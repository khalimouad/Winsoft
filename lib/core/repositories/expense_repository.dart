import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Expense>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT e.*, emp.name AS employee_name
      FROM expenses e
      LEFT JOIN employees emp ON emp.id = e.employee_id
      ORDER BY e.date DESC
    ''', []);
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getByEmployee(int employeeId) async {
    final rows = await _db.rawQuery('''
      SELECT e.*, emp.name AS employee_name
      FROM expenses e
      LEFT JOIN employees emp ON emp.id = e.employee_id
      WHERE e.employee_id = ?
      ORDER BY e.date DESC
    ''', [employeeId]);
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> insert(Expense expense) async {
    final db = await _db.database;
    await db.insert('expenses', expense.toMap());
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('expenses', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('expenses', id);
  }

  Future<double> totalByStatus(String status) async {
    final v = await _db.rawQueryDouble(
        "SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE status = ?",
        [status]);
    return v ?? 0;
  }

  Future<List<Map<String, dynamic>>> byCategory() async {
    return _db.rawQuery('''
      SELECT category,
             COUNT(*) AS count,
             SUM(amount) AS total
      FROM expenses
      WHERE status NOT IN ('Rejetée')
      GROUP BY category
      ORDER BY total DESC
    ''', []);
  }
}
