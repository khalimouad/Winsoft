import '../database/database_helper.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Supplier>> getAll() async {
    final rows =
        await _db.query('suppliers', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<Supplier?> getById(int id) async {
    final rows =
        await _db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Supplier.fromMap(rows.first);
  }

  Future<int> insert(Supplier s) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = s.toMap();
    map['created_at'] = now;
    return _db.insert('suppliers', map);
  }

  Future<int> update(Supplier s) async =>
      _db.update('suppliers', s.toMap(), s.id!);

  Future<int> delete(int id) async => _db.delete('suppliers', id);
}
