import '../database/database_helper.dart';
import '../models/credit_note.dart';

class CreditNoteRepository {
  final _db = DatabaseHelper.instance;

  Future<List<CreditNote>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT cn.*, c.name AS client_name, i.reference AS invoice_reference
      FROM credit_notes cn
      LEFT JOIN clients c  ON cn.client_id  = c.id
      LEFT JOIN invoices i ON cn.invoice_id = i.id
      ORDER BY cn.issue_date DESC
    ''', []);
    return rows.map(CreditNote.fromMap).toList();
  }

  Future<int> insert(CreditNote cn) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = cn.toMap();
    map['created_at'] = now;
    map.remove('id');
    return _db.insert('credit_notes', map);
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _db.database;
    await db.update('credit_notes', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async => _db.delete('credit_notes', id);

  Future<int> nextSequence() async {
    final val = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM credit_notes', []);
    return (val ?? 0) + 1;
  }
}
