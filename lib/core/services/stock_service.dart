import '../database/database_helper.dart';

/// Handles all stock movements: decrement on sales, increment on purchases.
class StockService {
  StockService._();

  static final _db = DatabaseHelper.instance;

  // ── Adjust stock ───────────────────────────────────────────────────────────

  static Future<void> adjustStock(
      int productId, double qty, String type, String reference) async {
    final db = await _db.database;
    // Log movement
    await db.insert('stock_movements', {
      'product_id': productId,
      'quantity': qty,
      'type': type,
      'reference': reference,
      'date': DateTime.now().millisecondsSinceEpoch,
    });
    // Update product stock
    await db.rawUpdate('''
      UPDATE products SET stock = COALESCE(stock, 0) + ?
      WHERE id = ? AND stock IS NOT NULL
    ''', [qty, productId]);
  }

  /// Decrement stock for each item in a POS sale.
  static Future<void> decrementForPosSale(
      String saleRef, List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final productId = item['product_id'] as int?;
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
      if (productId == null) continue;
      await adjustStock(productId, -qty, 'sale_pos', saleRef);
    }
  }

  /// Increment stock when a purchase order is received.
  static Future<void> incrementForPurchase(
      String orderRef, List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final productId = item['product_id'] as int?;
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
      if (productId == null) continue;
      await adjustStock(productId, qty, 'purchase_received', orderRef);
    }
  }

  /// Get low-stock products (stock > 0 but below threshold).
  static Future<List<Map<String, dynamic>>> getLowStock(
      {int threshold = 5}) async {
    return _db.rawQuery('''
      SELECT id, name, reference, stock, unit
      FROM products
      WHERE stock IS NOT NULL AND stock <= ? AND stock >= 0 AND status = 'Actif'
      ORDER BY stock ASC
    ''', [threshold]);
  }

  /// Get stock movement history for a product.
  static Future<List<Map<String, dynamic>>> getMovements(int productId) async {
    return _db.rawQuery('''
      SELECT sm.*, p.name AS product_name
      FROM stock_movements sm
      JOIN products p ON sm.product_id = p.id
      WHERE sm.product_id = ?
      ORDER BY sm.date DESC
      LIMIT 50
    ''', [productId]);
  }
}
