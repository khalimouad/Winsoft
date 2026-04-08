import 'dart:convert';
import 'dart:io';
import '../database/database_helper.dart';

/// Exports / imports all business data as a JSON snapshot.
class BackupService {
  BackupService._();

  static final _db = DatabaseHelper.instance;

  // Tables ordered so foreign-key parents come before children on import
  static const _tables = [
    'settings',
    'companies',
    'clients',
    'suppliers',
    'products',
    'price_lists',
    'price_list_items',
    'sale_orders',
    'sale_order_items',
    'invoices',
    'invoice_items',
    'purchase_orders',
    'purchase_order_items',
    'supplier_invoices',
    'supplier_invoice_items',
    'credit_notes',
    'recurring_templates',
    'recurring_items',
    'employees',
    'payroll_slips',
    'leaves',
    'account_chart',
    'journal_entries',
    'journal_entry_lines',
    'manufacturing_boms',
    'bom_components',
    'production_orders',
    'production_order_outputs',
    'pos_sessions',
    'pos_sales',
    'pos_sale_items',
    'stock_movements',
  ];

  // ── Export ────────────────────────────────────────────────────────────────

  /// Exports all data to a JSON file and returns the file path.
  static Future<String> export() async {
    final data = <String, dynamic>{};
    for (final table in _tables) {
      try {
        data[table] = await _db.rawQuery('SELECT * FROM $table', []);
      } catch (_) {
        data[table] = <dynamic>[];
      }
    }

    final payload = const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Winsoft',
      'data': data,
    });

    final dir = _backupDir();
    await Directory(dir).create(recursive: true);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);
    final path = '$dir${Platform.pathSeparator}winsoft_backup_$stamp.json';
    await File(path).writeAsString(payload);
    return path;
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Restores data from a JSON backup file (replaces all current data).
  static Future<void> import(String path) async {
    final content = await File(path).readAsString();
    final json    = jsonDecode(content) as Map<String, dynamic>;
    final data    = json['data'] as Map<String, dynamic>;

    final db = await _db.database;

    // Temporarily disable FK constraints while we clear + re-insert
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        // Clear in reverse order
        for (final table in _tables.reversed) {
          try {
            await txn.execute('DELETE FROM $table');
          } catch (_) {}
        }
        // Re-insert in forward order
        for (final table in _tables) {
          final rows = data[table];
          if (rows is! List) continue;
          for (final row in rows) {
            if (row is! Map) continue;
            try {
              await txn.insert(table, Map<String, dynamic>.from(row));
            } catch (_) {}
          }
        }
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  // ── List existing backups ─────────────────────────────────────────────────

  static Future<List<FileSystemEntity>> listBackups() async {
    final dir = Directory(_backupDir());
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // newest first
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _backupDir() {
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'] ?? '.';
      return '$home\\Documents\\WinsoftBackup';
    }
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/Documents/WinsoftBackup';
  }
}
