const INVALID_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

class WorkflowError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "WorkflowError";
    this.code = code;
  }
}

function normalizeString(value, maxLength = 500) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function normalizeRole(role) {
  const value = normalizeString(role, 40).toLowerCase();
  if (value === "regular") return "farmer";
  return value;
}

function isFarmerCreationEligible(farmerData) {
  if (!farmerData || typeof farmerData !== "object") return false;
  const role = normalizeRole(farmerData.role);
  const status = normalizeString(farmerData.status, 40).toLowerCase();
  return role === "farmer" && status === "pending";
}

function registrationNotificationId(farmerUid) {
  return `new_registration_${farmerUid}`;
}

function registrationAuditLogId(farmerUid) {
  return `registration_${farmerUid}`;
}

function buildAdminRegistrationNotification({
  farmerUid,
  farmerData,
  serverTimestamp,
}) {
  const fullName =
    normalizeString(farmerData?.fullName, 120) ||
    normalizeString(farmerData?.email, 120) ||
    "New Farmer";
  const email = normalizeString(farmerData?.email, 160);
  const id = registrationNotificationId(farmerUid);

  return {
    id,
    targetRole: "admin",
    recipientUid: null,
    farmerUid,
    farmerName: fullName,
    farmerEmail: email,
    title: "New Farmer Registration",
    message: `${fullName} has submitted a registration request and is waiting for account approval.`,
    type: "new_registration",
    isRead: false,
    readAt: null,
    readBy: null,
    handled: false,
    handledStatus: null,
    handledAction: null,
    handledBy: null,
    handledAt: null,
    registrationDate: farmerData?.createdAt ?? serverTimestamp,
    createdAt: serverTimestamp,
  };
}

function buildRegistrationAuditLog({
  farmerUid,
  farmerData,
  serverTimestamp,
}) {
  return {
    targetUid: farmerUid,
    targetName: normalizeString(farmerData?.fullName, 120),
    targetEmail: normalizeString(farmerData?.email, 160),
    adminUid: null,
    actorUid: farmerUid,
    action: "farmer_registration",
    previousStatus: null,
    newStatus: "pending",
    reason: null,
    createdAt: serverTimestamp,
  };
}

function resolveAccountTransition({ currentRole, currentStatus, action, reason }) {
  const normalizedRole = normalizeRole(currentRole);
  if (normalizedRole === "admin") {
    throw new WorkflowError(
      "failed-precondition",
      "Administrator accounts cannot be modified through farmer approval.",
    );
  }
  if (normalizedRole !== "farmer") {
    throw new WorkflowError(
      "failed-precondition",
      "Target account is not a farmer account.",
    );
  }

  const normalizedStatus = normalizeString(currentStatus, 40).toLowerCase();
  const normalizedAction = normalizeString(action, 40).toLowerCase();
  const cleanReason = normalizeString(reason, 500);

  switch (normalizedAction) {
    case "approve":
      if (normalizedStatus === "active") {
        throw new WorkflowError(
          "failed-precondition",
          "This farmer account is already approved.",
        );
      }
      if (normalizedStatus !== "pending") {
        throw new WorkflowError(
          "failed-precondition",
          "Only pending farmer accounts can be approved.",
        );
      }
      return {
        nextStatus: "active",
        auditAction: "account_approved",
        notificationType: "account_approved",
        title: "SoilSAFE Account Approved",
        message:
          "Your account has been approved. You can now access your SoilSAFE dashboard.",
        rejectionReason: null,
      };

    case "reject":
      if (normalizedStatus === "rejected") {
        throw new WorkflowError(
          "failed-precondition",
          "This farmer account is already rejected.",
        );
      }
      if (normalizedStatus !== "pending") {
        throw new WorkflowError(
          "failed-precondition",
          "Only pending farmer accounts can be rejected.",
        );
      }
      return {
        nextStatus: "rejected",
        auditAction: "account_rejected",
        notificationType: "account_rejected",
        title: "SoilSAFE Account Not Approved",
        message: cleanReason
          ? `Your registration was not approved. Reason: ${cleanReason}`
          : "Your registration was not approved. Please contact a SoilSAFE administrator for assistance.",
        rejectionReason: cleanReason || null,
      };

    case "block":
      if (normalizedStatus === "blocked") {
        throw new WorkflowError(
          "failed-precondition",
          "This farmer account is already blocked.",
        );
      }
      if (normalizedStatus !== "active") {
        throw new WorkflowError(
          "failed-precondition",
          "Only active farmer accounts can be blocked.",
        );
      }
      return {
        nextStatus: "blocked",
        auditAction: "account_blocked",
        notificationType: "account_blocked",
        title: "SoilSAFE Account Blocked",
        message:
          "Your account has been blocked by an administrator. Please contact support for assistance.",
        rejectionReason: null,
      };

    case "unblock":
      if (normalizedStatus === "active") {
        throw new WorkflowError(
          "failed-precondition",
          "This farmer account is already active.",
        );
      }
      if (normalizedStatus !== "blocked") {
        throw new WorkflowError(
          "failed-precondition",
          "Only blocked farmer accounts can be unblocked.",
        );
      }
      return {
        nextStatus: "active",
        auditAction: "account_unblocked",
        notificationType: "account_unblocked",
        title: "SoilSAFE Account Restored",
        message:
          "Your account access has been restored. You can now use your SoilSAFE dashboard.",
        rejectionReason: null,
      };

    default:
      throw new WorkflowError(
        "invalid-argument",
        "Action must be approve, reject, block, or unblock.",
      );
  }
}

async function dispatchPushToUsers({
  db,
  messaging,
  userIds,
  title,
  body,
  data,
  logger = console,
}) {
  if (!messaging || !Array.isArray(userIds) || userIds.length === 0) {
    return { sent: 0, removedTokens: 0 };
  }

  const tokenEntries = [];
  const seenTokens = new Set();

  for (const uid of userIds) {
    const snap = await db
      .collection("users")
      .doc(uid)
      .collection("fcmTokens")
      .get();
    for (const doc of snap.docs) {
      const token = normalizeString(doc.data()?.token, 4096);
      if (token && !seenTokens.has(token)) {
        seenTokens.add(token);
        tokenEntries.push({ token, ref: doc.ref });
      }
    }
  }

  if (tokenEntries.length === 0) {
    return { sent: 0, removedTokens: 0 };
  }

  let sent = 0;
  let removedTokens = 0;
  const tokens = tokenEntries.map((entry) => entry.token);

  try {
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [k, String(v ?? "")]),
      ),
    });

    const cleanupPromises = [];
    response.responses.forEach((res, idx) => {
      if (res.success) {
        sent += 1;
      } else {
        const code = res.error?.code;
        if (code && INVALID_TOKEN_CODES.has(code)) {
          removedTokens += 1;
          cleanupPromises.push(
            tokenEntries[idx].ref.delete().catch((err) => {
              logger.warn?.("Failed deleting stale FCM token:", err);
            }),
          );
        } else {
          logger.warn?.("FCM delivery failed for token:", code || res.error);
        }
      }
    });

    if (cleanupPromises.length > 0) {
      await Promise.all(cleanupPromises);
    }
  } catch (err) {
    logger.warn?.("FCM sendEachForMulticast failed:", err);
  }

  return { sent, removedTokens };
}

async function handleFarmerProfileCreated({
  db,
  messaging,
  farmerUid,
  farmerData,
  serverTimestamp,
  logger = console,
}) {
  if (!isFarmerCreationEligible(farmerData)) {
    return { created: false, skipped: true };
  }

  const notifId = registrationNotificationId(farmerUid);
  const auditId = registrationAuditLogId(farmerUid);
  const notifRef = db.collection("notifications").doc(notifId);
  const auditRef = db.collection("audit_logs").doc(auditId);

  const notificationPayload = buildAdminRegistrationNotification({
    farmerUid,
    farmerData,
    serverTimestamp,
  });
  const auditPayload = buildRegistrationAuditLog({
    farmerUid,
    farmerData,
    serverTimestamp,
  });

  const created = await db.runTransaction(async (tx) => {
    const existingNotif = await tx.get(notifRef);
    if (existingNotif.exists) {
      return false;
    }

    const existingAudit = await tx.get(auditRef);
    tx.set(notifRef, notificationPayload);
    if (!existingAudit.exists) {
      tx.set(auditRef, auditPayload);
    }
    return true;
  });

  if (!created) {
    return { created: false, duplicate: true };
  }

  // Fan out FCM push to active admins when configured.
  try {
    const adminsSnap = await db
      .collection("users")
      .where("role", "==", "admin")
      .where("status", "==", "active")
      .get();
    const adminUids = adminsSnap.docs.map((d) => d.id);
    await dispatchPushToUsers({
      db,
      messaging,
      userIds: adminUids,
      title: notificationPayload.title,
      body: notificationPayload.message,
      data: {
        notificationId: notifId,
        type: "new_registration",
        farmerUid,
      },
      logger,
    });
  } catch (err) {
    logger.warn?.("Admin FCM lookup/dispatch failed:", err);
  }

  return { created: true, notificationId: notifId, auditId };
}

async function handleAccountStatusUpdate({
  db,
  messaging,
  adminUser,
  farmerUid,
  action,
  reason,
  serverTimestamp,
  logger = console,
}) {
  const cleanFarmerUid = normalizeString(farmerUid, 128);
  if (!cleanFarmerUid) {
    throw new WorkflowError("invalid-argument", "farmerUid is required.");
  }
  if (cleanFarmerUid === adminUser.uid) {
    throw new WorkflowError(
      "failed-precondition",
      "Administrators cannot modify their own approval status.",
    );
  }

  const userRef = db.collection("users").doc(cleanFarmerUid);
  const adminRegNotifRef = db
    .collection("notifications")
    .doc(registrationNotificationId(cleanFarmerUid));
  const notifRef = db.collection("notifications").doc();
  const auditRef = db.collection("audit_logs").doc();

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const adminRegNotifSnap = await tx.get(adminRegNotifRef);
    if (!snap.exists) {
      throw new WorkflowError("not-found", "Farmer account not found.");
    }

    const userData = snap.data() || {};
    const currentStatus = normalizeString(userData.status, 40) || "pending";
    const transition = resolveAccountTransition({
      currentRole: userData.role,
      currentStatus,
      action,
      reason,
    });

    const farmerName =
      normalizeString(userData.fullName, 120) ||
      normalizeString(userData.email, 120) ||
      "Farmer";
    const farmerEmail = normalizeString(userData.email, 160);

    const userUpdates = {
      status: transition.nextStatus,
      updatedAt: serverTimestamp,
    };

    if (transition.nextStatus === "active" && action === "approve") {
      userUpdates.approvedBy = adminUser.uid;
      userUpdates.approvedByName = adminUser.fullName;
      userUpdates.approvedAt = serverTimestamp;
      userUpdates.rejectionReason = null;
    } else if (transition.nextStatus === "rejected") {
      userUpdates.rejectedBy = adminUser.uid;
      userUpdates.rejectedByName = adminUser.fullName;
      userUpdates.rejectedAt = serverTimestamp;
      userUpdates.rejectionReason = transition.rejectionReason;
    } else if (transition.nextStatus === "blocked") {
      userUpdates.blockedBy = adminUser.uid;
      userUpdates.blockedByName = adminUser.fullName;
      userUpdates.blockedAt = serverTimestamp;
    } else if (transition.nextStatus === "active" && action === "unblock") {
      userUpdates.unblockedBy = adminUser.uid;
      userUpdates.unblockedByName = adminUser.fullName;
      userUpdates.unblockedAt = serverTimestamp;
    }

    const notificationDoc = {
      id: notifRef.id,
      targetRole: "farmer",
      recipientUid: cleanFarmerUid,
      farmerUid: cleanFarmerUid,
      farmerName,
      title: transition.title,
      message: transition.message,
      type: transition.notificationType,
      rejectionReason: transition.rejectionReason,
      isRead: false,
      readAt: null,
      readBy: null,
      actorUid: adminUser.uid,
      createdAt: serverTimestamp,
    };

    const auditDoc = {
      targetUid: cleanFarmerUid,
      targetName: farmerName,
      targetEmail: farmerEmail,
      adminUid: adminUser.uid,
      actorUid: adminUser.uid,
      action: transition.auditAction,
      previousStatus: currentStatus,
      newStatus: transition.nextStatus,
      reason: transition.rejectionReason,
      createdAt: serverTimestamp,
    };

    tx.update(userRef, userUpdates);
    if (
      adminRegNotifSnap.exists &&
      (action === "approve" || action === "reject")
    ) {
      const existingAdminNotif = adminRegNotifSnap.data() || {};
      tx.update(adminRegNotifRef, {
        isRead: true,
        readAt: existingAdminNotif.readAt ?? serverTimestamp,
        readBy: existingAdminNotif.readBy ?? adminUser.uid,
        handled: true,
        handledStatus: transition.nextStatus,
        handledAction: action,
        handledBy: adminUser.uid,
        handledAt: serverTimestamp,
      });
    }
    tx.set(notifRef, notificationDoc);
    tx.set(auditRef, auditDoc);

    return {
      farmerUid: cleanFarmerUid,
      status: transition.nextStatus,
      notificationId: notifRef.id,
      auditId: auditRef.id,
      title: transition.title,
      message: transition.message,
      type: transition.notificationType,
      rejectionReason: transition.rejectionReason,
    };
  });

  await dispatchPushToUsers({
    db,
    messaging,
    userIds: [cleanFarmerUid],
    title: result.title,
    body: result.message,
    data: {
      notificationId: result.notificationId,
      type: result.type,
      farmerUid: cleanFarmerUid,
      status: result.status,
    },
    logger,
  });

  return {
    farmerUid: result.farmerUid,
    status: result.status,
    notificationId: result.notificationId,
    auditId: result.auditId,
  };
}

module.exports = {
  INVALID_TOKEN_CODES,
  WorkflowError,
  buildAdminRegistrationNotification,
  buildRegistrationAuditLog,
  dispatchPushToUsers,
  handleAccountStatusUpdate,
  handleFarmerProfileCreated,
  isFarmerCreationEligible,
  normalizeRole,
  registrationAuditLogId,
  registrationNotificationId,
  resolveAccountTransition,
};
