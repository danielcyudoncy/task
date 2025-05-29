// main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import
import 'core/bootstrap.dart';

/// Initializes Firestore dashboard metrics if they do not exist.
Future<void> _initializeFirestoreMetrics() async {
  final docRef =
      FirebaseFirestore.instance.collection('dashboard_metrics').doc('summary');

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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase per latest best practice.
  await Supabase.initialize(
    url: 'https://supabase.com/dashboard/project/avivxpqksbqncnjuwxia',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2aXZ4cHFrc2JxbmNuanV3eGlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNjA1MjYsImV4cCI6MjA2MzkzNjUyNn0.aD0dUoVQ0pe08nt9WEbohCJcC6QxSyQ9QfnfvFSUinQ', 
    debug: true, // Enable detailed error logs (optional)
  );

  await bootstrapApp();
  await _initializeFirestoreMetrics(); // Await this to ensure metrics are set

  // No need to runApp here if bootstrapApp() does it internally.
}
