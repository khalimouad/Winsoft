import '../database/database_helper.dart';
import '../models/physical_inventory.dart';

class PhysicalInventoryRepository {
  final _db = DatabaseHelper.instance;

  Future<List<PhysicalInventory>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT pi.*, w.name AS warehouse_name
      FROM physical_inventories pi
      LEFT JOIN warehouses w ON w.id = pi.warehouse_id
      ORDER BY pi.date DESC
    ''', []);
    return rows.map((m) => PhysicalInventory.fromMap(m)).toList();
  }

  Future<PhysicalInventory?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT pi.*, w.name AS warehouse_name
      FROM physical_inventories pi
      LEFT JOIN warehouses w ON w.id = pi.warehouse_id
      WHERE pi.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final lines = await _getLines(id);
    return PhysicalInventory.fromMap(rows.first, lines: lines);
  }

  Future<List<PhysicalInventoryLine>> _getLines(int inventoryId) async {
    final rows = await _db.rawQuery('''
      SELECT pil.*, p.name AS product_name, p.reference AS product_ref
      FROM physical_inventory_lines pil
      LEFT JOIN products p ON p.id = pil.product_id
      WHERE pil.inventory_id = ?
    ''', [inventoryId]);
    return rows.map(PhysicalInventoryLine.fromMap).toList();
  }

  Future<PhysicalInventory> insert(
      PhysicalInventory inventory, List<PhysicalInventoryLine> lines) async {
    final dbConn = await _db.database;
    late PhysicalInventory saved;

    await dbConn.transaction((txn) async {
      final id = await txn.insert('physical_inventories', inventory.toMap());
      for (final line in lines) {
        await txn.insert(
            'physical_inventory_lines', line.toMap()..['inventory_id'] = id);
      }
      saved = inventory.copyWith(id: id, lines: lines);
    });
    return saved;
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('physical_inventories', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('physical_inventories', id);
  }

  Future<int> nextSequence() async {
    final n = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM physical_inventories', []);
    return (n ?? 0) + 1;
  }
}
