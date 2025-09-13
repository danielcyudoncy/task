// lib/core/db_factory_web.dart
// Web implementation using sqflite_common_ffi_web

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Configure database factory for web so global openDatabase works.
/// Use the non-web-worker variant to avoid SharedArrayBuffer/Cross-Origin
/// isolation issues on hosts that don't set the required headers.
void configureDbFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
