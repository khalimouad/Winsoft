import '../database/database_helper.dart';
import '../models/warehouse.dart';

class WarehouseRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Warehouse>> getAll() async {
    final rows = await _db.rawQuery(
        'SELECT * FROM warehouses WHERE is_active = 1 ORDER BY is_default DESC, name ASC',
        []);
    return rows.map(Warehouse.fromMap).toList();
  }

  Future<Warehouse?> getDefault() async {
    final rows = await _db.rawQuery(
        'SELECT * FROM warehouses WHERE is_default = 1 LIMIT 1', []);
    if (rows.isEmpty) return null;
    return Warehouse.fromMap(rows.first);
  }

  Future<void> insert(Warehouse warehouse) async {
    final db = await _db.database;
    await db.insert('warehouses', warehouse.toMap());
  }

  Future<void> update(Warehouse warehouse) async {
    final db = await _db.database;
    await db.update('warehouses', warehouse.toMap(),
        where: 'id = ?', whereArgs: [warehouse.id]);
  }

  Future<void> setDefault(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('warehouses', {'is_default': 0});
      await txn.update('warehouses', {'is_default': 1},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> delete(int id) async {
    await _db.delete('warehouses', id);
  }
}
