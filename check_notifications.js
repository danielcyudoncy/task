const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkNotifications() {
  try {
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    
    for (const userDoc of usersSnapshot.docs) {
      console.log(`\n=== User: ${userDoc.id} ===`);
      
      // Get notifications for this user
      const notificationsSnapshot = await db
        .collection('users')
        .doc(userDoc.id)
        .collection('notifications')
        .get();
      
      console.log(`Total notifications: ${notificationsSnapshot.docs.length}`);
      
      notificationsSnapshot.docs.forEach((notifDoc, index) => {
        const data = notifDoc.data();
        console.log(`\nNotification ${index + 1}:`);
        console.log(`  ID: ${notifDoc.id}`);
        console.log(`  Type: ${data.type}`);
        console.log(`  TaskId: ${data.taskId}`);
        console.log(`  Title: ${data.title}`);
        console.log(`  IsRead: ${data.isRead}`);
        console.log(`  Timestamp: ${data.timestamp?.toDate()}`);
      });
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

checkNotifications().then(() => {
  console.log('\nDone checking notifications');
  process.exit(0);
});