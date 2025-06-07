const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function updateTaskMetrics() {
  const tasksSnapshot = await db.collection('tasks').get();

  let total = 0;
  let completed = 0;
  let pending = 0;
  let overdue = 0;

  const now = new Date();

  tasksSnapshot.forEach(doc => {
    const task = doc.data();
    total++;

    if (task.status?.toLowerCase() === 'completed') {
      completed++;
    } else {
      const dueDate = task.dueDate?.toDate?.();
      if (dueDate && dueDate < now) {
        overdue++;
      } else {
        pending++;
      }
    }
  });

  await db.collection('dashboard_metrics').doc('summary').set({
    tasks: {
      total,
      completed,
      pending,
      overdue,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  }, { merge: true });
}

exports.onTaskChange = functions.firestore
  .document('tasks/{taskId}')
  .onWrite(async (change, context) => {
    await updateTaskMetrics();
  });

exports.deleteUserFromAuth = functions.firestore
  .document('users/{userId}')
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;

    try {
      await admin.auth().deleteUser(userId);
      console.log(`✅ Successfully deleted user ${userId} from Firebase Auth`);
    } catch (error) {
      console.error(`❌ Error deleting user ${userId}:`, error.message);
    }

    return null;
  });
