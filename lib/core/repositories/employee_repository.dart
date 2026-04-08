import '../database/database_helper.dart';
import '../models/employee.dart';
import '../models/payroll_slip.dart';

class EmployeeRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Employee>> getAll() async {
    final rows =
        await _db.query('employees', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee?> getById(int id) async {
    final rows =
        await _db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Employee.fromMap(rows.first);
  }

  Future<int> insert(Employee e) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = e.toMap();
    map['created_at'] = now;
    return _db.insert('employees', map);
  }

  Future<int> update(Employee e) async =>
      _db.update('employees', e.toMap(), e.id!);

  Future<int> delete(int id) async => _db.delete('employees', id);

  // ── Payroll ────────────────────────────────────────────────────────────────

  Future<List<PayrollSlip>> getPayrollSlips(
      {int? year, int? month, int? employeeId}) async {
    final conds = <String>[];
    final args = <Object?>[];
    if (year != null) {
      conds.add('ps.period_year = ?');
      args.add(year);
    }
    if (month != null) {
      conds.add('ps.period_month = ?');
      args.add(month);
    }
    if (employeeId != null) {
      conds.add('ps.employee_id = ?');
      args.add(employeeId);
    }
    final where = conds.isEmpty ? '' : 'WHERE ${conds.join(' AND ')}';
    final rows = await _db.rawQuery('''
      SELECT ps.*,
             e.name  AS employee_name,
             e.cin   AS employee_cin,
             e.position AS employee_position
      FROM payroll_slips ps
      JOIN employees e ON ps.employee_id = e.id
      $where
      ORDER BY ps.period_year DESC, ps.period_month DESC, e.name ASC
    ''', args);
    return rows.map(PayrollSlip.fromMap).toList();
  }

  Future<int> insertPayrollSlip(PayrollSlip slip) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = slip.toMap();
    map['created_at'] = now;
    return _db.insert('payroll_slips', map);
  }

  Future<void> updatePayrollStatus(int id, String status) async {
    final db = await _db.database;
    await db.update('payroll_slips', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePayrollSlip(int id) async =>
      _db.delete('payroll_slips', id);

  // ── Leaves ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeaves({int? employeeId}) async {
    if (employeeId != null) {
      return _db.rawQuery('''
        SELECT l.*, e.name AS employee_name
        FROM leaves l JOIN employees e ON l.employee_id = e.id
        WHERE l.employee_id = ?
        ORDER BY l.start_date DESC
      ''', [employeeId]);
    }
    return _db.rawQuery('''
      SELECT l.*, e.name AS employee_name
      FROM leaves l JOIN employees e ON l.employee_id = e.id
      ORDER BY l.start_date DESC
    ''', []);
  }

  Future<int> insertLeave(Map<String, dynamic> leave) async {
    leave['created_at'] = DateTime.now().millisecondsSinceEpoch;
    return _db.insert('leaves', leave);
  }

  Future<void> updateLeaveStatus(int id, String status) async {
    final db = await _db.database;
    await db.update('leaves', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }
}
