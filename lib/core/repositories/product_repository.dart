import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Product>> getAll() async {
    final rows = await _db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getActive() async {
    final rows = await _db.query('products',
        where: "status = 'Actif'", orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(int id) async {
    final rows =
        await _db.query('products', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<Product> insert(Product product) async {
    final id = await _db.insert('products', product.toMap());
    return product.copyWith(id: id);
  }

  Future<void> update(Product product) async {
    await _db.update('products', product.toMap(), product.id!);
  }

  Future<void> delete(int id) async {
    await _db.delete('products', id);
  }

  Future<List<String>> getCategories() async {
    final rows = await _db.rawQuery(
        'SELECT DISTINCT category FROM products WHERE category IS NOT NULL ORDER BY category',
        []);
    return rows
        .map((r) => r['category'] as String)
        .toList();
  }
}
