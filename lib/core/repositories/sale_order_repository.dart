import '../database/database_helper.dart';
import '../models/sale_order.dart';

class SaleOrderRepository {
  final _db = DatabaseHelper.instance;

  Future<List<SaleOrder>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT so.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM sale_orders so
      JOIN clients c  ON c.id  = so.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      ORDER BY so.date DESC
    ''', []);
    return rows.map((r) => SaleOrder.fromMap(r)).toList();
  }

  Future<SaleOrder?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT so.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM sale_orders so
      JOIN clients c  ON c.id  = so.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE so.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;

    final items = await _getItems(id);
    return SaleOrder.fromMap(rows.first, items: items);
  }

  Future<List<SaleOrderItem>> _getItems(int orderId) async {
    final rows = await _db.rawQuery('''
      SELECT soi.*, p.name AS product_name
      FROM sale_order_items soi
      LEFT JOIN products p ON p.id = soi.product_id
      WHERE soi.order_id = ?
    ''', [orderId]);
    return rows.map(SaleOrderItem.fromMap).toList();
  }

  Future<SaleOrder> insert(SaleOrder order, List<SaleOrderItem> items) async {
    final db = DatabaseHelper.instance;
    final dbConn = await db.database;

    late SaleOrder saved;
    await dbConn.transaction((txn) async {
      // Recalculate totals from items
      double ht = 0, tva = 0;
      for (final item in items) {
        ht += item.totalHt;
        tva += item.totalTva;
      }
      final ttc = ht + tva;

      final map = order.toMap()
        ..['total_ht'] = ht
        ..['total_tva'] = tva
        ..['total_ttc'] = ttc;

      final id = await txn.insert('sale_orders', map);
      for (final item in items) {
        await txn.insert(
            'sale_order_items', item.toMap()..['order_id'] = id);
      }
      saved = order.copyWith(id: id, totalHt: ht, totalTva: tva, totalTtc: ttc);
    });
    return saved;
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('sale_orders', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('sale_orders', id);
  }

  Future<int> nextSequence() async {
    final n = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM sale_orders', []);
    return (n ?? 0) + 1;
  }
}
