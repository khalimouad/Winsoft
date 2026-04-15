import '../database/database_helper.dart';
import '../models/purchase_request.dart';

class PurchaseRequestRepository {
  final _db = DatabaseHelper.instance;

  Future<List<PurchaseRequest>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT * FROM purchase_requests
      ORDER BY date DESC
    ''', []);
    return rows.map((m) => PurchaseRequest.fromMap(m)).toList();
  }

  Future<PurchaseRequest?> getById(int id) async {
    final rows = await _db.rawQuery(
        'SELECT * FROM purchase_requests WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    final items = await _getItems(id);
    return PurchaseRequest.fromMap(rows.first, items: items);
  }

  Future<List<PurchaseRequestItem>> _getItems(int requestId) async {
    final rows = await _db.rawQuery('''
      SELECT pri.*, p.name AS product_name
      FROM purchase_request_items pri
      LEFT JOIN products p ON p.id = pri.product_id
      WHERE pri.request_id = ?
    ''', [requestId]);
    return rows.map(PurchaseRequestItem.fromMap).toList();
  }

  Future<PurchaseRequest> insert(
      PurchaseRequest request, List<PurchaseRequestItem> items) async {
    final dbConn = await _db.database;
    late PurchaseRequest saved;

    await dbConn.transaction((txn) async {
      final id = await txn.insert('purchase_requests', request.toMap());
      for (final item in items) {
        await txn.insert(
            'purchase_request_items', item.toMap()..['request_id'] = id);
      }
      saved = request.copyWith(id: id);
    });
    return saved;
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('purchase_requests', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('purchase_requests', id);
  }

  Future<int> nextSequence() async {
    final n = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM purchase_requests', []);
    return (n ?? 0) + 1;
  }
}
