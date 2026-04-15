import '../database/database_helper.dart';
import '../models/delivery.dart';

class DeliveryRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Delivery>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT d.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM deliveries d
      JOIN clients c  ON c.id  = d.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      ORDER BY d.date DESC
    ''', []);
    return rows.map((r) => Delivery.fromMap(r)).toList();
  }

  Future<List<Delivery>> getByOrderId(int orderId) async {
    final rows = await _db.rawQuery('''
      SELECT d.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM deliveries d
      JOIN clients c  ON c.id  = d.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE d.order_id = ?
      ORDER BY d.date DESC
    ''', [orderId]);
    return rows.map((r) => Delivery.fromMap(r)).toList();
  }

  Future<Delivery?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT d.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM deliveries d
      JOIN clients c  ON c.id  = d.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE d.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final items = await _getItems(id);
    return Delivery.fromMap(rows.first, items: items);
  }

  Future<List<DeliveryItem>> _getItems(int deliveryId) async {
    final rows = await _db.rawQuery('''
      SELECT di.*, p.name AS product_name
      FROM delivery_items di
      LEFT JOIN products p ON p.id = di.product_id
      WHERE di.delivery_id = ?
    ''', [deliveryId]);
    return rows.map(DeliveryItem.fromMap).toList();
  }

  Future<List<DeliveryItem>> getItemsByDeliveryId(int deliveryId) =>
      _getItems(deliveryId);

  Future<Delivery> insert(Delivery delivery, List<DeliveryItem> items) async {
    final dbConn = await _db.database;
    late Delivery saved;

    await dbConn.transaction((txn) async {
      double ht = 0, tva = 0;
      for (final item in items) {
        ht += item.totalHt;
        tva += item.totalTva;
      }
      final ttc = ht + tva;

      final map = delivery.toMap()
        ..['total_ht'] = ht
        ..['total_tva'] = tva
        ..['total_ttc'] = ttc;

      final id = await txn.insert('deliveries', map);
      for (final item in items) {
        await txn.insert(
            'delivery_items', item.toMap()..['delivery_id'] = id);
      }
      saved = delivery.copyWith(
          id: id, totalHt: ht, totalTva: tva, totalTtc: ttc);
    });
    return saved;
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('deliveries', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('deliveries', id);
  }
}
