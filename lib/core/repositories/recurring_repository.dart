import '../database/database_helper.dart';
import '../models/recurring_template.dart';

class RecurringRepository {
  final _db = DatabaseHelper.instance;

  Future<List<RecurringTemplate>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT rt.*, c.name AS client_name
      FROM recurring_templates rt
      LEFT JOIN clients c ON rt.client_id = c.id
      ORDER BY rt.next_due_date ASC
    ''', []);
    final result = <RecurringTemplate>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final items = await _getItems(id);
      result.add(RecurringTemplate.fromMap(row, items: items));
    }
    return result;
  }

  Future<List<RecurringItem>> _getItems(int templateId) async {
    final rows = await _db.query('recurring_items',
        where: 'template_id = ?', whereArgs: [templateId]);
    return rows.map(RecurringItem.fromMap).toList();
  }

  Future<int> insert(RecurringTemplate t) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = t.toMap();
      map['created_at'] = now;
      map.remove('id');
      final id = await txn.insert('recurring_templates', map);
      for (final item in t.items) {
        final im = item.toMap();
        im['template_id'] = id;
        im.remove('id');
        await txn.insert('recurring_items', im);
      }
      return id;
    });
  }

  Future<void> updateNextDue(int id, int nextDueDate) async {
    final db = await _db.database;
    await db.update('recurring_templates', {'next_due_date': nextDueDate},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async =>
      _db.delete('recurring_templates', id);

  /// Templates due today or overdue.
  Future<List<RecurringTemplate>> getDue() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await _db.rawQuery('''
      SELECT rt.*, c.name AS client_name
      FROM recurring_templates rt
      LEFT JOIN clients c ON rt.client_id = c.id
      WHERE rt.is_active = 1 AND rt.next_due_date <= ?
      ORDER BY rt.next_due_date ASC
    ''', [now]);
    final result = <RecurringTemplate>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final items = await _getItems(id);
      result.add(RecurringTemplate.fromMap(row, items: items));
    }
    return result;
  }
}
