import '../database/database_helper.dart';
import '../models/bank_account.dart';

class BankAccountRepository {
  final _db = DatabaseHelper.instance;

  Future<List<BankAccount>> getAll() async {
    final rows = await _db.rawQuery(
        'SELECT * FROM bank_accounts ORDER BY is_default DESC, name ASC',
        []);
    return rows.map(BankAccount.fromMap).toList();
  }

  Future<void> insert(BankAccount account) async {
    final db = await _db.database;
    await db.insert('bank_accounts', account.toMap());
  }

  Future<void> update(BankAccount account) async {
    final db = await _db.database;
    await db.update('bank_accounts', account.toMap(),
        where: 'id = ?', whereArgs: [account.id]);
  }

  Future<void> setDefault(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('bank_accounts', {'is_default': 0});
      await txn.update('bank_accounts', {'is_default': 1},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> delete(int id) async {
    await _db.delete('bank_accounts', id);
  }

  // ── Aggregates ────────────────────────────────────────────────────────────

  /// TVA collectée sur les factures pour une période
  Future<double> tvaCollected(int fromMs, int toMs) async {
    final v = await _db.rawQueryDouble('''
      SELECT COALESCE(SUM(total_tva), 0)
      FROM invoices
      WHERE issued_date BETWEEN ? AND ?
        AND status NOT IN ('Brouillon', 'Annulée')
    ''', [fromMs, toMs]);
    return v ?? 0;
  }

  /// TVA déductible sur les factures fournisseurs pour une période
  Future<double> tvaDeductible(int fromMs, int toMs) async {
    final v = await _db.rawQueryDouble('''
      SELECT COALESCE(SUM(total_tva), 0)
      FROM supplier_invoices
      WHERE issued_date BETWEEN ? AND ?
        AND status NOT IN ('Annulée')
    ''', [fromMs, toMs]);
    return v ?? 0;
  }

  /// Aged receivables — unpaid client invoices grouped by aging bucket
  Future<List<Map<String, dynamic>>> agedReceivables() async {
    final rows = await _db.rawQuery('''
      SELECT
        inv.id,
        inv.reference,
        c.name AS client_name,
        inv.due_date,
        inv.total_ttc,
        COALESCE((SELECT SUM(pr.amount) FROM payments_received pr WHERE pr.invoice_id = inv.id), 0) AS amount_paid
      FROM invoices inv
      JOIN clients c ON c.id = inv.client_id
      WHERE inv.status NOT IN ('Payée', 'Brouillon', 'Annulée')
      ORDER BY inv.due_date ASC
    ''', []);
    return rows.toList();
  }

  /// Aged payables — unpaid supplier invoices grouped by aging
  Future<List<Map<String, dynamic>>> agedPayables() async {
    final rows = await _db.rawQuery('''
      SELECT
        si.id,
        si.reference,
        s.name AS supplier_name,
        si.due_date,
        si.total_ttc,
        COALESCE((SELECT SUM(ps.amount) FROM payments_sent ps WHERE ps.supplier_invoice_id = si.id), 0) AS amount_paid
      FROM supplier_invoices si
      JOIN suppliers s ON s.id = si.supplier_id
      WHERE si.status NOT IN ('Payée', 'Annulée')
      ORDER BY si.due_date ASC
    ''', []);
    return rows.toList();
  }
}
