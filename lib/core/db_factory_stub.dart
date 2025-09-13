// lib/core/db_factory_stub.dart
// Default (non-web) implementation: no configuration needed.

import 'package:sqflite/sqflite.dart';

/// Configure database factory for the current platform.
/// On non-web platforms, sqflite provides the factory by default.
void configureDbFactory() {
  // No-op on Android/iOS/macOS/Windows/Linux where sqflite is available.
  // databaseFactory is initialized by the sqflite plugin itself.
  // Keeping this function ensures unified call sites via conditional imports.
  final _ = databaseFactory; // reference to avoid unused import warnings
}
