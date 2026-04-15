import '../database/database_helper.dart';
import '../models/fiscal_year.dart';

class FiscalYearRepository {
  final _db = DatabaseHelper.instance;

  Future<List<FiscalYear>> getAll() async {
    final rows = await _db.rawQuery(
        'SELECT * FROM fiscal_years ORDER BY start_date DESC', []);
    return rows.map(FiscalYear.fromMap).toList();
  }

  Future<FiscalYear?> getCurrent() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await _db.rawQuery('''
      SELECT * FROM fiscal_years
      WHERE start_date <= ? AND end_date >= ? AND status = 'Ouverte'
      ORDER BY start_date DESC LIMIT 1
    ''', [now, now]);
    if (rows.isEmpty) return null;
    return FiscalYear.fromMap(rows.first);
  }

  Future<void> insert(FiscalYear fy) async {
    final db = await _db.database;
    await db.insert('fiscal_years', fy.toMap());
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('fiscal_years', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('fiscal_years', id);
  }
}
