import '../database/database_helper.dart';

/// Central reporting queries — all monetary values in MAD.
class ReportRepository {
  final _db = DatabaseHelper.instance;

  // ── Revenue ────────────────────────────────────────────────────────────────

  /// Monthly revenue (paid invoices) for the last [months] months.
  Future<List<Map<String, dynamic>>> revenueByMonth(int months) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: months * 30))
        .millisecondsSinceEpoch;
    return _db.rawQuery('''
      SELECT
        strftime('%Y-%m', datetime(issued_date/1000,'unixepoch')) AS month,
        SUM(total_ht)  AS ht,
        SUM(total_tva) AS tva,
        SUM(total_ttc) AS ttc
      FROM invoices
      WHERE status = 'Payée' AND issued_date >= ?
      GROUP BY month
      ORDER BY month ASC
    ''', [cutoff]);
  }

  /// Revenue by client (all paid invoices).
  Future<List<Map<String, dynamic>>> revenueByClient({int limit = 10}) async {
    return _db.rawQuery('''
      SELECT c.name AS client_name,
             COUNT(i.id) AS invoice_count,
             SUM(i.total_ht)  AS total_ht,
             SUM(i.total_ttc) AS total_ttc
      FROM invoices i
      JOIN clients c ON i.client_id = c.id
      WHERE i.status = 'Payée'
      GROUP BY c.id
      ORDER BY total_ttc DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Revenue by product/service (from invoice items).
  Future<List<Map<String, dynamic>>> revenueByProduct({int limit = 10}) async {
    return _db.rawQuery('''
      SELECT ii.description,
             SUM(ii.quantity) AS total_qty,
             SUM(ii.quantity * ii.unit_price_ht) AS total_ht
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.status = 'Payée'
      GROUP BY ii.description
      ORDER BY total_ht DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Invoice status breakdown.
  Future<Map<String, dynamic>> invoiceSummary() async {
    final rows = await _db.rawQuery('''
      SELECT
        status,
        COUNT(*) AS cnt,
        SUM(total_ttc) AS amount
      FROM invoices
      GROUP BY status
    ''', []);
    final result = <String, dynamic>{};
    for (final r in rows) {
      result[r['status'] as String] = {
        'count': r['cnt'],
        'amount': r['amount'],
      };
    }
    return result;
  }

  // ── TVA ────────────────────────────────────────────────────────────────────

  /// TVA collectée (from paid invoices) and récupérable (from purchase orders received).
  Future<Map<String, dynamic>> tvaReport(int year, int month) async {
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1).millisecondsSinceEpoch;

    final collectee = await _db.rawQuery('''
      SELECT tva_rate, SUM(quantity * unit_price_ht * tva_rate / 100) AS tva_amount
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.status IN ('Payée','Envoyée')
        AND i.issued_date >= ? AND i.issued_date < ?
      GROUP BY tva_rate
    ''', [start, end]);

    final recuperable = await _db.rawQuery('''
      SELECT poi.tva_rate,
             SUM(poi.quantity * poi.unit_price_ht * poi.tva_rate / 100) AS tva_amount
      FROM purchase_order_items poi
      JOIN purchase_orders po ON poi.order_id = po.id
      WHERE po.status IN ('Reçu','Partiel')
        AND po.date >= ? AND po.date < ?
      GROUP BY poi.tva_rate
    ''', [start, end]);

    double totalCollectee = 0;
    double totalRecuperable = 0;
    for (final r in collectee) {
      totalCollectee += (r['tva_amount'] as num?)?.toDouble() ?? 0;
    }
    for (final r in recuperable) {
      totalRecuperable += (r['tva_amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'collectee': collectee,
      'recuperable': recuperable,
      'total_collectee': totalCollectee,
      'total_recuperable': totalRecuperable,
      'tva_nette': totalCollectee - totalRecuperable,
    };
  }

  // ── Purchases ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> purchasesBySupplier({int limit = 10}) async {
    return _db.rawQuery('''
      SELECT s.name AS supplier_name,
             COUNT(po.id) AS order_count,
             SUM(po.total_ht)  AS total_ht,
             SUM(po.total_ttc) AS total_ttc
      FROM purchase_orders po
      JOIN suppliers s ON po.supplier_id = s.id
      WHERE po.status != 'Annulé'
      GROUP BY s.id
      ORDER BY total_ttc DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> purchasesByMonth(int months) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: months * 30))
        .millisecondsSinceEpoch;
    return _db.rawQuery('''
      SELECT strftime('%Y-%m', datetime(date/1000,'unixepoch')) AS month,
             SUM(total_ht)  AS ht,
             SUM(total_ttc) AS ttc
      FROM purchase_orders
      WHERE status != 'Annulé' AND date >= ?
      GROUP BY month
      ORDER BY month ASC
    ''', [cutoff]);
  }

  // ── Payroll ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> payrollByMonth(int year) async {
    return _db.rawQuery('''
      SELECT period_year, period_month,
             SUM(salary_brut)   AS total_brut,
             SUM(salary_net)    AS total_net,
             SUM(cnss_employer + amo_employer) AS total_employer_charges,
             COUNT(*)           AS employee_count
      FROM payroll_slips
      WHERE period_year = ?
      GROUP BY period_year, period_month
      ORDER BY period_month ASC
    ''', [year]);
  }

  // ── IS (Impôt sur les Sociétés) ─────────────────────────────────────────

  Future<Map<String, dynamic>> isReport(int year) async {
    final start = DateTime(year).millisecondsSinceEpoch;
    final end = DateTime(year + 1).millisecondsSinceEpoch;

    final revenueRows = await _db.rawQuery('''
      SELECT SUM(total_ht) AS total FROM invoices
      WHERE status IN ('Payée','Envoyée') AND issued_date >= ? AND issued_date < ?
    ''', [start, end]);

    final purchaseRows = await _db.rawQuery('''
      SELECT SUM(total_ht) AS total FROM purchase_orders
      WHERE status IN ('Reçu','Partiel') AND date >= ? AND date < ?
    ''', [start, end]);

    final payrollRows = await _db.rawQuery('''
      SELECT SUM(salary_brut + cnss_employer + amo_employer) AS total
      FROM payroll_slips WHERE period_year = ?
    ''', [year]);

    final revenue = (revenueRows.first['total'] as num?)?.toDouble() ?? 0;
    final purchases = (purchaseRows.first['total'] as num?)?.toDouble() ?? 0;
    final payroll = (payrollRows.first['total'] as num?)?.toDouble() ?? 0;
    final resultFiscal = revenue - purchases - payroll;

    double is_amount = _calculateIs(resultFiscal);

    return {
      'year': year,
      'chiffre_affaires': revenue,
      'achats': purchases,
      'charges_personnel': payroll,
      'resultat_fiscal': resultFiscal,
      'is_amount': is_amount,
      'is_rate': resultFiscal > 0 ? (is_amount / resultFiscal * 100) : 0,
    };
  }

  static double _calculateIs(double profit) {
    if (profit <= 0) return 0;
    // Moroccan IS 2024 rates
    if (profit <= 300000) return profit * 0.10;
    if (profit <= 1000000) return 30000 + (profit - 300000) * 0.20;
    return 30000 + 140000 + (profit - 1000000) * 0.31;
  }

  // ── POS summary ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> posSummary({int? year, int? month}) async {
    final conds = <String>['1=1'];
    final args = <Object?>[];
    if (year != null && month != null) {
      final start = DateTime(year, month).millisecondsSinceEpoch;
      final end = DateTime(year, month + 1).millisecondsSinceEpoch;
      conds.add('sale_date >= ? AND sale_date < ?');
      args.addAll([start, end]);
    }
    final where = conds.join(' AND ');
    final rows = await _db.rawQuery('''
      SELECT COUNT(*) AS count, SUM(total_ttc) AS total, SUM(total_ht) AS ht,
             SUM(total_tva) AS tva
      FROM pos_sales WHERE $where
    ''', args);
    return rows.first;
  }
}
