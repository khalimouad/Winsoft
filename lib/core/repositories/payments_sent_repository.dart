import '../database/database_helper.dart';
import '../models/payment.dart';

class PaymentsSentRepository {
  final _db = DatabaseHelper.instance;

  Future<List<PaymentSent>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT ps.*,
             si.reference AS supplier_invoice_ref,
             s.name       AS supplier_name
      FROM payments_sent ps
      JOIN supplier_invoices si ON si.id = ps.supplier_invoice_id
      JOIN suppliers s          ON s.id  = si.supplier_id
      ORDER BY ps.payment_date DESC
    ''', []);
    return rows.map(PaymentSent.fromMap).toList();
  }

  Future<List<PaymentSent>> getBySupplierInvoiceId(int supplierInvoiceId) async {
    final rows = await _db.rawQuery('''
      SELECT ps.*,
             si.reference AS supplier_invoice_ref,
             s.name       AS supplier_name
      FROM payments_sent ps
      JOIN supplier_invoices si ON si.id = ps.supplier_invoice_id
      JOIN suppliers s          ON s.id  = si.supplier_id
      WHERE ps.supplier_invoice_id = ?
      ORDER BY ps.payment_date DESC
    ''', [supplierInvoiceId]);
    return rows.map(PaymentSent.fromMap).toList();
  }

  Future<double> totalBySupplierInvoiceId(int supplierInvoiceId) async {
    final v = await _db.rawQueryDouble(
      'SELECT COALESCE(SUM(amount),0) FROM payments_sent '
      'WHERE supplier_invoice_id = ?',
      [supplierInvoiceId],
    );
    return v ?? 0;
  }

  Future<PaymentSent> insert(PaymentSent payment) async {
    final id = await _db.insert('payments_sent', payment.toMap());
    return payment.copyWith(id: id);
  }

  Future<void> delete(int id) async {
    await _db.delete('payments_sent', id);
  }

  /// Total paid to suppliers for a given period
  Future<double> totalPaid({DateTime? from, DateTime? to}) async {
    final fromMs = (from ?? DateTime(2000)).millisecondsSinceEpoch;
    final toMs = (to ?? DateTime(2100)).millisecondsSinceEpoch;
    final v = await _db.rawQueryDouble(
      'SELECT COALESCE(SUM(amount),0) FROM payments_sent '
      'WHERE payment_date BETWEEN ? AND ?',
      [fromMs, toMs],
    );
    return v ?? 0;
  }
}
