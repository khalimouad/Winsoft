import '../database/database_helper.dart';
import '../models/purchase_order.dart';

class PurchaseOrderRepository {
  final _db = DatabaseHelper.instance;

  Future<List<PurchaseOrder>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT po.*, s.name AS supplier_name
      FROM purchase_orders po
      LEFT JOIN suppliers s ON po.supplier_id = s.id
      ORDER BY po.date DESC
    ''', []);
    return rows.map((r) => PurchaseOrder.fromMap(r)).toList();
  }

  Future<PurchaseOrder?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT po.*, s.name AS supplier_name
      FROM purchase_orders po
      LEFT JOIN suppliers s ON po.supplier_id = s.id
      WHERE po.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final items = await _db.query('purchase_order_items',
        where: 'order_id = ?', whereArgs: [id]);
    return PurchaseOrder.fromMap(rows.first,
        items: items.map(PurchaseOrderItem.fromMap).toList());
  }

  Future<int> insert(PurchaseOrder order) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = order.toMap();
      map['created_at'] = now;
      map.remove('id');
      final id = await txn.insert('purchase_orders', map);
      for (final item in order.items) {
        final im = item.toMap();
        im['order_id'] = id;
        im.remove('id');
        await txn.insert('purchase_order_items', im);
      }
      return id;
    });
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _db.database;
    await db.update('purchase_orders', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async => _db.delete('purchase_orders', id);

  Future<int> nextSequence() async {
    final val = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM purchase_orders', []);
    return (val ?? 0) + 1;
  }
}
