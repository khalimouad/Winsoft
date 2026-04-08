import '../database/database_helper.dart';
import '../models/supplier_invoice.dart';

class SupplierInvoiceRepository {
  final _db = DatabaseHelper.instance;

  Future<List<SupplierInvoice>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT si.*, s.name AS supplier_name
      FROM supplier_invoices si
      LEFT JOIN suppliers s ON si.supplier_id = s.id
      ORDER BY si.issued_date DESC
    ''', []);
    return rows.map((r) => SupplierInvoice.fromMap(r)).toList();
  }

  Future<int> insert(SupplierInvoice inv) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final map = inv.toMap();
      map.remove('id');
      final id = await txn.insert('supplier_invoices', map);
      for (final item in inv.items) {
        final im = item.toMap();
        im['invoice_id'] = id;
        im.remove('id');
        await txn.insert('supplier_invoice_items', im);
      }
      return id;
    });
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _db.database;
    await db.update('supplier_invoices', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async => _db.delete('supplier_invoices', id);

  Future<int> nextSequence() async {
    final val = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM supplier_invoices', []);
    return (val ?? 0) + 1;
  }

  Future<Map<String, dynamic>> summary() async {
    final rows = await _db.rawQuery('''
      SELECT status, COUNT(*) AS cnt, SUM(total_ttc) AS amount
      FROM supplier_invoices GROUP BY status
    ''', []);
    final result = <String, dynamic>{};
    for (final r in rows) {
      result[r['status'] as String] = {
        'count': r['cnt'],
        'amount': r['amount'],
      };
    }
    return result;
  }
}
