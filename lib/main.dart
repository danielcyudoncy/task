// main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://supabase.com/dashboard/project/avivxpqksbqncnjuwxia',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2aXZ4cHFrc2JxbmNuanV3eGlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNjA1MjYsImV4cCI6MjA2MzkzNjUyNn0.aD0dUoVQ0pe08nt9WEbohCJcC6QxSyQ9QfnfvFSUinQ',
    debug: true,
  );

  await bootstrapApp();
}
