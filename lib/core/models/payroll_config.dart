import 'dart:convert';

/// Moroccan payroll configuration: CNSS/AMO rates, plafond, and IGR brackets.
/// Stored as a single JSON blob under settings key [kSettings].
class PayrollConfig {
  // ── CNSS ────────────────────────────────────────────────────────────────────
  final double cnssEmployeeRate;  // 4.48 %
  final double cnssEmployerRate;  // 10.64 %
  final double cnssEmployeeApec; // 0.96 %
  final double cnssEmployerApec; // 3.96 %
  final double cnssPlafond;       // 6 000 DH/month ceiling

  // ── AMO ─────────────────────────────────────────────────────────────────────
  final double amoEmployeeRate;   // 2.26 %
  final double amoEmployerRate;   // 4.11 %

  // ── IGR (income tax) brackets ───────────────────────────────────────────────
  final List<IgrBracket> igrBrackets;

  static const kSettings = 'payroll_config';

  const PayrollConfig({
    required this.cnssEmployeeRate,
    required this.cnssEmployerRate,
    required this.cnssEmployeeApec,
    required this.cnssEmployerApec,
    required this.cnssPlafond,
    required this.amoEmployeeRate,
    required this.amoEmployerRate,
    required this.igrBrackets,
  });

  // ── Default Moroccan rates (2024) ────────────────────────────────────────────
  static PayrollConfig get defaults => PayrollConfig(
    cnssEmployeeRate:  0.0448,
    cnssEmployerRate:  0.1064,
    cnssEmployeeApec:  0.0096,
    cnssEmployerApec:  0.0396,
    cnssPlafond:       6000.0,
    amoEmployeeRate:   0.0226,
    amoEmployerRate:   0.0411,
    igrBrackets: const [
      IgrBracket(maxIncome: 30000,          rate: 0.00, baseAmount: 0),
      IgrBracket(maxIncome: 50000,          rate: 0.10, baseAmount: 0),
      IgrBracket(maxIncome: 60000,          rate: 0.20, baseAmount: 2000),
      IgrBracket(maxIncome: 80000,          rate: 0.30, baseAmount: 4000),
      IgrBracket(maxIncome: 180000,         rate: 0.34, baseAmount: 8000),
      IgrBracket(maxIncome: double.infinity, rate: 0.38, baseAmount: 42000),
    ],
  );

  // ── Serialization ────────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'cnssEmployeeRate': cnssEmployeeRate,
    'cnssEmployerRate': cnssEmployerRate,
    'cnssEmployeeApec': cnssEmployeeApec,
    'cnssEmployerApec': cnssEmployerApec,
    'cnssPlafond':      cnssPlafond,
    'amoEmployeeRate':  amoEmployeeRate,
    'amoEmployerRate':  amoEmployerRate,
    'igrBrackets': igrBrackets.map((b) => b.toMap()).toList(),
  };

  String toJson() => jsonEncode(toMap());

  factory PayrollConfig.fromJson(String json) {
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return PayrollConfig(
        cnssEmployeeRate:  (m['cnssEmployeeRate'] as num?)?.toDouble() ?? 0.0448,
        cnssEmployerRate:  (m['cnssEmployerRate'] as num?)?.toDouble() ?? 0.1064,
        cnssEmployeeApec:  (m['cnssEmployeeApec'] as num?)?.toDouble() ?? 0.0096,
        cnssEmployerApec:  (m['cnssEmployerApec'] as num?)?.toDouble() ?? 0.0396,
        cnssPlafond:       (m['cnssPlafond']      as num?)?.toDouble() ?? 6000.0,
        amoEmployeeRate:   (m['amoEmployeeRate']  as num?)?.toDouble() ?? 0.0226,
        amoEmployerRate:   (m['amoEmployerRate']  as num?)?.toDouble() ?? 0.0411,
        igrBrackets: (m['igrBrackets'] as List?)
            ?.map((e) => IgrBracket.fromMap(e as Map<String, dynamic>))
            .toList() ?? PayrollConfig.defaults.igrBrackets,
      );
    } catch (_) {
      return PayrollConfig.defaults;
    }
  }
}

/// A single IGR (Impôt Général sur le Revenu) bracket.
class IgrBracket {
  /// Annual income upper threshold (use double.infinity for the last bracket).
  final double maxIncome;
  /// Marginal rate for this bracket (e.g. 0.10 = 10%).
  final double rate;
  /// Accumulated tax already applied below this bracket.
  final double baseAmount;

  const IgrBracket({
    required this.maxIncome,
    required this.rate,
    required this.baseAmount,
  });

  Map<String, dynamic> toMap() => {
    'maxIncome':   maxIncome.isInfinite ? null : maxIncome,
    'rate':        rate,
    'baseAmount':  baseAmount,
  };

  factory IgrBracket.fromMap(Map<String, dynamic> m) => IgrBracket(
    maxIncome:  m['maxIncome'] == null
        ? double.infinity
        : (m['maxIncome'] as num).toDouble(),
    rate:       (m['rate']       as num).toDouble(),
    baseAmount: (m['baseAmount'] as num).toDouble(),
  );
}
