class AccountChart {
  const AccountChart({
    this.id,
    required this.code,
    required this.label,
    required this.classNum,
    this.type = 'bilan',
    this.isActive = true,
  });

  final int? id;
  final String code;
  final String label;
  final int classNum;
  /// 'bilan' | 'gestion'
  final String type;
  final bool isActive;

  String get className {
    switch (classNum) {
      case 1: return 'Comptes de financement permanent';
      case 2: return 'Comptes d\'actif immobilisé';
      case 3: return 'Comptes d\'actif circulant';
      case 4: return 'Comptes de passif circulant';
      case 5: return 'Comptes de trésorerie';
      case 6: return 'Comptes de charges';
      case 7: return 'Comptes de produits';
      default: return 'Classe $classNum';
    }
  }

  factory AccountChart.fromMap(Map<String, dynamic> m) => AccountChart(
        id: m['id'] as int?,
        code: m['code'] as String,
        label: m['label'] as String,
        classNum: m['class_num'] as int,
        type: m['type'] as String? ?? 'bilan',
        isActive: (m['is_active'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'code': code,
        'label': label,
        'class_num': classNum,
        'type': type,
        'is_active': isActive ? 1 : 0,
      };
}

class JournalEntryLine {
  const JournalEntryLine({
    this.id,
    required this.entryId,
    required this.accountId,
    this.label,
    this.debit = 0,
    this.credit = 0,
    this.accountCode,
    this.accountLabel,
  });

  final int? id;
  final int entryId;
  final int accountId;
  final String? label;
  final double debit;
  final double credit;
  // Joined
  final String? accountCode;
  final String? accountLabel;

  factory JournalEntryLine.fromMap(Map<String, dynamic> m) => JournalEntryLine(
        id: m['id'] as int?,
        entryId: m['entry_id'] as int,
        accountId: m['account_id'] as int,
        label: m['label'] as String?,
        debit: (m['debit'] as num?)?.toDouble() ?? 0,
        credit: (m['credit'] as num?)?.toDouble() ?? 0,
        accountCode: m['account_code'] as String?,
        accountLabel: m['account_label'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'entry_id': entryId,
        'account_id': accountId,
        'label': label,
        'debit': debit,
        'credit': credit,
      };
}

class JournalEntry {
  const JournalEntry({
    this.id,
    required this.reference,
    required this.date,
    this.description,
    this.journal = 'OD',
    this.isValidated = false,
    required this.createdAt,
    this.lines = const [],
  });

  final int? id;
  final String reference;
  final int date;
  final String? description;
  /// 'OD' | 'VTE' | 'ACH' | 'TRE' | 'SAL'
  final String journal;
  final bool isValidated;
  final int createdAt;
  final List<JournalEntryLine> lines;

  double get totalDebit =>
      lines.fold(0, (s, l) => s + l.debit);
  double get totalCredit =>
      lines.fold(0, (s, l) => s + l.credit);
  bool get isBalanced =>
      (totalDebit - totalCredit).abs() < 0.01;

  factory JournalEntry.fromMap(Map<String, dynamic> m,
          {List<JournalEntryLine> lines = const []}) =>
      JournalEntry(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        date: m['date'] as int,
        description: m['description'] as String?,
        journal: m['journal'] as String? ?? 'OD',
        isValidated: (m['is_validated'] as int?) == 1,
        createdAt: m['created_at'] as int,
        lines: lines,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'date': date,
        'description': description,
        'journal': journal,
        'is_validated': isValidated ? 1 : 0,
        'created_at': createdAt,
      };
}
