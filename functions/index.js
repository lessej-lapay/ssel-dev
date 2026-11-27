const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

const {
  WorkflowError,
  handleAccountStatusUpdate,
  handleFarmerProfileCreated,
} = require("./account_workflow");

admin.initializeApp();
setGlobalOptions({ region: "asia-southeast1" });

async function assertCallerIsAdmin(auth) {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const user = await admin.auth().getUser(auth.uid);
  const profile = await admin.firestore().collection("users").doc(auth.uid).get();
  const data = profile.data();
  const hasFirestoreAdmin =
    profile.exists && data?.role === "admin" && data?.status === "active";

  if (user.customClaims?.admin === true || hasFirestoreAdmin) {
    return {
      uid: auth.uid,
      fullName:
        (typeof data?.fullName === "string" && data.fullName.trim()) ||
        user.displayName ||
        user.email ||
        "Administrator",
    };
  }

  throw new HttpsError(
    "permission-denied",
    "Only an authorized administrator can perform this action.",
  );
}

/**
 * Creates an Admin account from a trusted backend.
 * Do not expose this as a public registration form.
 */
exports.provisionAdmin = onCall(async (request) => {
  await assertCallerIsAdmin(request.auth);

  const email = String(request.data?.email || "").trim();
  const password = String(request.data?.password || "");
  const fullName = String(request.data?.fullName || "").trim();
  const contactNumber = String(request.data?.contactNumber || "").trim();

  if (!email || !password || !fullName) {
    throw new HttpsError(
      "invalid-argument",
      "fullName, email, and password are required.",
    );
  }

  const user = await admin.auth().createUser({
    email,
    password,
    displayName: fullName,
  });

  await admin.auth().setCustomUserClaims(user.uid, { admin: true, role: "admin" });

  await admin.firestore().collection("users").doc(user.uid).set({
    uid: user.uid,
    fullName,
    email,
    contactNumber,
    farmName: "",
    farmLocation: "",
    municipality: "",
    province: "",
    role: "admin",
    status: "active",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { uid: user.uid };
});

/**
 * Triggered when a new user profile is created in Firestore.
 * Automatically creates a deduplicated admin notification, writes an audit
 * log entry, and dispatches FCM notifications to active administrators.
 */
exports.onFarmerProfileCreated = onDocumentCreated(
  "users/{uid}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    return handleFarmerProfileCreated({
      db: admin.firestore(),
      messaging: admin.messaging(),
      farmerUid: event.params.uid,
      farmerData: snapshot.data(),
      serverTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      logger,
    });
  },
);

/**
 * Trusted callable for administrators to approve, reject, block, or unblock
 * a farmer account atomically with notifications and audit logs.
 */
exports.updateFarmerAccountStatus = onCall(async (request) => {
  const adminUser = await assertCallerIsAdmin(request.auth);

  try {
    return await handleAccountStatusUpdate({
      db: admin.firestore(),
      messaging: admin.messaging(),
      adminUser,
      farmerUid: request.data?.farmerUid,
      action: request.data?.action,
      reason: request.data?.reason,
      serverTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      logger,
    });
  } catch (err) {
    if (err instanceof WorkflowError) {
      throw new HttpsError(err.code, err.message);
    }
    throw err;
  }
});
