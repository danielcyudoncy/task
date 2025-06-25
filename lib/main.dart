// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:task/core/bootstrap.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:task/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables early
    await dotenv.load(fileName: "assets/.env");

    // Initialize Firebase before app starts
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _verifyFirebaseServices();

    await bootstrapApp();
  } catch (error, stackTrace) {
    debugPrint('Bootstrap failed: $error\n$stackTrace');
    runApp(FallbackApp(error: error.toString()));
  }
}

class FallbackApp extends StatelessWidget {
  final String error;

  const FallbackApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(title: const Text('Initialization Error')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'App failed to initialize',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
Future<void> _verifyFirebaseServices() async {
  try {
    // Test Firestore connection
    await FirebaseFirestore.instance.collection('test').doc('test').get();

    // Test Realtime Database connection
    final database = FirebaseDatabase.instance;
    await database.ref('.info/connected').once();
  } catch (e) {
    throw Exception('Firebase service verification failed: $e');
  }
}
