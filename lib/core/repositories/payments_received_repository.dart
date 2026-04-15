import '../database/database_helper.dart';
import '../models/payment.dart';

class PaymentsReceivedRepository {
  final _db = DatabaseHelper.instance;

  Future<List<PaymentReceived>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT pr.*,
             inv.reference AS invoice_ref,
             c.name        AS client_name
      FROM payments_received pr
      JOIN invoices inv ON inv.id = pr.invoice_id
      JOIN clients c    ON c.id  = inv.client_id
      ORDER BY pr.payment_date DESC
    ''', []);
    return rows.map(PaymentReceived.fromMap).toList();
  }

  Future<List<PaymentReceived>> getByInvoiceId(int invoiceId) async {
    final rows = await _db.rawQuery('''
      SELECT pr.*,
             inv.reference AS invoice_ref,
             c.name        AS client_name
      FROM payments_received pr
      JOIN invoices inv ON inv.id = pr.invoice_id
      JOIN clients c    ON c.id  = inv.client_id
      WHERE pr.invoice_id = ?
      ORDER BY pr.payment_date DESC
    ''', [invoiceId]);
    return rows.map(PaymentReceived.fromMap).toList();
  }

  Future<double> totalByInvoiceId(int invoiceId) async {
    final v = await _db.rawQueryDouble(
      'SELECT COALESCE(SUM(amount),0) FROM payments_received WHERE invoice_id = ?',
      [invoiceId],
    );
    return v ?? 0;
  }

  Future<PaymentReceived> insert(PaymentReceived payment) async {
    final id = await _db.insert('payments_received', payment.toMap());
    return payment.copyWith(id: id);
  }

  Future<void> delete(int id) async {
    await _db.delete('payments_received', id);
  }

  /// Total collected for a given period (for dashboard / reports)
  Future<double> totalCollected({DateTime? from, DateTime? to}) async {
    final fromMs = (from ?? DateTime(2000)).millisecondsSinceEpoch;
    final toMs = (to ?? DateTime(2100)).millisecondsSinceEpoch;
    final v = await _db.rawQueryDouble(
      'SELECT COALESCE(SUM(amount),0) FROM payments_received '
      'WHERE payment_date BETWEEN ? AND ?',
      [fromMs, toMs],
    );
    return v ?? 0;
  }
}
