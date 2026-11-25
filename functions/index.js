const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "asia-southeast1" });

async function assertCallerIsAdmin(auth) {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const user = await admin.auth().getUser(auth.uid);
  if (user.customClaims?.admin === true) {
    return;
  }

  const profile = await admin.firestore().collection("users").doc(auth.uid).get();
  const data = profile.data();
  if (profile.exists && data?.role === "admin" && data?.status === "active") {
    return;
  }

  throw new HttpsError(
    "permission-denied",
    "Only an existing administrator can provision admin accounts.",
  );
}

/**
 * Creates an Admin account from a trusted backend.
 * Do not expose this as a public registration form.
 *
 * First admin: create Auth user + users/{uid} in Firebase Console, or
 * run a one-time Admin SDK script. After that, signed-in admins can call this.
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
