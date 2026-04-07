import '../database/database_helper.dart';
import '../models/client.dart';

class ClientRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Client>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT c.*, co.name AS company_name
      FROM clients c
      LEFT JOIN companies co ON co.id = c.company_id
      ORDER BY c.name ASC
    ''', []);
    return rows.map(Client.fromMap).toList();
  }

  Future<List<Client>> getByCompany(int companyId) async {
    final rows = await _db.rawQuery('''
      SELECT c.*, co.name AS company_name
      FROM clients c
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE c.company_id = ?
      ORDER BY c.name ASC
    ''', [companyId]);
    return rows.map(Client.fromMap).toList();
  }

  Future<Client?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT c.*, co.name AS company_name
      FROM clients c
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE c.id = ?
    ''', [id]);
    return rows.isEmpty ? null : Client.fromMap(rows.first);
  }

  Future<Client> insert(Client client) async {
    final id = await _db.insert('clients', client.toMap());
    return client.copyWith(id: id);
  }

  Future<void> update(Client client) async {
    await _db.update('clients', client.toMap(), client.id!);
  }

  Future<void> delete(int id) async {
    await _db.delete('clients', id);
  }

  /// Total invoiced (TTC) for a client
  Future<double> totalSpent(int clientId) async {
    final v = await _db.rawQueryDouble(
        "SELECT COALESCE(SUM(total_ttc),0) FROM invoices WHERE client_id = ? AND status = 'Payée'",
        [clientId]);
    return v ?? 0;
  }

  /// Last order date
  Future<DateTime?> lastOrderDate(int clientId) async {
    final n = await _db.rawQueryScalar(
        'SELECT MAX(date) FROM sale_orders WHERE client_id = ?', [clientId]);
    return n == null ? null : DateTime.fromMillisecondsSinceEpoch(n);
  }
}
