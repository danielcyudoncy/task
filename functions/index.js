/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const {onDocumentWritten} = require("firebase-functions/v2/firestore");
// const logger = require("firebase-functions/logger");

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.adminDeleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can delete users.",
    );
  }

  const uid = data.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "User ID is required.",
    );
  }

  await admin.auth().deleteUser(uid);
  await admin.firestore().collection("users").doc(uid).delete();

  return {success: true};
});

// TODO: Add audit logging function once Firestore trigger syntax is resolved
// For now, audit logging is handled by the Firestore rules and client-side logging

// Admin-only permanent delete function with audit logging
exports.adminPermanentlyDeleteTask = functions.https.onCall(async (data, context) => {
  // Check admin permissions
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can permanently delete tasks.",
    );
  }

  const taskId = data.taskId;
  if (!taskId) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Task ID is required.",
    );
  }

  try {
    // Get task data before deletion for audit
    const taskDoc = await admin.firestore().collection("tasks").doc(taskId).get();
    if (!taskDoc.exists) {
      throw new functions.https.HttpsError(
          "not-found",
          "Task not found.",
      );
    }

    const taskData = taskDoc.data();

    // Create comprehensive audit record for permanent deletion
    const auditRecord = {
      taskId: taskId,
      operation: "permanent_delete",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      performedBy: context.auth.uid,
      adminId: context.auth.uid,
      reason: data.reason || "Administrative deletion",
      taskSnapshot: sanitizeData(taskData),
      deletedBy: context.auth.uid,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Write audit record first
    await admin.firestore().collection("task_audits").add(auditRecord);

    // Delete the task
    await admin.firestore().collection("tasks").doc(taskId).delete();

    console.log(`Task ${taskId} permanently deleted by admin ${context.auth.uid}`);

    return {
      success: true,
      message: "Task permanently deleted",
      auditId: auditRecord.id,
    };
  } catch (error) {
    console.error("Error in adminPermanentlyDeleteTask:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to permanently delete task.",
    );
  }
});

// Helper function to sanitize sensitive data from audit logs
function sanitizeData(data) {
  if (!data) return null;

  const sanitized = {...data};

  // Remove or mask sensitive fields if any
  // Add any sensitive fields that shouldn't be logged here

  return sanitized;
}

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
