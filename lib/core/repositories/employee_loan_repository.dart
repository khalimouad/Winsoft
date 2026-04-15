import '../database/database_helper.dart';
import '../models/employee_loan.dart';

class EmployeeLoanRepository {
  final _db = DatabaseHelper.instance;

  Future<List<EmployeeLoan>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT el.*, e.name AS employee_name
      FROM employee_loans el
      JOIN employees e ON e.id = el.employee_id
      ORDER BY el.start_date DESC
    ''', []);
    return rows.map(EmployeeLoan.fromMap).toList();
  }

  Future<List<EmployeeLoan>> getActive() async {
    final rows = await _db.rawQuery('''
      SELECT el.*, e.name AS employee_name
      FROM employee_loans el
      JOIN employees e ON e.id = el.employee_id
      WHERE el.status = 'En cours'
      ORDER BY el.start_date ASC
    ''', []);
    return rows.map(EmployeeLoan.fromMap).toList();
  }

  Future<void> insert(EmployeeLoan loan) async {
    final db = await _db.database;
    await db.insert('employee_loans', loan.toMap());
  }

  Future<void> recordPayment(int id, double payment) async {
    final db = await _db.database;
    await db.rawUpdate('''
      UPDATE employee_loans
      SET amount_paid = amount_paid + ?
      WHERE id = ?
    ''', [payment, id]);
    // Auto-mark as repaid if fully paid
    final rows = await _db.rawQuery(
        'SELECT amount, amount_paid FROM employee_loans WHERE id = ?',
        [id]);
    if (rows.isNotEmpty) {
      final total = (rows.first['amount'] as num).toDouble();
      final paid = (rows.first['amount_paid'] as num).toDouble();
      if (paid >= total - 0.01) {
        await _db.update('employee_loans', {'status': 'Remboursé'}, id);
      }
    }
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('employee_loans', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('employee_loans', id);
  }
}
