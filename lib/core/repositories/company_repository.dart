import '../database/database_helper.dart';
import '../models/company.dart';

class CompanyRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Company>> getAll() async {
    final rows = await _db.query('companies', orderBy: 'name ASC');
    return rows.map(Company.fromMap).toList();
  }

  Future<Company?> getById(int id) async {
    final rows =
        await _db.query('companies', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Company.fromMap(rows.first);
  }

  Future<Company> insert(Company company) async {
    final map = company.toMap();
    final id = await _db.insert('companies', map);
    return company.copyWith(id: id);
  }

  Future<void> update(Company company) async {
    await _db.update('companies', company.toMap(), company.id!);
  }

  Future<void> delete(int id) async {
    await _db.delete('companies', id);
  }

  /// Count of clients linked to this company
  Future<int> clientCount(int companyId) async {
    final n = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM clients WHERE company_id = ?', [companyId]);
    return n ?? 0;
  }
}
