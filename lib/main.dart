import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for Windows / Linux desktop
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize French locale for intl (MAD currency + dates)
  await initializeDateFormatting('fr_MA', null);

  // Warm up the database (runs onCreate + seed on first launch)
  await DatabaseHelper.instance.database;

  runApp(
    const ProviderScope(
      child: WinsoftApp(),
    ),
  );
}
