import '../database/database_helper.dart';
import '../models/reception.dart';

class ReceptionRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Reception>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT r.*, s.name AS supplier_name
      FROM receptions r
      JOIN suppliers s ON s.id = r.supplier_id
      ORDER BY r.date DESC
    ''', []);
    return rows.map((m) => Reception.fromMap(m)).toList();
  }

  Future<List<Reception>> getByPurchaseOrderId(int poId) async {
    final rows = await _db.rawQuery('''
      SELECT r.*, s.name AS supplier_name
      FROM receptions r
      JOIN suppliers s ON s.id = r.supplier_id
      WHERE r.purchase_order_id = ?
      ORDER BY r.date DESC
    ''', [poId]);
    return rows.map((m) => Reception.fromMap(m)).toList();
  }

  Future<Reception?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT r.*, s.name AS supplier_name
      FROM receptions r
      JOIN suppliers s ON s.id = r.supplier_id
      WHERE r.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final items = await _getItems(id);
    return Reception.fromMap(rows.first, items: items);
  }

  Future<List<ReceptionItem>> _getItems(int receptionId) async {
    final rows = await _db.rawQuery('''
      SELECT ri.*, p.name AS product_name
      FROM reception_items ri
      LEFT JOIN products p ON p.id = ri.product_id
      WHERE ri.reception_id = ?
    ''', [receptionId]);
    return rows.map(ReceptionItem.fromMap).toList();
  }

  Future<Reception> insert(Reception reception, List<ReceptionItem> items) async {
    final dbConn = await _db.database;
    late Reception saved;

    await dbConn.transaction((txn) async {
      double ht = 0, tva = 0;
      for (final item in items) {
        ht += item.totalHt;
        tva += item.totalTva;
      }
      final ttc = ht + tva;

      final map = reception.toMap()
        ..['total_ht'] = ht
        ..['total_tva'] = tva
        ..['total_ttc'] = ttc;

      final id = await txn.insert('receptions', map);
      for (final item in items) {
        await txn.insert('reception_items', item.toMap()..['reception_id'] = id);
      }
      saved = reception.copyWith(
          id: id, totalHt: ht, totalTva: tva, totalTtc: ttc);
    });
    return saved;
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('receptions', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('receptions', id);
  }

  Future<int> nextSequence() async {
    final n = await _db.rawQueryScalar('SELECT COUNT(*) FROM receptions', []);
    return (n ?? 0) + 1;
  }
}
