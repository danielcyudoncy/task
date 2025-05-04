// main.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/bootstrap.dart';

void _initializeFirestoreMetrics() async {
  final docRef = FirebaseFirestore.instance
      .collection('dashboard_metrics')
      .doc('summary');

  final doc = await docRef.get();
  if (!doc.exists) {
    await docRef.set({
      'totalUsers': 0,
      'tasks': {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'overdue': 0,
      },
    });
  }
}

Future<void> main() async {
  await bootstrapApp();
  _initializeFirestoreMetrics();
}
