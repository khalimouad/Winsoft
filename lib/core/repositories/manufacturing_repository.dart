import '../database/database_helper.dart';
import '../models/manufacturing_bom.dart';

class ManufacturingRepository {
  final _db = DatabaseHelper.instance;

  // ── BOMs ───────────────────────────────────────────────────────────────────

  Future<List<ManufacturingBom>> getAllBoms() async {
    final rows = await _db.query('manufacturing_boms',
        orderBy: 'name COLLATE NOCASE ASC');
    final boms = <ManufacturingBom>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final components = await _getComponents(id);
      boms.add(ManufacturingBom.fromMap(row, components: components));
    }
    return boms;
  }

  Future<ManufacturingBom?> getBomById(int id) async {
    final rows = await _db.query('manufacturing_boms',
        where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final components = await _getComponents(id);
    return ManufacturingBom.fromMap(rows.first, components: components);
  }

  Future<List<BomComponent>> _getComponents(int bomId) async {
    final rows = await _db.rawQuery('''
      SELECT bc.*, p.name AS product_name, p.reference AS product_reference
      FROM bom_components bc
      JOIN products p ON bc.product_id = p.id
      WHERE bc.bom_id = ?
      ORDER BY bc.role, p.name
    ''', [bomId]);
    return rows.map(BomComponent.fromMap).toList();
  }

  Future<int> insertBom(ManufacturingBom bom) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = bom.toMap();
      map['created_at'] = now;
      map.remove('id');
      final id = await txn.insert('manufacturing_boms', map);
      for (final c in bom.components) {
        final cm = c.toMap();
        cm['bom_id'] = id;
        cm.remove('id');
        await txn.insert('bom_components', cm);
      }
      return id;
    });
  }

  Future<void> deleteBom(int id) async => _db.delete('manufacturing_boms', id);

  // ── Production orders ──────────────────────────────────────────────────────

  Future<List<ProductionOrder>> getAllOrders() async {
    final rows = await _db.rawQuery('''
      SELECT po.*, mb.name AS bom_name
      FROM production_orders po
      LEFT JOIN manufacturing_boms mb ON po.bom_id = mb.id
      ORDER BY po.planned_date DESC
    ''', []);
    final orders = <ProductionOrder>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final outputs = await _getOutputs(id);
      orders.add(ProductionOrder.fromMap(row, outputs: outputs));
    }
    return orders;
  }

  Future<List<ProductionOutput>> _getOutputs(int orderId) async {
    final rows = await _db.rawQuery('''
      SELECT poo.*, p.name AS product_name
      FROM production_order_outputs poo
      JOIN products p ON poo.product_id = p.id
      WHERE poo.production_order_id = ?
    ''', [orderId]);
    return rows.map(ProductionOutput.fromMap).toList();
  }

  Future<int> insertOrder(ProductionOrder order) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = order.toMap();
      map['created_at'] = now;
      map.remove('id');
      final id = await txn.insert('production_orders', map);
      for (final out in order.outputs) {
        final om = out.toMap();
        om['production_order_id'] = id;
        om.remove('id');
        await txn.insert('production_order_outputs', om);
      }
      return id;
    });
  }

  Future<void> updateOrderStatus(int id, String status) async {
    final db = await _db.database;
    await db.update('production_orders', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOrder(int id) async =>
      _db.delete('production_orders', id);

  Future<int> nextSequence() async {
    final val = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM production_orders', []);
    return (val ?? 0) + 1;
  }
}
