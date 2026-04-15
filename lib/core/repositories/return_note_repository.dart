import '../database/database_helper.dart';
import '../models/return_note.dart';

class ReturnNoteRepository {
  final _db = DatabaseHelper.instance;

  Future<List<ReturnNote>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT rn.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM return_notes rn
      JOIN clients c  ON c.id  = rn.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      ORDER BY rn.date DESC
    ''', []);
    return rows.map((r) => ReturnNote.fromMap(r)).toList();
  }

  Future<List<ReturnNote>> getByDeliveryId(int deliveryId) async {
    final rows = await _db.rawQuery('''
      SELECT rn.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM return_notes rn
      JOIN clients c  ON c.id  = rn.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE rn.delivery_id = ?
      ORDER BY rn.date DESC
    ''', [deliveryId]);
    return rows.map((r) => ReturnNote.fromMap(r)).toList();
  }

  Future<ReturnNote?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT rn.*,
             c.name  AS client_name,
             co.name AS company_name
      FROM return_notes rn
      JOIN clients c  ON c.id  = rn.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE rn.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final items = await _getItems(id);
    return ReturnNote.fromMap(rows.first, items: items);
  }

  Future<List<ReturnNoteItem>> _getItems(int returnNoteId) async {
    final rows = await _db.rawQuery('''
      SELECT rni.*, p.name AS product_name
      FROM return_note_items rni
      LEFT JOIN products p ON p.id = rni.product_id
      WHERE rni.return_note_id = ?
    ''', [returnNoteId]);
    return rows.map(ReturnNoteItem.fromMap).toList();
  }

  Future<ReturnNote> insert(
      ReturnNote returnNote, List<ReturnNoteItem> items) async {
    final dbConn = await _db.database;
    late ReturnNote saved;

    await dbConn.transaction((txn) async {
      double ht = 0, tva = 0;
      for (final item in items) {
        ht += item.totalHt;
        tva += item.totalTva;
      }
      final ttc = ht + tva;

      final map = returnNote.toMap()
        ..['total_ht'] = ht
        ..['total_tva'] = tva
        ..['total_ttc'] = ttc;

      final id = await txn.insert('return_notes', map);
      for (final item in items) {
        await txn.insert(
            'return_note_items', item.toMap()..['return_note_id'] = id);
      }
      saved = returnNote.copyWith(
          id: id, totalHt: ht, totalTva: tva, totalTtc: ttc);
    });
    return saved;
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('return_notes', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('return_notes', id);
  }
}
