import 'package:intl/intl.dart';

/// Moroccan formatting utilities: currency (MAD), TVA, dates, phone
class MoroccoFormat {
  MoroccoFormat._();

  // ── Currency ──────────────────────────────────────────────────────────────

  static final _madFmt = NumberFormat('#,##0.00', 'fr_MA');

  /// Format a number as Moroccan Dirham: "1 234,50 DH"
  static String mad(double amount) => '${_madFmt.format(amount)} DH';

  /// Format without decimals: "1 235 DH"
  static String madInt(double amount) =>
      '${NumberFormat('#,##0', 'fr_MA').format(amount)} DH';

  // ── TVA ───────────────────────────────────────────────────────────────────

  /// Moroccan TVA rates
  static const List<double> tvaRates = [0, 7, 10, 14, 20];

  /// Standard TVA rate (default)
  static const double tvaStandard = 20.0;

  /// Calculate TTC from HT + TVA rate
  static double ttcFromHt(double ht, double tvaRate) =>
      ht * (1 + tvaRate / 100);

  /// Calculate HT from TTC + TVA rate
  static double htFromTtc(double ttc, double tvaRate) =>
      ttc / (1 + tvaRate / 100);

  /// Calculate TVA amount
  static double tvaAmount(double ht, double tvaRate) =>
      ht * (tvaRate / 100);

  /// Format TVA rate as "20%"
  static String tvaLabel(double rate) =>
      rate == 0 ? 'Exonéré' : '${rate.toStringAsFixed(0)}%';

  // ── Dates ─────────────────────────────────────────────────────────────────

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'fr_MA');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_MA');

  /// Format date as "05/04/2026"
  static String date(DateTime dt) => _dateFmt.format(dt);

  /// Format date from milliseconds epoch
  static String dateFromMs(int ms) =>
      _dateFmt.format(DateTime.fromMillisecondsSinceEpoch(ms));

  /// Format date+time
  static String dateTime(DateTime dt) => _dateTimeFmt.format(dt);

  /// Parse "dd/MM/yyyy" string to DateTime
  static DateTime? parseDate(String s) {
    try {
      return _dateFmt.parse(s);
    } catch (_) {
      return null;
    }
  }

  // ── Phone ─────────────────────────────────────────────────────────────────

  /// Format Moroccan phone: "0612345678" → "06 12 34 56 78"
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} '
          '${digits.substring(4, 6)} ${digits.substring(6, 8)} '
          '${digits.substring(8, 10)}';
    }
    return raw;
  }

  // ── Moroccan cities ───────────────────────────────────────────────────────

  static const List<String> cities = [
    'Casablanca',
    'Rabat',
    'Marrakech',
    'Fès',
    'Tanger',
    'Agadir',
    'Meknès',
    'Oujda',
    'Kénitra',
    'Tétouan',
    'Salé',
    'Mohammedia',
    'El Jadida',
    'Beni Mellal',
    'Nador',
    'Settat',
    'Berrechid',
    'Khouribga',
    'Taza',
    'Safi',
    'Autre',
  ];

  // ── Numbering sequences ───────────────────────────────────────────────────

  /// Generate invoice reference: "FAC-2026-001"
  static String invoiceRef(int sequence) {
    final year = DateTime.now().year;
    return 'FAC-$year-${sequence.toString().padLeft(3, '0')}';
  }

  /// Generate order reference: "BC-2026-001"
  static String orderRef(int sequence) {
    final year = DateTime.now().year;
    return 'BC-$year-${sequence.toString().padLeft(3, '0')}';
  }

  // ── Status labels (French) ────────────────────────────────────────────────

  static const invoiceStatuses = [
    'Brouillon',
    'Envoyée',
    'Payée',
    'En retard',
  ];

  static const orderStatuses = [
    'En attente',
    'En cours',
    'Terminée',
    'Annulée',
  ];

  static const companyStatuses = ['Active', 'Inactive'];
}
