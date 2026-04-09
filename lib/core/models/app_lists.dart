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
  });

  // ── Settings-table keys ────────────────────────────────────────────────────
  static const kCities             = 'list_cities';
  static const kTvaRates           = 'list_tva_rates';
  static const kFormesJuridiques   = 'list_formes_juridiques';
  static const kPaymentMethods     = 'list_payment_methods';
  static const kLeaveTypes         = 'list_leave_types';
  static const kProductCategories  = 'list_product_categories';
  static const kProductUnits       = 'list_product_units';
  static const kCompanyStatuses    = 'list_company_statuses';
  static const kEmployeeDepartments = 'list_employee_departments';

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
    return AppLists(
      cities:              str(kCities,              defaultCities),
      tvaRates:            dbl(kTvaRates,            defaultTvaRates),
      formesJuridiques:    str(kFormesJuridiques,    defaultFormesJuridiques),
      paymentMethods:      str(kPaymentMethods,      defaultPaymentMethods),
      leaveTypes:          str(kLeaveTypes,          defaultLeaveTypes),
      productCategories:   str(kProductCategories,   defaultProductCategories),
      productUnits:        str(kProductUnits,        defaultProductUnits),
      companyStatuses:     str(kCompanyStatuses,     defaultCompanyStatuses),
      employeeDepartments: str(kEmployeeDepartments, defaultEmployeeDepartments),
    );
  }

  static AppLists get defaults => fromSettings(const {});

  /// Serialize a list to JSON for DB storage.
  static String encode(List items) => jsonEncode(items);
}
