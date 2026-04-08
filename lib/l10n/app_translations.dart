// ignore_for_file: constant_identifier_names
/// Central translation map for FR (default) / AR (RTL) / EN.
/// Usage: AppTranslations.t('key')  — after setting languageProvider.
library app_translations;

import 'package:flutter/widgets.dart';

const Map<String, Map<String, String>> _translations = {
  // ── Navigation ────────────────────────────────────────────────────────────
  'nav.dashboard':    {'fr': 'Tableau de bord',   'ar': 'لوحة التحكم',      'en': 'Dashboard'},
  'nav.companies':    {'fr': 'Entreprises',        'ar': 'الشركات',          'en': 'Companies'},
  'nav.clients':      {'fr': 'Clients',            'ar': 'العملاء',          'en': 'Clients'},
  'nav.sales':        {'fr': 'Bons de Commande',   'ar': 'أوامر البيع',      'en': 'Sales Orders'},
  'nav.products':     {'fr': 'Produits & Services','ar': 'المنتجات والخدمات','en': 'Products & Services'},
  'nav.invoices':     {'fr': 'Factures Clients',   'ar': 'فواتير العملاء',   'en': 'Customer Invoices'},
  'nav.purchases':    {'fr': 'Achats',             'ar': 'المشتريات',        'en': 'Purchases'},
  'nav.hr':           {'fr': 'Ressources Humaines','ar': 'الموارد البشرية',  'en': 'Human Resources'},
  'nav.accounting':   {'fr': 'Comptabilité',       'ar': 'المحاسبة',         'en': 'Accounting'},
  'nav.manufacturing':{'fr': 'Production',         'ar': 'الإنتاج',          'en': 'Manufacturing'},
  'nav.team':         {'fr': 'Équipe',             'ar': 'الفريق',           'en': 'Team'},
  'nav.subscription': {'fr': 'Abonnement',         'ar': 'الاشتراك',         'en': 'Subscription'},
  'nav.settings':     {'fr': 'Paramètres',         'ar': 'الإعدادات',        'en': 'Settings'},

  // ── Nav groups ───────────────────────────────────────────────────────────
  'group.general':    {'fr': 'GÉNÉRAL',            'ar': 'عام',              'en': 'GENERAL'},
  'group.contacts':   {'fr': 'CONTACTS',           'ar': 'جهات الاتصال',     'en': 'CONTACTS'},
  'group.sales':      {'fr': 'VENTES',             'ar': 'المبيعات',         'en': 'SALES'},
  'group.inventory':  {'fr': 'INVENTAIRE',         'ar': 'المخزون',          'en': 'INVENTORY'},
  'group.billing':    {'fr': 'FACTURATION',        'ar': 'الفوترة',          'en': 'BILLING'},
  'group.operations': {'fr': 'OPÉRATIONS',         'ar': 'العمليات',         'en': 'OPERATIONS'},
  'group.admin':      {'fr': 'ADMINISTRATION',     'ar': 'الإدارة',          'en': 'ADMINISTRATION'},

  // ── Common actions ───────────────────────────────────────────────────────
  'action.add':       {'fr': 'Ajouter',            'ar': 'إضافة',            'en': 'Add'},
  'action.edit':      {'fr': 'Modifier',           'ar': 'تعديل',            'en': 'Edit'},
  'action.delete':    {'fr': 'Supprimer',          'ar': 'حذف',              'en': 'Delete'},
  'action.cancel':    {'fr': 'Annuler',            'ar': 'إلغاء',            'en': 'Cancel'},
  'action.save':      {'fr': 'Enregistrer',        'ar': 'حفظ',              'en': 'Save'},
  'action.search':    {'fr': 'Rechercher…',        'ar': 'بحث…',             'en': 'Search…'},
  'action.filter':    {'fr': 'Filtrer',            'ar': 'تصفية',            'en': 'Filter'},
  'action.export':    {'fr': 'Exporter',           'ar': 'تصدير',            'en': 'Export'},
  'action.print':     {'fr': 'Imprimer',           'ar': 'طباعة',            'en': 'Print'},
  'action.close':     {'fr': 'Fermer',             'ar': 'إغلاق',            'en': 'Close'},
  'action.confirm':   {'fr': 'Confirmer',          'ar': 'تأكيد',            'en': 'Confirm'},
  'action.logout':    {'fr': 'Se déconnecter',     'ar': 'تسجيل الخروج',     'en': 'Logout'},

  // ── Common fields ────────────────────────────────────────────────────────
  'field.name':       {'fr': 'Nom',                'ar': 'الاسم',            'en': 'Name'},
  'field.email':      {'fr': 'Email',              'ar': 'البريد الإلكتروني','en': 'Email'},
  'field.phone':      {'fr': 'Téléphone',          'ar': 'الهاتف',           'en': 'Phone'},
  'field.address':    {'fr': 'Adresse',            'ar': 'العنوان',          'en': 'Address'},
  'field.city':       {'fr': 'Ville',              'ar': 'المدينة',          'en': 'City'},
  'field.status':     {'fr': 'Statut',             'ar': 'الحالة',           'en': 'Status'},
  'field.date':       {'fr': 'Date',               'ar': 'التاريخ',          'en': 'Date'},
  'field.amount':     {'fr': 'Montant',            'ar': 'المبلغ',           'en': 'Amount'},
  'field.total':      {'fr': 'Total',              'ar': 'المجموع',          'en': 'Total'},
  'field.notes':      {'fr': 'Notes',              'ar': 'ملاحظات',          'en': 'Notes'},
  'field.reference':  {'fr': 'Référence',          'ar': 'المرجع',           'en': 'Reference'},
  'field.description':{'fr': 'Description',        'ar': 'الوصف',            'en': 'Description'},
  'field.role':       {'fr': 'Rôle',               'ar': 'الدور',            'en': 'Role'},
  'field.password':   {'fr': 'Mot de passe',       'ar': 'كلمة المرور',      'en': 'Password'},

  // ── Dashboard ────────────────────────────────────────────────────────────
  'dash.title':         {'fr': 'Tableau de bord',      'ar': 'لوحة التحكم',    'en': 'Dashboard'},
  'dash.revenue':       {'fr': 'Chiffre d\'affaires',  'ar': 'رقم الأعمال',    'en': 'Revenue'},
  'dash.invoices':      {'fr': 'Factures en attente',  'ar': 'الفواتير المعلقة','en': 'Pending Invoices'},
  'dash.clients':       {'fr': 'Clients actifs',       'ar': 'العملاء النشطون','en': 'Active Clients'},
  'dash.orders':        {'fr': 'Commandes du mois',    'ar': 'طلبات الشهر',    'en': 'Monthly Orders'},
  'dash.chart_revenue': {'fr': 'Évolution du CA',      'ar': 'تطور رقم الأعمال','en': 'Revenue Trend'},
  'dash.chart_invoices':{'fr': 'Statuts des factures', 'ar': 'حالات الفواتير', 'en': 'Invoice Status'},
  'dash.recent':        {'fr': 'Factures récentes',    'ar': 'الفواتير الأخيرة','en': 'Recent Invoices'},

  // ── Auth ─────────────────────────────────────────────────────────────────
  'auth.login':       {'fr': 'Se connecter',       'ar': 'تسجيل الدخول',    'en': 'Login'},
  'auth.email':       {'fr': 'Adresse email',      'ar': 'البريد الإلكتروني','en': 'Email address'},
  'auth.password':    {'fr': 'Mot de passe',       'ar': 'كلمة المرور',      'en': 'Password'},
  'auth.error':       {'fr': 'Email ou mot de passe incorrect.','ar': 'البريد أو كلمة المرور غير صحيحة.','en': 'Incorrect email or password.'},
  'auth.welcome':     {'fr': 'Bienvenue sur WinSoft','ar': 'مرحباً بك في WinSoft','en': 'Welcome to WinSoft'},
  'auth.subtitle':    {'fr': 'Gestion d\'entreprise complète','ar': 'إدارة الأعمال الشاملة','en': 'Complete Business Management'},

  // ── Invoices ─────────────────────────────────────────────────────────────
  'inv.draft':        {'fr': 'Brouillon',          'ar': 'مسودة',            'en': 'Draft'},
  'inv.sent':         {'fr': 'Envoyée',            'ar': 'مرسلة',            'en': 'Sent'},
  'inv.paid':         {'fr': 'Payée',              'ar': 'مدفوعة',           'en': 'Paid'},
  'inv.overdue':      {'fr': 'En retard',          'ar': 'متأخرة',           'en': 'Overdue'},
  'inv.cancelled':    {'fr': 'Annulée',            'ar': 'ملغاة',            'en': 'Cancelled'},

  // ── Sales orders ─────────────────────────────────────────────────────────
  'ord.pending':      {'fr': 'En attente',         'ar': 'قيد الانتظار',     'en': 'Pending'},
  'ord.processing':   {'fr': 'En cours',           'ar': 'قيد المعالجة',     'en': 'Processing'},
  'ord.completed':    {'fr': 'Terminée',           'ar': 'مكتملة',           'en': 'Completed'},
  'ord.cancelled':    {'fr': 'Annulée',            'ar': 'ملغاة',            'en': 'Cancelled'},

  // ── Purchase ─────────────────────────────────────────────────────────────
  'pur.title':        {'fr': 'Achats',             'ar': 'المشتريات',        'en': 'Purchases'},
  'pur.suppliers':    {'fr': 'Fournisseurs',       'ar': 'الموردون',         'en': 'Suppliers'},
  'pur.orders':       {'fr': 'Bons de commande',   'ar': 'أوامر الشراء',     'en': 'Purchase Orders'},
  'pur.invoices':     {'fr': 'Factures fournisseurs','ar': 'فواتير الموردين','en': 'Supplier Invoices'},
  'pur.add_supplier': {'fr': 'Nouveau fournisseur','ar': 'مورد جديد',        'en': 'New Supplier'},
  'pur.add_order':    {'fr': 'Nouveau bon d\'achat','ar': 'أمر شراء جديد',   'en': 'New Purchase Order'},
  'pur.draft':        {'fr': 'Brouillon',          'ar': 'مسودة',            'en': 'Draft'},
  'pur.sent':         {'fr': 'Envoyé',             'ar': 'مرسل',             'en': 'Sent'},
  'pur.received':     {'fr': 'Reçu',               'ar': 'مستلم',            'en': 'Received'},
  'pur.partial':      {'fr': 'Partiel',            'ar': 'جزئي',             'en': 'Partial'},
  'pur.cancelled':    {'fr': 'Annulé',             'ar': 'ملغى',             'en': 'Cancelled'},
  'pur.supplier':     {'fr': 'Fournisseur',        'ar': 'المورد',           'en': 'Supplier'},
  'pur.reception':    {'fr': 'Réception',          'ar': 'الاستلام',         'en': 'Reception'},

  // ── HR ───────────────────────────────────────────────────────────────────
  'hr.title':         {'fr': 'Ressources Humaines','ar': 'الموارد البشرية',  'en': 'Human Resources'},
  'hr.employees':     {'fr': 'Employés',           'ar': 'الموظفون',         'en': 'Employees'},
  'hr.payroll':       {'fr': 'Paie',               'ar': 'كشف الرواتب',      'en': 'Payroll'},
  'hr.leaves':        {'fr': 'Congés',             'ar': 'الإجازات',         'en': 'Leaves'},
  'hr.add_employee':  {'fr': 'Nouvel employé',     'ar': 'موظف جديد',        'en': 'New Employee'},
  'hr.salary':        {'fr': 'Salaire brut',       'ar': 'الراتب الإجمالي',  'en': 'Gross Salary'},
  'hr.net':           {'fr': 'Salaire net',        'ar': 'الراتب الصافي',    'en': 'Net Salary'},
  'hr.cnss':          {'fr': 'CNSS',               'ar': 'CNSS',             'en': 'CNSS'},
  'hr.amo':           {'fr': 'AMO',                'ar': 'AMO',              'en': 'AMO'},
  'hr.igr':           {'fr': 'IR (IGR)',           'ar': 'الضريبة على الدخل','en': 'Income Tax'},
  'hr.active':        {'fr': 'Actif',              'ar': 'نشط',              'en': 'Active'},
  'hr.inactive':      {'fr': 'Inactif',            'ar': 'غير نشط',          'en': 'Inactive'},
  'hr.cin':           {'fr': 'CIN',                'ar': 'رقم البطاقة الوطنية','en': 'National ID'},
  'hr.hire_date':     {'fr': 'Date d\'embauche',   'ar': 'تاريخ التعيين',    'en': 'Hire Date'},
  'hr.department':    {'fr': 'Département',        'ar': 'القسم',            'en': 'Department'},
  'hr.position':      {'fr': 'Poste',              'ar': 'المنصب',           'en': 'Position'},
  'hr.leave_annual':  {'fr': 'Congé annuel',       'ar': 'إجازة سنوية',      'en': 'Annual Leave'},
  'hr.leave_sick':    {'fr': 'Congé maladie',      'ar': 'إجازة مرضية',      'en': 'Sick Leave'},
  'hr.leave_unpaid':  {'fr': 'Congé sans solde',   'ar': 'إجازة بدون أجر',   'en': 'Unpaid Leave'},

  // ── Accounting ───────────────────────────────────────────────────────────
  'acc.title':        {'fr': 'Comptabilité',       'ar': 'المحاسبة',         'en': 'Accounting'},
  'acc.chart':        {'fr': 'Plan Comptable',     'ar': 'الدليل المحاسبي',  'en': 'Chart of Accounts'},
  'acc.journal':      {'fr': 'Journal',            'ar': 'دفتر اليومية',     'en': 'Journal'},
  'acc.ledger':       {'fr': 'Grand Livre',        'ar': 'دفتر الأستاذ',     'en': 'General Ledger'},
  'acc.balance':      {'fr': 'Bilan',              'ar': 'الميزانية',        'en': 'Balance Sheet'},
  'acc.income':       {'fr': 'CPC',                'ar': 'حساب النتائج',     'en': 'Income Statement'},
  'acc.tva':          {'fr': 'Déclaration TVA',    'ar': 'إقرار الضريبة',    'en': 'VAT Declaration'},
  'acc.debit':        {'fr': 'Débit',              'ar': 'مدين',             'en': 'Debit'},
  'acc.credit':       {'fr': 'Crédit',             'ar': 'دائن',             'en': 'Credit'},
  'acc.entry':        {'fr': 'Écriture',           'ar': 'قيد محاسبي',       'en': 'Journal Entry'},

  // ── Manufacturing ────────────────────────────────────────────────────────
  'mfg.title':        {'fr': 'Production',         'ar': 'الإنتاج',          'en': 'Manufacturing'},
  'mfg.bom':          {'fr': 'Nomenclatures',      'ar': 'قوائم المواد',     'en': 'Bill of Materials'},
  'mfg.orders':       {'fr': 'Ordres de fabrication','ar': 'أوامر التصنيع', 'en': 'Production Orders'},
  'mfg.add_bom':      {'fr': 'Nouvelle nomenclature','ar': 'قائمة مواد جديدة','en': 'New BOM'},
  'mfg.add_order':    {'fr': 'Nouvel ordre',       'ar': 'أمر جديد',         'en': 'New Order'},
  'mfg.raw_material': {'fr': 'Matière première',   'ar': 'مواد خام',         'en': 'Raw Material'},
  'mfg.finished':     {'fr': 'Produit fini',       'ar': 'منتج نهائي',       'en': 'Finished Product'},
  'mfg.byproduct':    {'fr': 'Sous-produit',       'ar': 'منتج ثانوي',       'en': 'By-product'},
  'mfg.qty':          {'fr': 'Quantité',           'ar': 'الكمية',           'en': 'Quantity'},
  'mfg.draft':        {'fr': 'Brouillon',          'ar': 'مسودة',            'en': 'Draft'},
  'mfg.planned':      {'fr': 'Planifié',           'ar': 'مخطط',             'en': 'Planned'},
  'mfg.in_progress':  {'fr': 'En cours',           'ar': 'قيد التنفيذ',      'en': 'In Progress'},
  'mfg.done':         {'fr': 'Terminé',            'ar': 'منتهي',            'en': 'Done'},
  'mfg.cancelled':    {'fr': 'Annulé',             'ar': 'ملغى',             'en': 'Cancelled'},

  // ── Settings ─────────────────────────────────────────────────────────────
  'set.title':        {'fr': 'Paramètres',         'ar': 'الإعدادات',        'en': 'Settings'},
  'set.company':      {'fr': 'Informations entreprise','ar': 'معلومات الشركة','en': 'Company Info'},
  'set.language':     {'fr': 'Langue',             'ar': 'اللغة',            'en': 'Language'},
  'set.theme':        {'fr': 'Thème',              'ar': 'المظهر',           'en': 'Theme'},
  'set.dark_mode':    {'fr': 'Mode sombre',        'ar': 'الوضع المظلم',     'en': 'Dark Mode'},
  'set.saved':        {'fr': 'Paramètres enregistrés','ar': 'تم الحفظ',      'en': 'Settings saved'},
  'set.lang_fr':      {'fr': 'Français',           'ar': 'الفرنسية',         'en': 'French'},
  'set.lang_ar':      {'fr': 'العربية',            'ar': 'العربية',          'en': 'Arabic'},
  'set.lang_en':      {'fr': 'English',            'ar': 'الإنجليزية',       'en': 'English'},

  // ── Errors / validation ──────────────────────────────────────────────────
  'err.required':     {'fr': 'Champ requis',       'ar': 'الحقل مطلوب',      'en': 'Required field'},
  'err.invalid_email':{'fr': 'Email invalide',     'ar': 'بريد إلكتروني غير صحيح','en': 'Invalid email'},
  'err.min4':         {'fr': 'Min. 4 caractères',  'ar': 'الحد الأدنى 4 أحرف','en': 'Min. 4 characters'},
  'err.generic':      {'fr': 'Une erreur est survenue','ar': 'حدث خطأ',      'en': 'An error occurred'},
};

/// Holds the currently active language code ('fr', 'ar', 'en').
String _currentLang = 'fr';

class AppTranslations {
  AppTranslations._();

  /// Set the active language (call when languageProvider changes).
  static void setLanguage(String lang) {
    if (['fr', 'ar', 'en'].contains(lang)) _currentLang = lang;
  }

  /// Look up a translation key in the current language.
  /// Falls back to French, then to the key itself.
  static String t(String key) {
    return _translations[key]?[_currentLang] ??
        _translations[key]?['fr'] ??
        key;
  }

  /// Whether the current language is RTL.
  static bool get isRtl => _currentLang == 'ar';

  /// TextDirection for the current language.
  static TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  static String get currentLang => _currentLang;
}
