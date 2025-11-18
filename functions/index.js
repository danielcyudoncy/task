const {onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

// List of roles authorized to perform sensitive operations
const AUTHORIZED_ADMIN_ROLES = [
  "admin",
  "Admin",
  "News Director",
  "Head of Department",
  "Head of Unit",
];

/**
 * Check if user is authorized to perform admin operations
 * @param {Object} auth - Firebase auth context
 * @return {Promise<boolean>}
 */
async function isAdminAuthorized(auth) {
  if (!auth || !auth.token) return false;
  if (auth.token.admin === true) return true;

  const userRole = auth.token.role;
  if (AUTHORIZED_ADMIN_ROLES.includes(userRole)) return true;

  try {
    if (auth.uid) {
      const usersRef = admin.firestore().collection("users");
      const userDoc = await usersRef.doc(auth.uid).get();
      const role = userDoc.exists ? userDoc.data()?.role : null;
      if (role && AUTHORIZED_ADMIN_ROLES.includes(role)) return true;
    }
  } catch (e) {
    logger.warn("isAdminAuthorized: error checking users doc", e);
  }
  return false;
}

/**
 * Log privileged operations for audit trail
 * @param {string} operation - Operation name
 * @param {string} uid - User performing operation
 * @param {string} targetUid - Target user (if applicable)
 * @param {string} resourceId - Resource ID (if applicable)
 * @param {Object} details - Additional details
 */
async function logPrivilegedOperation(
    operation,
    uid,
    targetUid,
    resourceId,
    details,
) {
  try {
    const auditRecord = {
      operation,
      performedBy: uid,
      targetUid: targetUid || null,
      resourceId: resourceId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: details || {},
      status: "success",
    };

    const auditRef = admin.firestore().collection("audit_logs");
    await auditRef.add(auditRecord);
    logger.info(`Audit log: ${operation} by ${uid}`, {targetUid, resourceId});
  } catch (error) {
    logger.error("Failed to log privileged operation:", error);
  }
}

/**
 * Sanitize sensitive data from audit logs
 * @param {Object} data - Data to sanitize
 * @return {Object} Sanitized data
 */
function sanitizeData(data) {
  if (!data) return null;
  const sanitized = {...data};
  return sanitized;
}

/**
 * Hash invite token using SHA-256 for secure storage
 * @param {string} rawToken - Raw invite token
 * @return {string} Hex digest
 */
function hashInviteToken(rawToken) {
  return crypto.createHash("sha256").update(rawToken).digest("hex");
}

/**
 * Create admin invite (admin-only)
 * Returns raw token to caller (shown only once)
 */
exports.createAdminInvite = onCall({maxInstances: 1}, async (request) => {
  const {auth, data} = request;

  if (!(await isAdminAuthorized(auth))) {
    const callerUid = auth?.uid || "unknown";
    logger.warn(`Unauthorized createAdminInvite attempt by ${callerUid}`);
    throw new Error("permission-denied/only-admins-can-create-invites");
  }

  const expiresInDays = (data && data.expiresInDays) || 7;
  // Generate cryptographically secure random token
  const rawToken = crypto.randomBytes(32).toString("hex");
  const tokenHash = hashInviteToken(rawToken);

  const expiresMs = Date.now() + expiresInDays * 24 * 60 * 60 * 1000;
  const expiresDate = new Date(expiresMs);

  const inviteDoc = {
    tokenHash,
    createdBy: auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(expiresDate),
    usedBy: null,
    usedAt: null,
  };

  try {
    const invitesRef = admin.firestore().collection("adminInvites");
    const ref = await invitesRef.add(inviteDoc);

    await logPrivilegedOperation(
        "admin_invite_created",
        auth.uid,
        null,
        ref.id,
        {expiresInDays},
    );

    return {
      success: true,
      inviteId: ref.id,
      token: rawToken,
      expiresInDays,
    };
  } catch (error) {
    logger.error("Error creating admin invite:", error);
    throw new Error("internal/failed-to-create-invite");
  }
});

/**
 * Redeem admin invite:
 * - Validates the invite
 * - Sets custom admin claim for caller UID
 * - Marks invite used and creates admins/{uid} doc
 * data: {token: string}
 */
exports.redeemAdminInvite = onCall({maxInstances: 1}, async (request) => {
  const {auth, data} = request;

  if (!auth || !auth.uid) {
    throw new Error("unauthenticated");
  }

  const rawToken = data && data.token;
  if (!rawToken || typeof rawToken !== "string") {
    throw new Error("invalid-argument/token-required");
  }

  const tokenHash = hashInviteToken(rawToken);

  try {
    // Find the invite by hash
    const invitesRef = admin.firestore().collection("adminInvites");
    const q = await invitesRef
        .where("tokenHash", "==", tokenHash)
        .limit(1)
        .get();

    if (q.empty) {
      throw new Error("not-found/invite-not-found");
    }

    const inviteDoc = q.docs[0];
    const inviteData = inviteDoc.data();

    // Check expiration
    if (inviteData.expiresAt && inviteData.expiresAt.toDate() < new Date()) {
      throw new Error("failed-precondition/invite-expired");
    }

    if (inviteData.usedBy) {
      throw new Error("failed-precondition/invite-already-used");
    }

    const uid = auth.uid;

    // 1) Set admin claim for the user
    await admin.auth().setCustomUserClaims(uid, {
      admin: true,
      role: "Admin",
      claimsSetAt: Math.floor(Date.now() / 1000),
      claimsSetBy: "invite_redeem",
    });

    // 2) Atomically mark invite used and create admins/{uid} document
    const inviteRef = invitesRef.doc(inviteDoc.id);
    const adminRef = admin.firestore().collection("admins").doc(uid);

    await admin.firestore().runTransaction(async (tx) => {
      const freshInvite = await tx.get(inviteRef);
      if (!freshInvite.exists) {
        throw new Error("not-found/invite-not-found");
      }
      const freshData = freshInvite.data();
      if (freshData.usedBy) {
        throw new Error("failed-precondition/invite-already-used");
      }

      tx.update(inviteRef, {
        usedBy: uid,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(adminRef, {
        createdBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        source: "invite",
      });
    });

    // Audit log
    await logPrivilegedOperation(
        "admin_invite_redeemed",
        uid,
        uid,
        inviteDoc.id,
        {},
    );

    return {
      success: true,
      message:
        "Invite redeemed; admin claim set. Please refresh your " +
        "authentication token.",
    };
  } catch (error) {
    logger.error("Error redeeming invite:", error);
    const msg = (error && error.message) || "internal/error";
    throw new Error(msg);
  }
});

/**
 * Admin-only user deletion with comprehensive audit logging
 */
exports.adminDeleteUser = onCall({maxInstances: 1}, async (request) => {
  const {auth, data} = request;

  if (!(await isAdminAuthorized(auth))) {
    const userId = (auth && auth.uid) || "unknown";
    const userRole =
        (auth && auth.token && auth.token.role) || "unknown";
    logger.warn(
        `Unauthorized adminDeleteUser attempt by ${userId} with role ` +
        `${userRole}`,
    );
    throw new Error("permission-denied/only-admins-can-delete-users");
  }

  const uid = data.uid;
  if (!uid) {
    throw new Error("invalid-argument/user-id-required");
  }

  // Prevent self-deletion
  if (uid === auth.uid) {
    logger.warn(`Attempt to self-delete by admin ${auth.uid}`);
    throw new Error("invalid-argument/cannot-delete-yourself");
  }

  try {
    // Get user details before deletion for audit
    const userDoc = await admin.firestore()
        .collection("users")
        .doc(uid)
        .get();
    const userName = userDoc.data()?.name || "Unknown";
    const userEmail = userDoc.data()?.email || "unknown@email.com";

    // Delete user and user document
    await admin.auth().deleteUser(uid);
    await admin.firestore().collection("users").doc(uid).delete();

    // Audit log
    await logPrivilegedOperation(
        "user_deleted",
        auth.uid,
        uid,
        null,
        {userName, userEmail},
    );

    logger.info(`User ${uid} deleted by admin ${auth.uid}`);
    return {success: true, message: "User deleted successfully"};
  } catch (error) {
    logger.error("Error in adminDeleteUser:", error);
    await logPrivilegedOperation(
        "user_deleted",
        auth.uid,
        uid,
        null,
        {error: error.message},
    ).catch(() => {});
    throw new Error("internal/failed-to-delete-user");
  }
});

/**
 * Admin-only permanent task deletion with comprehensive audit trail
 */
exports.adminPermanentlyDeleteTask = onCall(
    {maxInstances: 1},
    async (request) => {
      const {auth, data} = request;

      if (!(await isAdminAuthorized(auth))) {
        const userId = (auth && auth.uid) || "unknown";
        const userRole =
            (auth && auth.token && auth.token.role) || "unknown";
        logger.warn(
            `Unauthorized adminPermanentlyDeleteTask attempt by ${userId} ` +
            `with role ${userRole}`,
        );
        throw new Error(
            "permission-denied/only-admins-can-permanently-delete-tasks",
        );
      }

      const taskId = data.taskId;
      if (!taskId) {
        throw new Error("invalid-argument/task-id-required");
      }

      try {
        const taskDoc = await admin.firestore()
            .collection("tasks")
            .doc(taskId)
            .get();
        if (!taskDoc.exists) {
          throw new Error("not-found/task-not-found");
        }

        const taskData = taskDoc.data();

        // Create comprehensive audit record for permanent deletion
        const auditRecord = {
          taskId,
          operation: "permanent_delete",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          performedBy: auth.uid,
          adminId: auth.uid,
          reason: data.reason || "Administrative deletion",
          taskSnapshot: sanitizeData(taskData),
          deletedBy: auth.uid,
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Write audit record first
        const taskAuditsRef = admin.firestore().collection("task_audits");
        const auditRef = await taskAuditsRef.add(auditRecord);

        // Delete the task
        await admin.firestore().collection("tasks").doc(taskId).delete();

        // Audit log
        await logPrivilegedOperation(
            "task_permanently_deleted",
            auth.uid,
            null,
            taskId,
            {taskTitle: taskData.title, reason: data.reason},
        );

        logger.info(`Task ${taskId} permanently deleted by admin ${auth.uid}`);
        return {
          success: true,
          message: "Task permanently deleted",
          auditId: auditRef.id,
        };
      } catch (error) {
        logger.error("Error in adminPermanentlyDeleteTask:", error);
        throw new Error("internal/failed-to-permanently-delete-task");
      }
    },
);

/**
 * Set admin custom claim (admin-only)
 */
exports.setAdminClaim = onCall({maxInstances: 1}, async (request) => {
  const {auth, data} = request;

  if (!(await isAdminAuthorized(auth))) {
    const userId = (auth && auth.uid) || "unknown";
    const userRole =
        (auth && auth.token && auth.token.role) || "unknown";
    logger.warn(
        `Unauthorized setAdminClaim attempt by ${userId} with role ` +
        `${userRole}`,
    );
    throw new Error("permission-denied/only-admins-can-set-admin-claims");
  }

  const uid = data.uid;
  if (!uid) {
    throw new Error("invalid-argument/user-id-required");
  }

  // Verify user exists
  try {
    const user = await admin.auth().getUser(uid);
    if (!user) {
      throw new Error("User not found");
    }
  } catch (error) {
    throw new Error("invalid-argument/user-not-found");
  }

  try {
    // Set comprehensive admin claims
    await admin.auth().setCustomUserClaims(uid, {
      admin: true,
      role: "Admin",
      claimsSetAt: Math.floor(Date.now() / 1000),
      claimsSetBy: auth.uid,
    });

    const targetUser = await admin.auth().getUser(uid);

    // Audit log
    await logPrivilegedOperation(
        "admin_claim_set",
        auth.uid,
        uid,
        null,
        {userEmail: targetUser.email},
    );

    logger.info(`Admin claim set for user ${uid} by ${auth.uid}`);
    return {success: true, message: "Admin claim set successfully"};
  } catch (error) {
    logger.error("Error setting admin claim:", error);
    throw new Error("internal/failed-to-set-admin-claim");
  }
});

/**
 * Unset admin custom claim (admin-only)
 */
exports.unsetAdminClaim = onCall({maxInstances: 1}, async (request) => {
  const {auth, data} = request;

  if (!(await isAdminAuthorized(auth))) {
    const userId = (auth && auth.uid) || "unknown";
    const userRole = (auth && auth.token && auth.token.role) || "unknown";
    logger.warn(
        "Unauthorized unsetAdminClaim attempt by " + userId +
        " with role " + userRole,
    );
    throw new Error("permission-denied/only-admins-can-unset-admin-claims");
  }

  const uid = data.uid;
  if (!uid) {
    throw new Error("invalid-argument/user-id-required");
  }

  try {
    // Clear admin-related custom claims. We set role back to a default value
    // or remove claims entirely depending on app expectations.
    await admin.auth().setCustomUserClaims(uid, {
      admin: false,
      role: "Reporter",
      claimsSetAt: Math.floor(Date.now() / 1000),
      claimsRemovedBy: auth.uid,
    });

    // Remove admin doc if present
    const adminDocRef = admin.firestore()
        .collection("admins")
        .doc(uid);
    const adminDoc = await adminDocRef.get();
    if (adminDoc.exists) {
      await adminDocRef.delete();
    }

    // Update users collection role back to Reporter (best-effort)
    await admin.firestore()
        .collection("users")
        .doc(uid)
        .update({
          role: "Reporter",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    // Audit log
    await logPrivilegedOperation(
        "admin_claim_unset",
        auth.uid,
        uid,
        null,
        {message: "Admin claim removed"},
    );

    logger.info(`Admin claim unset for user ${uid} by ${auth.uid}`);
    return {success: true, message: "Admin claim unset successfully"};
  } catch (error) {
    logger.error("Error unsetting admin claim:", error);
    throw new Error("internal/failed-to-unset-admin-claim");
  }
});

