import '../database/database_helper.dart';
import '../models/product_category.dart';

class ProductCategoryRepository {
  final _db = DatabaseHelper.instance;

  Future<List<ProductCategory>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT pc.*, p.name AS parent_name
      FROM product_categories pc
      LEFT JOIN product_categories p ON p.id = pc.parent_id
      ORDER BY pc.parent_id NULLS FIRST, pc.name ASC
    ''', []);
    return rows.map(ProductCategory.fromMap).toList();
  }

  Future<void> insert(ProductCategory category) async {
    final db = await _db.database;
    await db.insert('product_categories', category.toMap());
  }

  Future<void> update(ProductCategory category) async {
    final db = await _db.database;
    await db.update('product_categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> delete(int id) async {
    await _db.delete('product_categories', id);
  }
}
