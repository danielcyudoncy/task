const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteUserFromAuth = functions.firestore
  .document('users/{userId}')
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    try {
      await admin.auth().deleteUser(userId);
      console.log(`Successfully deleted user ${userId} from Auth`);
      return null;
    } catch (error) {
      console.error(`Error deleting user ${userId} from Auth:`, error);
      return null;
    }
  });