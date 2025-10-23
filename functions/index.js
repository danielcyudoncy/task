const {onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

exports.adminDeleteUser = onCall({maxInstances: 1}, async (request) => {
  const {auth} = request;

  if (!auth || !auth.token.admin) {
    throw new Error(
        "permission-denied/only-admins-can-delete-users",
    );
  }

  const uid = request.data.uid;
  if (!uid) {
    throw new Error(
        "invalid-argument/user-id-required",
    );
  }

  await admin.auth().deleteUser(uid);
  await admin.firestore().collection("users").doc(uid).delete();

  return {success: true};
});

// TODO: Add audit logging function once Firestore trigger syntax is resolved
// For now, audit logging is handled by the Firestore rules and client-side
// logging

// Admin-only permanent delete function with audit logging
exports.adminPermanentlyDeleteTask = onCall(
    {maxInstances: 1},
    async (request) => {
      const {auth, data} = request;

      // Check admin permissions
      if (!auth || !auth.token.admin) {
        throw new Error(
            "permission-denied/only-admins-can-permanently-delete-tasks",
        );
      }

      const taskId = data.taskId;
      if (!taskId) {
        throw new Error(
            "invalid-argument/task-id-required",
        );
      }

      try {
        // Get task data before deletion for audit
        const taskDoc = await admin.firestore()
            .collection("tasks")
            .doc(taskId)
            .get();
        if (!taskDoc.exists) {
          throw new Error(
              "not-found/task-not-found",
          );
        }

        const taskData = taskDoc.data();

        // Create comprehensive audit record for permanent deletion
        const auditRecord = {
          taskId: taskId,
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
        const auditRef = await admin.firestore()
            .collection("task_audits")
            .add(auditRecord);

        // Delete the task
        await admin.firestore().collection("tasks").doc(taskId).delete();

        logger.info(
            `Task ${taskId} permanently deleted by admin ${auth.uid}`,
        );

        return {
          success: true,
          message: "Task permanently deleted",
          auditId: auditRef.id,
        };
      } catch (error) {
        logger.error("Error in adminPermanentlyDeleteTask:", error);
        throw new Error(
            "internal/failed-to-permanently-delete-task",
        );
      }
    },
);

// Helper function to sanitize sensitive data from audit logs
/**
 * Sanitizes sensitive data from audit logs.
 * @param {Object} data The data to sanitize.
 * @return {Object} The sanitized data.
 */
function sanitizeData(data) {
  if (!data) return null;

  const sanitized = {...data};

  // Remove or mask sensitive fields if any
  // Add any sensitive fields that shouldn't be logged here

  return sanitized;
}

// Set admin custom claim
exports.setAdminClaim = onCall({maxInstances: 1}, async (request) => {
  const {auth, data} = request;
  // Check if the caller is already an admin
  if (!auth || !auth.token.admin) {
    throw new Error(
        "permission-denied/only-admins-can-set-admin-claims",
    );
  }

  const uid = data.uid;
  if (!uid) {
    throw new Error(
        "invalid-argument/user-id-required",
    );
  }

  try {
    await admin.auth().setCustomUserClaims(uid, {admin: true});
    logger.info(`Admin claim set for user ${uid}`);
    return {success: true};
  } catch (error) {
    logger.error("Error setting admin claim:", error);
    throw new Error(
        "internal/failed-to-set-admin-claim",
    );
  }
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
