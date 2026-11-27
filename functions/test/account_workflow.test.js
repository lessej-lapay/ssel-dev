const test = require("node:test");
const assert = require("node:assert/strict");

const {
  WorkflowError,
  handleAccountStatusUpdate,
  handleFarmerProfileCreated,
  resolveAccountTransition,
} = require("../account_workflow");

function createFakeFirestore(initialDocs = {}) {
  const store = new Map();
  let autoCounter = 1;

  for (const [path, data] of Object.entries(initialDocs)) {
    store.set(path, structuredClone(data));
  }

  function makeDocRef(path) {
    return {
      id: path.split("/").pop(),
      path,
      collection(sub) {
        return makeCollectionRef(`${path}/${sub}`);
      },
      async get() {
        const exists = store.has(path);
        return {
          id: this.id,
          exists,
          data: () => (exists ? structuredClone(store.get(path)) : undefined),
        };
      },
      async delete() {
        store.delete(path);
      },
    };
  }

  function makeCollectionRef(colPath) {
    const filters = [];

    const queryObj = {
      doc(id) {
        const docId = id || `auto_${autoCounter++}`;
        return makeDocRef(`${colPath}/${docId}`);
      },
      where(field, op, value) {
        filters.push({ field, op, value });
        return queryObj;
      },
      async get() {
        const prefix = `${colPath}/`;
        const docs = [];
        for (const [path, data] of store.entries()) {
          if (!path.startsWith(prefix)) continue;
          const rest = path.slice(prefix.length);
          if (rest.includes("/")) continue;

          const matches = filters.every(
            ({ field, op, value }) => op === "==" && data[field] === value,
          );
          if (matches) {
            docs.push({
              id: rest,
              ref: makeDocRef(path),
              data: () => structuredClone(data),
            });
          }
        }
        return { docs };
      },
    };

    return queryObj;
  }

  return {
    store,
    collection(name) {
      return makeCollectionRef(name);
    },
    async runTransaction(fn) {
      const tx = {
        async get(ref) {
          return ref.get();
        },
        set(ref, data) {
          store.set(ref.path, structuredClone(data));
        },
        update(ref, updates) {
          const current = store.get(ref.path);
          if (!current) throw new Error(`Missing doc ${ref.path}`);
          store.set(ref.path, { ...current, ...structuredClone(updates) });
        },
      };
      return fn(tx);
    },
  };
}

test("farmer registration creates deduplicated admin notification and audit log", async () => {
  const db = createFakeFirestore({
    "users/admin-1": {
      uid: "admin-1",
      role: "admin",
      status: "active",
      fullName: "Admin User",
    },
    "users/admin-1/fcmTokens/tok-valid": { token: "valid-admin-token" },
    "users/admin-1/fcmTokens/tok-stale": { token: "stale-admin-token" },
  });

  const sentPayloads = [];
  const messaging = {
    async sendEachForMulticast(payload) {
      sentPayloads.push(payload);
      return {
        responses: [
          { success: true },
          {
            success: false,
            error: { code: "messaging/registration-token-not-registered" },
          },
        ],
      };
    },
  };

  const farmerData = {
    uid: "farmer-1",
    fullName: "Juan Dela Cruz",
    email: "farmer@example.com",
    role: "farmer",
    status: "pending",
  };

  const first = await handleFarmerProfileCreated({
    db,
    messaging,
    farmerUid: "farmer-1",
    farmerData,
    serverTimestamp: "SERVER_TS",
  });
  assert.equal(first.created, true);
  assert.equal(first.notificationId, "new_registration_farmer-1");

  const notif = db.store.get("notifications/new_registration_farmer-1");
  assert.equal(notif.targetRole, "admin");
  assert.equal(notif.farmerUid, "farmer-1");
  assert.equal(notif.farmerName, "Juan Dela Cruz");
  assert.equal(notif.title, "New Farmer Registration");
  assert.equal(notif.type, "new_registration");
  assert.equal(notif.isRead, false);

  const audit = db.store.get("audit_logs/registration_farmer-1");
  assert.equal(audit.action, "farmer_registration");
  assert.equal(audit.targetUid, "farmer-1");
  assert.equal(audit.newStatus, "pending");

  // Stale FCM token was automatically cleaned up.
  assert.equal(db.store.has("users/admin-1/fcmTokens/tok-stale"), false);
  assert.equal(db.store.has("users/admin-1/fcmTokens/tok-valid"), true);
  assert.equal(sentPayloads.length, 1);

  // Retry / duplicate invocation must not duplicate notification or push.
  const second = await handleFarmerProfileCreated({
    db,
    messaging,
    farmerUid: "farmer-1",
    farmerData,
    serverTimestamp: "SERVER_TS",
  });
  assert.equal(second.created, false);
  assert.equal(second.duplicate, true);
  assert.equal(sentPayloads.length, 1);
});

test("non-farmer or non-pending profiles do not trigger registration notification", async () => {
  const db = createFakeFirestore();
  const result = await handleFarmerProfileCreated({
    db,
    messaging: null,
    farmerUid: "admin-2",
    farmerData: { role: "admin", status: "active", fullName: "Root Admin" },
    serverTimestamp: "SERVER_TS",
  });
  assert.equal(result.created, false);
  assert.equal(result.skipped, true);
  assert.equal(db.store.size, 0);
});

test("approve workflow updates user, marks registration notification handled, creates farmer notification, and writes audit log", async () => {
  const db = createFakeFirestore({
    "users/farmer-1": {
      uid: "farmer-1",
      fullName: "Juan Dela Cruz",
      email: "farmer@example.com",
      role: "farmer",
      status: "pending",
    },
    "notifications/new_registration_farmer-1": {
      id: "new_registration_farmer-1",
      targetRole: "admin",
      farmerUid: "farmer-1",
      farmerName: "Juan Dela Cruz",
      type: "new_registration",
      isRead: false,
      handled: false,
    },
  });

  const res = await handleAccountStatusUpdate({
    db,
    messaging: null,
    adminUser: { uid: "admin-1", fullName: "Admin One" },
    farmerUid: "farmer-1",
    action: "approve",
    serverTimestamp: "SERVER_TS",
  });

  assert.equal(res.status, "active");
  const updated = db.store.get("users/farmer-1");
  assert.equal(updated.status, "active");
  assert.equal(updated.approvedBy, "admin-1");
  assert.equal(updated.approvedAt, "SERVER_TS");

  const adminRegNotif = db.store.get("notifications/new_registration_farmer-1");
  assert.ok(adminRegNotif);
  assert.equal(adminRegNotif.handled, true);
  assert.equal(adminRegNotif.handledStatus, "active");
  assert.equal(adminRegNotif.handledAction, "approve");
  assert.equal(adminRegNotif.handledBy, "admin-1");
  assert.equal(adminRegNotif.isRead, true);

  const notif = db.store.get(`notifications/${res.notificationId}`);
  assert.equal(notif.targetRole, "farmer");
  assert.equal(notif.recipientUid, "farmer-1");
  assert.equal(notif.type, "account_approved");
  assert.equal(notif.title, "SoilSAFE Account Approved");
  assert.equal(notif.isRead, false);

  const audit = db.store.get(`audit_logs/${res.auditId}`);
  assert.equal(audit.action, "account_approved");
  assert.equal(audit.adminUid, "admin-1");
  assert.equal(audit.targetUid, "farmer-1");
  assert.equal(audit.previousStatus, "pending");
  assert.equal(audit.newStatus, "active");

  // Re-approving an already approved account is rejected (prevents duplicates).
  await assert.rejects(
    () =>
      handleAccountStatusUpdate({
        db,
        messaging: null,
        adminUser: { uid: "admin-1", fullName: "Admin One" },
        farmerUid: "farmer-1",
        action: "approve",
        serverTimestamp: "SERVER_TS",
      }),
    (err) => err instanceof WorkflowError && err.code === "failed-precondition",
  );
});

test("reject workflow stores rejection reason, preserves account, marks registration notification handled, notifies farmer, and audits", async () => {
  const db = createFakeFirestore({
    "users/farmer-2": {
      uid: "farmer-2",
      fullName: "Maria Clara",
      email: "maria@example.com",
      role: "farmer",
      status: "pending",
    },
    "notifications/new_registration_farmer-2": {
      id: "new_registration_farmer-2",
      targetRole: "admin",
      farmerUid: "farmer-2",
      farmerName: "Maria Clara",
      type: "new_registration",
      isRead: true,
      handled: false,
    },
  });

  const res = await handleAccountStatusUpdate({
    db,
    messaging: null,
    adminUser: { uid: "admin-1", fullName: "Admin One" },
    farmerUid: "farmer-2",
    action: "reject",
    reason: "Incomplete farm location details",
    serverTimestamp: "SERVER_TS",
  });

  assert.equal(res.status, "rejected");
  const updated = db.store.get("users/farmer-2");
  assert.ok(updated);
  assert.equal(updated.status, "rejected");
  assert.equal(updated.rejectedBy, "admin-1");
  assert.equal(updated.rejectionReason, "Incomplete farm location details");

  const adminRegNotif = db.store.get("notifications/new_registration_farmer-2");
  assert.ok(adminRegNotif);
  assert.equal(adminRegNotif.handled, true);
  assert.equal(adminRegNotif.handledStatus, "rejected");
  assert.equal(adminRegNotif.handledAction, "reject");

  const notif = db.store.get(`notifications/${res.notificationId}`);
  assert.equal(notif.recipientUid, "farmer-2");
  assert.equal(notif.type, "account_rejected");
  assert.equal(notif.rejectionReason, "Incomplete farm location details");
  assert.match(notif.message, /Incomplete farm location details/);

  const audit = db.store.get(`audit_logs/${res.auditId}`);
  assert.equal(audit.action, "account_rejected");
  assert.equal(audit.reason, "Incomplete farm location details");
});

test("block and unblock transitions validate state and prevent invalid transitions", async () => {
  assert.throws(
    () =>
      resolveAccountTransition({
        currentRole: "admin",
        currentStatus: "active",
        action: "block",
      }),
    (err) => err instanceof WorkflowError && err.code === "failed-precondition",
  );

  assert.throws(
    () =>
      resolveAccountTransition({
        currentRole: "farmer",
        currentStatus: "pending",
        action: "block",
      }),
    (err) => err instanceof WorkflowError && err.code === "failed-precondition",
  );

  const blockRes = resolveAccountTransition({
    currentRole: "farmer",
    currentStatus: "active",
    action: "block",
  });
  assert.equal(blockRes.nextStatus, "blocked");
  assert.equal(blockRes.auditAction, "account_blocked");

  const unblockRes = resolveAccountTransition({
    currentRole: "farmer",
    currentStatus: "blocked",
    action: "unblock",
  });
  assert.equal(unblockRes.nextStatus, "active");
  assert.equal(unblockRes.auditAction, "account_unblocked");
});
