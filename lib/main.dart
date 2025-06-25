// main.dart
import 'package:flutter/material.dart';
import 'package:task/core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await bootstrapApp();
  } catch (error, stackTrace) {
    // Log errors to Crashlytics/Sentry or show a fallback UI
    debugPrint('Bootstrap failed: $error\n$stackTrace');
    runApp(FallbackApp(error: error)); // Custom error widget
  }
}
class FallbackApp extends StatelessWidget {
  final Object error;

  const FallbackApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('An error occurred: $error'),
        ),
      ),
    );
  }
}