import '../database/database_helper.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Invoice>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT inv.*,
             c.name  AS client_name,
             co.name AS company_name,
             COALESCE((
               SELECT SUM(pr.amount)
               FROM payments_received pr
               WHERE pr.invoice_id = inv.id
             ), 0) AS amount_paid
      FROM invoices inv
      JOIN clients c  ON c.id  = inv.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      ORDER BY inv.issued_date DESC
    ''', []);
    return rows.map((r) => Invoice.fromMap(r)).toList();
  }

  Future<Invoice?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT inv.*,
             c.name  AS client_name,
             co.name AS company_name,
             COALESCE((
               SELECT SUM(pr.amount)
               FROM payments_received pr
               WHERE pr.invoice_id = inv.id
             ), 0) AS amount_paid
      FROM invoices inv
      JOIN clients c  ON c.id  = inv.client_id
      LEFT JOIN companies co ON co.id = c.company_id
      WHERE inv.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final items = await _getItems(id);
    return Invoice.fromMap(rows.first, items: items);
  }

  Future<List<InvoiceItem>> _getItems(int invoiceId) async {
    final rows = await _db.rawQuery('''
      SELECT ii.*, p.name AS product_name
      FROM invoice_items ii
      LEFT JOIN products p ON p.id = ii.product_id
      WHERE ii.invoice_id = ?
    ''', [invoiceId]);
    return rows.map(InvoiceItem.fromMap).toList();
  }

  Future<Invoice> insert(Invoice invoice, List<InvoiceItem> items) async {
    final dbConn = await _db.database;
    late Invoice saved;

    await dbConn.transaction((txn) async {
      double ht = 0, tva = 0;
      for (final item in items) {
        ht += item.totalHt;
        tva += item.totalTva;
      }
      final ttc = ht + tva;

      final map = invoice.toMap()
        ..['total_ht'] = ht
        ..['total_tva'] = tva
        ..['total_ttc'] = ttc;

      final id = await txn.insert('invoices', map);
      for (final item in items) {
        await txn.insert(
            'invoice_items', item.toMap()..['invoice_id'] = id);
      }
      saved = invoice.copyWith(
          id: id, totalHt: ht, totalTva: tva, totalTtc: ttc);
    });
    return saved;
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('invoices', {'status': status}, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('invoices', id);
  }

  Future<int> nextSequence() async {
    final n = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM invoices', []);
    return (n ?? 0) + 1;
  }

  // ── Dashboard aggregates ───────────────────────────────────────────────────

  Future<double> totalRevenue() async {
    final v = await _db.rawQueryDouble(
        "SELECT COALESCE(SUM(total_ttc),0) FROM invoices WHERE status = 'Payée'",
        []);
    return v ?? 0;
  }

  Future<int> pendingCount() async {
    final n = await _db.rawQueryScalar(
        "SELECT COUNT(*) FROM invoices WHERE status IN ('Envoyée','En retard')",
        []);
    return n ?? 0;
  }

  Future<double> pendingAmount() async {
    final v = await _db.rawQueryDouble(
        "SELECT COALESCE(SUM(total_ttc),0) FROM invoices WHERE status IN ('Envoyée','En retard')",
        []);
    return v ?? 0;
  }

  Future<Map<String, int>> statusCounts() async {
    final rows = await _db.rawQuery(
        'SELECT status, COUNT(*) AS cnt FROM invoices GROUP BY status', []);
    return {for (final r in rows) r['status'] as String: (r['cnt'] as int)};
  }

  /// Revenue per month for the last N months (returns list of [month, amount])
  Future<List<Map<String, dynamic>>> revenueByMonth(int months) async {
    final rows = await _db.rawQuery('''
      SELECT
        strftime('%Y-%m', issued_date / 1000, 'unixepoch') AS month,
        COALESCE(SUM(total_ttc), 0) AS amount
      FROM invoices
      WHERE status = 'Payée'
        AND issued_date >= ?
      GROUP BY month
      ORDER BY month ASC
    ''', [
      DateTime.now()
          .subtract(Duration(days: months * 30))
          .millisecondsSinceEpoch
    ]);
    return rows
        .map((r) => {
              'month': r['month'] as String,
              'amount': (r['amount'] as num).toDouble(),
            })
        .toList();
  }
}
