import 'dart:convert';

/// All user-configurable dropdown/list values, stored as JSON in settings table.
class AppLists {
  final List<String> cities;
  final List<double> tvaRates;
  final List<String> formesJuridiques;
  final List<String> paymentMethods;
  final List<String> leaveTypes;
  final List<String> productCategories;
  final List<String> productUnits;
  final List<String> companyStatuses;
  final List<String> employeeDepartments;
  /// Accounting journals: ordered list of {code, label} pairs.
  final List<JournalDef> journals;

  // ── Status lists ────────────────────────────────────────────────────────────
  final List<String> invoiceStatuses;
  final List<String> orderStatuses;
  final List<String> purchaseOrderStatuses;
  final List<String> supplierInvoiceStatuses;
  final List<String> creditNoteStatuses;
  final List<String> payrollStatuses;
  final List<String> productionStatuses;
  final List<String> leaveStatuses;

  const AppLists({
    required this.cities,
    required this.tvaRates,
    required this.formesJuridiques,
    required this.paymentMethods,
    required this.leaveTypes,
    required this.productCategories,
    required this.productUnits,
    required this.companyStatuses,
    required this.employeeDepartments,
    required this.journals,
    required this.invoiceStatuses,
    required this.orderStatuses,
    required this.purchaseOrderStatuses,
    required this.supplierInvoiceStatuses,
    required this.creditNoteStatuses,
    required this.payrollStatuses,
    required this.productionStatuses,
    required this.leaveStatuses,
  });

  // ── Settings-table keys ────────────────────────────────────────────────────
  static const kCities                    = 'list_cities';
  static const kTvaRates                  = 'list_tva_rates';
  static const kFormesJuridiques          = 'list_formes_juridiques';
  static const kPaymentMethods            = 'list_payment_methods';
  static const kLeaveTypes               = 'list_leave_types';
  static const kProductCategories        = 'list_product_categories';
  static const kProductUnits             = 'list_product_units';
  static const kCompanyStatuses          = 'list_company_statuses';
  static const kEmployeeDepartments      = 'list_employee_departments';
  static const kJournals                 = 'list_journals';
  static const kInvoiceStatuses          = 'list_invoice_statuses';
  static const kOrderStatuses            = 'list_order_statuses';
  static const kPurchaseOrderStatuses    = 'list_po_statuses';
  static const kSupplierInvoiceStatuses  = 'list_supplier_invoice_statuses';
  static const kCreditNoteStatuses       = 'list_cn_statuses';
  static const kPayrollStatuses          = 'list_payroll_statuses';
  static const kProductionStatuses       = 'list_production_statuses';
  static const kLeaveStatuses            = 'list_leave_statuses';

  // ── Built-in defaults ──────────────────────────────────────────────────────
  static const defaultCities = [
    'Casablanca', 'Rabat', 'Marrakech', 'Fès', 'Tanger', 'Agadir',
    'Meknès', 'Oujda', 'Kénitra', 'Tétouan', 'Salé', 'Mohammedia',
    'El Jadida', 'Beni Mellal', 'Nador', 'Settat', 'Berrechid',
    'Khouribga', 'Taza', 'Safi', 'Autre',
  ];
  static const defaultTvaRates = [0.0, 7.0, 10.0, 14.0, 20.0];
  static const defaultFormesJuridiques = [
    'SARL', 'SA', 'SNC', 'SCS', 'Auto-entrepreneur', 'Personne physique',
  ];
  static const defaultPaymentMethods = [
    'Espèces', 'Carte', 'Chèque', 'Virement',
  ];
  static const defaultLeaveTypes = [
    'Congé annuel', 'Congé maladie', 'Congé maternité',
    'Congé paternité', 'Congé sans solde', 'Autre',
  ];
  static const defaultProductCategories = [
    'Services', 'Informatique', 'Fournitures', 'Marchandises',
    'Matières premières', 'Emballage', 'Autre',
  ];
  static const defaultProductUnits = [
    'pcs', 'kg', 'g', 'L', 'm', 'm²', 'boîte', 'carton', 'heure', 'forfait',
  ];
  static const defaultCompanyStatuses = [
    'Active', 'Inactive', 'En cours de création',
  ];
  static const defaultEmployeeDepartments = [
    'Direction', 'Comptabilité', 'Commercial', 'Technique', 'RH',
    'Logistique', 'Informatique', 'Production', 'Autre',
  ];
  static const defaultJournals = [
    JournalDef(code: 'OD',  label: 'Opérations diverses'),
    JournalDef(code: 'VTE', label: 'Ventes'),
    JournalDef(code: 'ACH', label: 'Achats'),
    JournalDef(code: 'TRE', label: 'Trésorerie'),
    JournalDef(code: 'SAL', label: 'Salaires'),
  ];
  static const defaultInvoiceStatuses         = ['Brouillon', 'Envoyée', 'Payée', 'En retard'];
  static const defaultOrderStatuses           = ['En attente', 'En cours', 'Terminée', 'Annulée'];
  static const defaultPurchaseOrderStatuses   = ['Brouillon', 'Envoyé', 'Reçu', 'Partiel', 'Annulé'];
  static const defaultSupplierInvoiceStatuses = ['Reçue', 'Validée', 'Payée', 'Contestée', 'Annulée'];
  static const defaultCreditNoteStatuses      = ['Brouillon', 'Émis', 'Appliqué'];
  static const defaultPayrollStatuses         = ['Brouillon', 'Validé', 'Payé'];
  static const defaultProductionStatuses      = ['Brouillon', 'Planifié', 'En cours', 'Terminé', 'Annulé'];
  static const defaultLeaveStatuses           = ['En attente', 'Approuvé', 'Refusé', 'Annulé'];

  // ── Deserialize from settings map ──────────────────────────────────────────
  static AppLists fromSettings(Map<String, String> s) {
    List<String> str(String key, List<String> def) {
      final v = s[key];
      if (v == null || v.isEmpty) return List<String>.from(def);
      try { return List<String>.from(jsonDecode(v)); }
      catch (_) { return List<String>.from(def); }
    }
    List<double> dbl(String key, List<double> def) {
      final v = s[key];
      if (v == null || v.isEmpty) return List<double>.from(def);
      try {
        return List<dynamic>.from(jsonDecode(v))
            .map((e) => (e as num).toDouble())
            .toList();
      } catch (_) { return List<double>.from(def); }
    }
    List<JournalDef> journals(String key) {
      final v = s[key];
      if (v == null || v.isEmpty) return List.from(defaultJournals);
      try {
        return (jsonDecode(v) as List)
            .map((e) => JournalDef(
                code: e['code'] as String,
                label: e['label'] as String))
            .toList();
      } catch (_) { return List.from(defaultJournals); }
    }
    return AppLists(
      cities:                    str(kCities,                    defaultCities),
      tvaRates:                  dbl(kTvaRates,                  defaultTvaRates),
      formesJuridiques:          str(kFormesJuridiques,          defaultFormesJuridiques),
      paymentMethods:            str(kPaymentMethods,            defaultPaymentMethods),
      leaveTypes:                str(kLeaveTypes,                defaultLeaveTypes),
      productCategories:         str(kProductCategories,         defaultProductCategories),
      productUnits:              str(kProductUnits,              defaultProductUnits),
      companyStatuses:           str(kCompanyStatuses,           defaultCompanyStatuses),
      employeeDepartments:       str(kEmployeeDepartments,       defaultEmployeeDepartments),
      journals:                  journals(kJournals),
      invoiceStatuses:           str(kInvoiceStatuses,           defaultInvoiceStatuses),
      orderStatuses:             str(kOrderStatuses,             defaultOrderStatuses),
      purchaseOrderStatuses:     str(kPurchaseOrderStatuses,     defaultPurchaseOrderStatuses),
      supplierInvoiceStatuses:   str(kSupplierInvoiceStatuses,   defaultSupplierInvoiceStatuses),
      creditNoteStatuses:        str(kCreditNoteStatuses,        defaultCreditNoteStatuses),
      payrollStatuses:           str(kPayrollStatuses,           defaultPayrollStatuses),
      productionStatuses:        str(kProductionStatuses,        defaultProductionStatuses),
      leaveStatuses:             str(kLeaveStatuses,             defaultLeaveStatuses),
    );
  }

  static AppLists get defaults => fromSettings(const {});

  /// Serialize a simple list to JSON for DB storage.
  static String encode(List items) => jsonEncode(items);

  /// Serialize journal list to JSON for DB storage.
  static String encodeJournals(List<JournalDef> jnl) =>
      jsonEncode(jnl.map((j) => {'code': j.code, 'label': j.label}).toList());
}

/// A single accounting journal definition (code + human-readable label).
class JournalDef {
  final String code;
  final String label;
  const JournalDef({required this.code, required this.label});
  String get display => '$code — $label';
}
