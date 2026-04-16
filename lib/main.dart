import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web (Firebase Studio, Vercel, Netlify …): use WebAssembly SQLite
    databaseFactory = databaseFactoryFfiWeb;
  } else if (!Platform.isAndroid && !Platform.isIOS) {
    // Desktop (Windows / Linux / macOS): use FFI SQLite
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Mobile (Android / iOS): default sqflite factory — no setup needed

  await initializeDateFormatting('fr_MA', null);
  await DatabaseHelper.instance.database;

  runApp(
    const ProviderScope(
      child: WinsoftApp(),
    ),
  );
}
