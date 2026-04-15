import '../database/database_helper.dart';
import 'journal_entry.dart';

/// Per-country accounting standard configuration.
/// Holds the account codes used by AccountingIntegration and the
/// full chart of accounts seed for that standard.
class AccountingCountry {
  const AccountingCountry({
    required this.code,
    required this.name,
    required this.standard,
    required this.flag,
    required this.requiredPlan,
    required this.accounts,
    required this.seedAccounts,
  });

  /// ISO 3166-1 alpha-2 or 'IFRS'
  final String code;
  final String name;
  final String standard;
  final String flag;

  /// Minimum subscription plan required: 'starter' | 'pro' | 'enterprise'
  final String requiredPlan;

  /// Named account codes used in automatic posting.
  final _AccountCodes accounts;

  /// Full chart of accounts seed for this standard.
  final List<AccountChart> seedAccounts;

  // ── Settings key ────────────────────────────────────────────────────────────

  static const kSettingKey = 'accounting_country';

  static AccountingCountry get defaultCountry => _all['MA']!;

  static List<AccountingCountry> get all => _all.values.toList();

  static AccountingCountry forCode(String? code) =>
      _all[code] ?? defaultCountry;

  static Future<AccountingCountry> fromSettings() async {
    final settings = await DatabaseHelper.instance.getAllSettings();
    return forCode(settings[kSettingKey]);
  }

  // ── Registry ────────────────────────────────────────────────────────────────

  static final Map<String, AccountingCountry> _all = {
    'MA': _morocco,
    'FR': _france,
    'DZ': _algeria,
    'TN': _tunisia,
    'SN': _syscohada,
    'IFRS': _ifrs,
  };
}

// ── Account codes carrier ─────────────────────────────────────────────────────

class _AccountCodes {
  const _AccountCodes({
    required this.client,
    required this.sales,
    required this.vatCollected,
    required this.supplier,
    required this.purchases,
    required this.vatDeductible,
    required this.cash,
    required this.bank,
    required this.wages,
    required this.employerCharges,
    required this.wagesDue,
    required this.socialOrgs,
    required this.incomeTax,
  });

  final String client;
  final String sales;
  final String vatCollected;
  final String supplier;
  final String purchases;
  final String vatDeductible;
  final String cash;
  final String bank;
  final String wages;
  final String employerCharges;
  final String wagesDue;
  final String socialOrgs;
  final String incomeTax;
}

// ── Morocco — PCM (Plan Comptable Marocain) ──────────────────────────────────

const _morocco = AccountingCountry(
  code: 'MA',
  name: 'Maroc',
  standard: 'PCM',
  flag: '🇲🇦',
  requiredPlan: 'starter',
  accounts: _AccountCodes(
    client: '3421', sales: '7141', vatCollected: '4441',
    supplier: '4411', purchases: '6121', vatDeductible: '3455',
    cash: '5161', bank: '5141',
    wages: '6321', employerCharges: '6322',
    wagesDue: '4432', socialOrgs: '4455', incomeTax: '4443',
  ),
  seedAccounts: [
    AccountChart(code: '1111', label: 'Capital social', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1191', label: 'Résultat de l\'exercice', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1411', label: 'Emprunts auprès des établissements de crédit', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '2221', label: 'Fonds commercial', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2332', label: 'Matériel de transport', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2355', label: 'Matériel informatique', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2421', label: 'Mobilier et matériel de bureau', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '3111', label: 'Marchandises', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3121', label: 'Matières premières', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3131', label: 'Produits en cours', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3141', label: 'Produits finis', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3421', label: 'Clients et comptes rattachés', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3455', label: 'TVA récupérable sur charges', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3456', label: 'TVA récupérable sur immobilisations', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '4411', label: 'Fournisseurs', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4432', label: 'Rémunérations dues au personnel', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4441', label: 'État — TVA facturée', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4443', label: 'État — IGR (impôt sur revenu)', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4455', label: 'Organismes sociaux (CNSS, AMO)', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '5141', label: 'Banques', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '5161', label: 'Caisse', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '6111', label: 'Achats de marchandises', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6121', label: 'Achats de matières premières', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6141', label: 'Achats de travaux, études et prestations', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6211', label: 'Locations et charges locatives', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6232', label: 'Publicité, publications et relations publiques', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6241', label: 'Transports', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6271', label: 'Frais de téléphone et télécommunications', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6311', label: 'Impôts, taxes et versements assimilés', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6321', label: 'Rémunérations du personnel', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6322', label: 'Charges sociales patronales', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '6611', label: 'Charges d\'intérêts', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '7111', label: 'Ventes de marchandises', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '7121', label: 'Ventes de biens produits', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '7141', label: 'Ventes de travaux et prestations de services', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '7161', label: 'Produits des activités annexes', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '7311', label: 'Intérêts et produits assimilés', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '7711', label: 'Produits des cessions d\'immobilisations', classNum: 7, type: 'gestion', isActive: true),
  ],
);

// ── France — PCG (Plan Comptable Général) ─────────────────────────────────────

const _france = AccountingCountry(
  code: 'FR',
  name: 'France',
  standard: 'PCG',
  flag: '🇫🇷',
  requiredPlan: 'pro',
  accounts: _AccountCodes(
    client: '411000', sales: '707000', vatCollected: '445710',
    supplier: '401000', purchases: '607000', vatDeductible: '445660',
    cash: '530000', bank: '512000',
    wages: '641000', employerCharges: '645000',
    wagesDue: '421000', socialOrgs: '431000', incomeTax: '444000',
  ),
  seedAccounts: [
    AccountChart(code: '101000', label: 'Capital social', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '110000', label: 'Report à nouveau', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '120000', label: 'Résultat de l\'exercice', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '164000', label: 'Emprunts auprès des établissements de crédit', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '207000', label: 'Fonds commercial', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '213000', label: 'Constructions', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '215400', label: 'Matériel de transport', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '218300', label: 'Matériel de bureau', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '218400', label: 'Matériel informatique', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '300000', label: 'Stocks de matières premières', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '350000', label: 'Stocks de produits finis', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '371000', label: 'Stocks de marchandises', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '401000', label: 'Fournisseurs et comptes rattachés', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '404000', label: 'Fournisseurs d\'immobilisations', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '411000', label: 'Clients et comptes rattachés', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '421000', label: 'Personnel — Rémunérations dues', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '431000', label: 'Sécurité sociale et mutuelles', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '444000', label: 'État — Impôts sur bénéfices', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '445660', label: 'TVA déductible sur autres biens', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '445710', label: 'TVA collectée', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '512000', label: 'Banques', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '530000', label: 'Caisse', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '601000', label: 'Achats de matières premières', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '606000', label: 'Achats non stockés de matières', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '607000', label: 'Achats de marchandises', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '611000', label: 'Locations et charges locatives', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '623000', label: 'Publicité, publications', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '625000', label: 'Déplacements, missions et réceptions', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '626000', label: 'Frais postaux et télécommunications', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '635000', label: 'Autres impôts, taxes et versements assimilés', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '641000', label: 'Rémunérations du personnel', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '645000', label: 'Charges de sécurité sociale et prévoyance', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '661000', label: 'Charges d\'intérêts', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '701000', label: 'Ventes de produits finis', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '706000', label: 'Prestations de services', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '707000', label: 'Ventes de marchandises', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '708000', label: 'Produits des activités annexes', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '761000', label: 'Produits de participations', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '771000', label: 'Produits exceptionnels sur cessions', classNum: 7, type: 'gestion', isActive: true),
  ],
);

// ── Algeria — SCF (Système Comptable Financier) ───────────────────────────────

const _algeria = AccountingCountry(
  code: 'DZ',
  name: 'Algérie',
  standard: 'SCF',
  flag: '🇩🇿',
  requiredPlan: 'pro',
  accounts: _AccountCodes(
    client: '411', sales: '700', vatCollected: '4457',
    supplier: '401', purchases: '601', vatDeductible: '4456',
    cash: '530', bank: '512',
    wages: '641', employerCharges: '645',
    wagesDue: '421', socialOrgs: '431', incomeTax: '444',
  ),
  seedAccounts: [
    AccountChart(code: '101', label: 'Capital social', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '106', label: 'Réserves', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '164', label: 'Emprunts auprès des établissements financiers', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '203', label: 'Immobilisations incorporelles', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '213', label: 'Terrains', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '215', label: 'Installations techniques, matériel et outillage', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '218', label: 'Matériel de transport', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '300', label: 'Matières premières', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '355', label: 'Produits finis', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '380', label: 'Marchandises', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '401', label: 'Fournisseurs et comptes rattachés', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '411', label: 'Clients et comptes rattachés', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '421', label: 'Personnel — Rémunérations dues', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '431', label: 'Sécurité sociale', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '444', label: 'État — Impôts sur les bénéfices', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4456', label: 'TVA à récupérer', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4457', label: 'TVA collectée', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '512', label: 'Banques', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '530', label: 'Caisse', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '601', label: 'Achats de matières premières', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '607', label: 'Achats de marchandises', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '613', label: 'Locations et charges locatives', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '623', label: 'Publicité et communication', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '625', label: 'Frais de déplacement et de transport', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '635', label: 'Impôts et taxes divers', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '641', label: 'Rémunérations du personnel', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '645', label: 'Charges de sécurité sociale', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '661', label: 'Charges d\'intérêts', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '700', label: 'Ventes de produits fabriqués', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '706', label: 'Prestations de services', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '707', label: 'Ventes de marchandises', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '750', label: 'Subventions d\'exploitation', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '762', label: 'Produits des créances', classNum: 7, type: 'gestion', isActive: true),
  ],
);

// ── Tunisia — PCG Tunisien ────────────────────────────────────────────────────

const _tunisia = AccountingCountry(
  code: 'TN',
  name: 'Tunisie',
  standard: 'PCG-TN',
  flag: '🇹🇳',
  requiredPlan: 'pro',
  accounts: _AccountCodes(
    client: '411', sales: '706', vatCollected: '4378',
    supplier: '401', purchases: '601', vatDeductible: '4365',
    cash: '531', bank: '532',
    wages: '621', employerCharges: '635',
    wagesDue: '421', socialOrgs: '431', incomeTax: '444',
  ),
  seedAccounts: [
    AccountChart(code: '101', label: 'Capital social', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '115', label: 'Réserves', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '131', label: 'Résultat de l\'exercice', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '224', label: 'Emprunts et dettes auprès des établissements bancaires', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '211', label: 'Immobilisations incorporelles', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '221', label: 'Terrains', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '241', label: 'Matériel de transport', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '243', label: 'Matériel et mobilier de bureau', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '311', label: 'Matières premières', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '321', label: 'Produits finis', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '371', label: 'Marchandises', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '401', label: 'Fournisseurs', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '411', label: 'Clients et comptes rattachés', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '421', label: 'Personnel — Rémunérations dues', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '431', label: 'Organismes sociaux', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '444', label: 'État — Impôts sur bénéfices', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4365', label: 'TVA récupérable', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4378', label: 'TVA collectée', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '531', label: 'Caisse en dinars', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '532', label: 'Banques et établissements financiers', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '601', label: 'Achats de matières premières et approvisionnements', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '606', label: 'Achats de marchandises', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '612', label: 'Locations', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '618', label: 'Divers', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '621', label: 'Rémunérations du personnel', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '635', label: 'Cotisations et charges sociales', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '652', label: 'Charges financières', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '706', label: 'Ventes de travaux et prestations de services', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '707', label: 'Ventes de marchandises', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '712', label: 'Ventes de biens produits', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '752', label: 'Produits financiers', classNum: 7, type: 'gestion', isActive: true),
  ],
);

// ── West & Central Africa — SYSCOHADA ─────────────────────────────────────────

const _syscohada = AccountingCountry(
  code: 'SN',
  name: 'Afrique OHADA',
  standard: 'SYSCOHADA',
  flag: '🌍',
  requiredPlan: 'pro',
  accounts: _AccountCodes(
    client: '411', sales: '701', vatCollected: '4431',
    supplier: '401', purchases: '601', vatDeductible: '4452',
    cash: '571', bank: '521',
    wages: '661', employerCharges: '664',
    wagesDue: '421', socialOrgs: '431', incomeTax: '441',
  ),
  seedAccounts: [
    AccountChart(code: '101', label: 'Capital social', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '111', label: 'Réserves légales', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '131', label: 'Résultat net de l\'exercice', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '162', label: 'Emprunts auprès des établissements de crédit', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '211', label: 'Charges immobilisées', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '241', label: 'Matériel et outillage', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '244', label: 'Matériel de transport', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '245', label: 'Matériel de bureau', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '31', label: 'Marchandises', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '32', label: 'Matières premières et approvisionnements', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '35', label: 'Produits finis', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '401', label: 'Fournisseurs, dettes en compte', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '411', label: 'Clients, effets à recevoir', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '421', label: 'Personnel — rémunérations dues', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '431', label: 'Sécurité sociale et organismes de retraite', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '441', label: 'État — impôts et taxes', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4431', label: 'TVA facturée sur ventes', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '4452', label: 'TVA récupérable sur achats', classNum: 4, type: 'bilan', isActive: true),
    AccountChart(code: '521', label: 'Banques locales', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '571', label: 'Caisse siège social', classNum: 5, type: 'bilan', isActive: true),
    AccountChart(code: '601', label: 'Achats de marchandises', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '602', label: 'Achats de matières premières', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '622', label: 'Locations et charges locatives', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '661', label: 'Rémunérations directes versées au personnel national', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '664', label: 'Charges sociales sur rémunérations', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '671', label: 'Intérêts des emprunts', classNum: 6, type: 'gestion', isActive: true),
    AccountChart(code: '701', label: 'Ventes de marchandises', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '702', label: 'Ventes de produits finis', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '706', label: 'Services vendus', classNum: 7, type: 'gestion', isActive: true),
    AccountChart(code: '771', label: 'Produits financiers divers', classNum: 7, type: 'gestion', isActive: true),
  ],
);

// ── International — IFRS Simplified ─────────────────────────────────────────

const _ifrs = AccountingCountry(
  code: 'IFRS',
  name: 'International (IFRS)',
  standard: 'IFRS',
  flag: '🌐',
  requiredPlan: 'enterprise',
  accounts: _AccountCodes(
    client: '1100', sales: '4000', vatCollected: '2200',
    supplier: '2000', purchases: '5000', vatDeductible: '1200',
    cash: '1001', bank: '1010',
    wages: '5100', employerCharges: '5200',
    wagesDue: '2100', socialOrgs: '2150', incomeTax: '2300',
  ),
  seedAccounts: [
    AccountChart(code: '1001', label: 'Cash and Cash Equivalents', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1010', label: 'Bank Accounts', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1100', label: 'Trade Receivables (Clients)', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1200', label: 'VAT Receivable', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1300', label: 'Inventories', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1500', label: 'Property, Plant and Equipment', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '1600', label: 'Intangible Assets', classNum: 1, type: 'bilan', isActive: true),
    AccountChart(code: '2000', label: 'Trade Payables (Suppliers)', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2100', label: 'Salaries Payable', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2150', label: 'Social Security Payable', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2200', label: 'VAT Payable', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2300', label: 'Income Tax Payable', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '2500', label: 'Long-Term Borrowings', classNum: 2, type: 'bilan', isActive: true),
    AccountChart(code: '3000', label: 'Share Capital', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3100', label: 'Retained Earnings', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '3200', label: 'Net Profit for the Period', classNum: 3, type: 'bilan', isActive: true),
    AccountChart(code: '4000', label: 'Revenue (Sales)', classNum: 4, type: 'gestion', isActive: true),
    AccountChart(code: '4100', label: 'Other Operating Income', classNum: 4, type: 'gestion', isActive: true),
    AccountChart(code: '4200', label: 'Finance Income', classNum: 4, type: 'gestion', isActive: true),
    AccountChart(code: '5000', label: 'Cost of Goods Sold / Purchases', classNum: 5, type: 'gestion', isActive: true),
    AccountChart(code: '5100', label: 'Salaries and Wages Expense', classNum: 5, type: 'gestion', isActive: true),
    AccountChart(code: '5200', label: 'Employer Social Contributions', classNum: 5, type: 'gestion', isActive: true),
    AccountChart(code: '5300', label: 'Rent Expense', classNum: 5, type: 'gestion', isActive: true),
    AccountChart(code: '5400', label: 'Utilities and Telecommunications', classNum: 5, type: 'gestion', isActive: true),
    AccountChart(code: '5500', label: 'Depreciation and Amortisation', classNum: 5, type: 'gestion', isActive: true),
    AccountChart(code: '5600', label: 'Finance Costs (Interest)', classNum: 5, type: 'gestion', isActive: true),
    AccountChart(code: '5700', label: 'Income Tax Expense', classNum: 5, type: 'gestion', isActive: true),
  ],
);
