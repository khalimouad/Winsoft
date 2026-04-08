import '../database/database_helper.dart';
import '../models/journal_entry.dart';

class AccountingRepository {
  final _db = DatabaseHelper.instance;

  // ── Chart of accounts ──────────────────────────────────────────────────────

  Future<List<AccountChart>> getAccounts({int? classNum}) async {
    if (classNum != null) {
      final rows = await _db.query('account_chart',
          where: 'class_num = ? AND is_active = 1',
          whereArgs: [classNum],
          orderBy: 'code ASC');
      return rows.map(AccountChart.fromMap).toList();
    }
    final rows =
        await _db.query('account_chart', orderBy: 'code ASC');
    return rows.map(AccountChart.fromMap).toList();
  }

  Future<int> insertAccount(AccountChart a) async =>
      _db.insert('account_chart', a.toMap());

  Future<void> seedPcm() async {
    final existing = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM account_chart', []);
    if ((existing ?? 0) > 0) return;
    final accounts = _pcmSeedAccounts();
    final db = await _db.database;
    final batch = db.batch();
    for (final a in accounts) {
      batch.insert('account_chart', a.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ── Journal entries ────────────────────────────────────────────────────────

  Future<List<JournalEntry>> getEntries({String? journal, int? year}) async {
    final conds = <String>[];
    final args = <Object?>[];
    if (journal != null) {
      conds.add('je.journal = ?');
      args.add(journal);
    }
    if (year != null) {
      final start = DateTime(year).millisecondsSinceEpoch;
      final end = DateTime(year + 1).millisecondsSinceEpoch;
      conds.add('je.date >= ? AND je.date < ?');
      args.addAll([start, end]);
    }
    final where = conds.isEmpty ? '' : 'WHERE ${conds.join(' AND ')}';
    final rows = await _db.rawQuery('''
      SELECT * FROM journal_entries $where
      ORDER BY date DESC
    ''', args);
    return rows.map((r) => JournalEntry.fromMap(r)).toList();
  }

  Future<JournalEntry?> getEntryById(int id) async {
    final rows = await _db.query('journal_entries',
        where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final lineRows = await _db.rawQuery('''
      SELECT jl.*, ac.code AS account_code, ac.label AS account_label
      FROM journal_entry_lines jl
      JOIN account_chart ac ON jl.account_id = ac.id
      WHERE jl.entry_id = ?
    ''', [id]);
    return JournalEntry.fromMap(rows.first,
        lines: lineRows.map(JournalEntryLine.fromMap).toList());
  }

  Future<int> insertEntry(JournalEntry entry) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = entry.toMap();
      map['created_at'] = now;
      map.remove('id');
      final id = await txn.insert('journal_entries', map);
      for (final line in entry.lines) {
        final lm = line.toMap();
        lm['entry_id'] = id;
        lm.remove('id');
        await txn.insert('journal_entry_lines', lm);
      }
      return id;
    });
  }

  Future<void> validateEntry(int id) async {
    final db = await _db.database;
    await db.update('journal_entries', {'is_validated': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async => _db.delete('journal_entries', id);

  Future<int> nextSequence() async {
    final val = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM journal_entries', []);
    return (val ?? 0) + 1;
  }

  /// Grand Livre: balance per account for a year
  Future<List<Map<String, dynamic>>> grandLivre(int year) async {
    final start = DateTime(year).millisecondsSinceEpoch;
    final end = DateTime(year + 1).millisecondsSinceEpoch;
    return _db.rawQuery('''
      SELECT ac.code, ac.label, ac.class_num,
             SUM(jl.debit)  AS total_debit,
             SUM(jl.credit) AS total_credit,
             SUM(jl.debit) - SUM(jl.credit) AS solde
      FROM journal_entry_lines jl
      JOIN account_chart ac  ON jl.account_id = ac.id
      JOIN journal_entries je ON jl.entry_id = je.id
      WHERE je.date >= ? AND je.date < ?
      GROUP BY ac.id
      ORDER BY ac.code ASC
    ''', [start, end]);
  }

  // ── PCM seed ───────────────────────────────────────────────────────────────

  static List<AccountChart> _pcmSeedAccounts() => [
    // Classe 1
    const AccountChart(code: '1111', label: 'Capital social', classNum: 1, type: 'bilan'),
    const AccountChart(code: '1191', label: 'Résultat de l\'exercice', classNum: 1, type: 'bilan'),
    const AccountChart(code: '1411', label: 'Emprunts auprès des établissements de crédit', classNum: 1, type: 'bilan'),
    // Classe 2
    const AccountChart(code: '2221', label: 'Fonds commercial', classNum: 2, type: 'bilan'),
    const AccountChart(code: '2332', label: 'Matériel de transport', classNum: 2, type: 'bilan'),
    const AccountChart(code: '2355', label: 'Matériel informatique', classNum: 2, type: 'bilan'),
    const AccountChart(code: '2421', label: 'Mobilier et matériel de bureau', classNum: 2, type: 'bilan'),
    // Classe 3
    const AccountChart(code: '3111', label: 'Marchandises', classNum: 3, type: 'bilan'),
    const AccountChart(code: '3121', label: 'Matières premières', classNum: 3, type: 'bilan'),
    const AccountChart(code: '3131', label: 'Produits en cours', classNum: 3, type: 'bilan'),
    const AccountChart(code: '3141', label: 'Produits finis', classNum: 3, type: 'bilan'),
    const AccountChart(code: '3421', label: 'Clients et comptes rattachés', classNum: 3, type: 'bilan'),
    const AccountChart(code: '3455', label: 'TVA récupérable sur charges', classNum: 3, type: 'bilan'),
    const AccountChart(code: '3456', label: 'TVA récupérable sur immobilisations', classNum: 3, type: 'bilan'),
    // Classe 4
    const AccountChart(code: '4411', label: 'Fournisseurs', classNum: 4, type: 'bilan'),
    const AccountChart(code: '4432', label: 'Rémunérations dues au personnel', classNum: 4, type: 'bilan'),
    const AccountChart(code: '4441', label: 'État — TVA facturée', classNum: 4, type: 'bilan'),
    const AccountChart(code: '4443', label: 'État — TVA due', classNum: 4, type: 'bilan'),
    const AccountChart(code: '4455', label: 'Organismes sociaux', classNum: 4, type: 'bilan'),
    // Classe 5
    const AccountChart(code: '5141', label: 'Banques', classNum: 5, type: 'bilan'),
    const AccountChart(code: '5161', label: 'Caisse', classNum: 5, type: 'bilan'),
    // Classe 6
    const AccountChart(code: '6111', label: 'Achats de marchandises', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6121', label: 'Achats de matières premières', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6131', label: 'Achats de matières et fournitures consommables', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6141', label: 'Achats de travaux, études et prestations', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6161', label: 'Achats non stockés de matières et fournitures', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6171', label: 'Achats d\'emballages', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6211', label: 'Locations et charges locatives', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6232', label: 'Publicité, publications et relations publiques', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6241', label: 'Transports', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6271', label: 'Frais de téléphone et télécommunications', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6311', label: 'Impôts, taxes et versements assimilés', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6321', label: 'Rémunérations du personnel', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6322', label: 'Charges sociales', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6611', label: 'Charges d\'intérêts', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6711', label: 'Valeurs nettes d\'amortissements des immobilisations cédées', classNum: 6, type: 'gestion'),
    const AccountChart(code: '6721', label: 'Pénalités sur marchés', classNum: 6, type: 'gestion'),
    // Classe 7
    const AccountChart(code: '7111', label: 'Ventes de marchandises en l\'état', classNum: 7, type: 'gestion'),
    const AccountChart(code: '7121', label: 'Ventes de biens produits', classNum: 7, type: 'gestion'),
    const AccountChart(code: '7131', label: 'Variation de stocks de produits finis', classNum: 7, type: 'gestion'),
    const AccountChart(code: '7141', label: 'Ventes de travaux et prestations de services', classNum: 7, type: 'gestion'),
    const AccountChart(code: '7161', label: 'Produits des activités annexes', classNum: 7, type: 'gestion'),
    const AccountChart(code: '7311', label: 'Intérêts et produits assimilés', classNum: 7, type: 'gestion'),
    const AccountChart(code: '7711', label: 'Produits des cessions d\'immobilisations', classNum: 7, type: 'gestion'),
    const AccountChart(code: '7721', label: 'Subventions d\'équilibre reçues', classNum: 7, type: 'gestion'),
  ];
}
