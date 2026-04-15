import '../database/database_helper.dart';
import '../models/employee_contract.dart';

class EmployeeContractRepository {
  final _db = DatabaseHelper.instance;

  Future<List<EmployeeContract>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT ec.*, e.name AS employee_name
      FROM employee_contracts ec
      JOIN employees e ON e.id = ec.employee_id
      ORDER BY ec.start_date DESC
    ''', []);
    return rows.map(EmployeeContract.fromMap).toList();
  }

  Future<List<EmployeeContract>> getByEmployeeId(int employeeId) async {
    final rows = await _db.rawQuery('''
      SELECT ec.*, e.name AS employee_name
      FROM employee_contracts ec
      JOIN employees e ON e.id = ec.employee_id
      WHERE ec.employee_id = ?
      ORDER BY ec.start_date DESC
    ''', [employeeId]);
    return rows.map(EmployeeContract.fromMap).toList();
  }

  Future<void> insert(EmployeeContract contract) async {
    final db = await _db.database;
    await db.insert('employee_contracts', contract.toMap());
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('employee_contracts', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('employee_contracts', id);
  }
}
