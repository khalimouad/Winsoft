import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // sqflite FFI is initialized in main.dart before this is called
    final path = await getDatabasesPath();
    final dbPath = '$path/winsoft.db';

    return openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        email         TEXT    NOT NULL UNIQUE COLLATE NOCASE,
        password_hash TEXT    NOT NULL,
        role          TEXT    NOT NULL DEFAULT 'employee',
        avatar        TEXT,
        is_active     INTEGER NOT NULL DEFAULT 1,
        created_at    INTEGER NOT NULL,
        last_login_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE companies (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        industry      TEXT,
        email         TEXT,
        phone         TEXT,
        address       TEXT,
        city          TEXT,
        ice           TEXT,
        rc            TEXT,
        if_number     TEXT,
        patente       TEXT,
        cnss          TEXT,
        capital_social REAL,
        status        TEXT    NOT NULL DEFAULT 'Active',
        created_at    INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        company_id  INTEGER REFERENCES companies(id) ON DELETE SET NULL,
        email       TEXT,
        phone       TEXT,
        address     TEXT,
        city        TEXT,
        cin         TEXT,
        ice         TEXT,
        notes       TEXT,
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        reference   TEXT,
        category    TEXT,
        price_ht    REAL    NOT NULL DEFAULT 0,
        tva_rate    REAL    NOT NULL DEFAULT 20,
        stock       INTEGER,
        unit        TEXT,
        description TEXT,
        status      TEXT    NOT NULL DEFAULT 'Actif',
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_orders (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        reference   TEXT    NOT NULL UNIQUE,
        client_id   INTEGER NOT NULL REFERENCES clients(id),
        date        INTEGER NOT NULL,
        status      TEXT    NOT NULL DEFAULT 'En attente',
        notes       TEXT,
        total_ht    REAL    NOT NULL DEFAULT 0,
        total_tva   REAL    NOT NULL DEFAULT 0,
        total_ttc   REAL    NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_order_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id      INTEGER NOT NULL REFERENCES sale_orders(id) ON DELETE CASCADE,
        product_id    INTEGER REFERENCES products(id) ON DELETE SET NULL,
        description   TEXT    NOT NULL,
        quantity      REAL    NOT NULL DEFAULT 1,
        unit_price_ht REAL    NOT NULL DEFAULT 0,
        tva_rate      REAL    NOT NULL DEFAULT 20
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        reference     TEXT    NOT NULL UNIQUE,
        client_id     INTEGER NOT NULL REFERENCES clients(id),
        order_id      INTEGER REFERENCES sale_orders(id) ON DELETE SET NULL,
        issued_date   INTEGER NOT NULL,
        due_date      INTEGER NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'Brouillon',
        notes         TEXT,
        total_ht      REAL    NOT NULL DEFAULT 0,
        total_tva     REAL    NOT NULL DEFAULT 0,
        total_ttc     REAL    NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id    INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
        product_id    INTEGER REFERENCES products(id) ON DELETE SET NULL,
        description   TEXT    NOT NULL,
        quantity      REAL    NOT NULL DEFAULT 1,
        unit_price_ht REAL    NOT NULL DEFAULT 0,
        tva_rate      REAL    NOT NULL DEFAULT 20
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await _createNewTables(db);
    await _createPosTables(db);
    await _createV4Tables(db);
    await _seedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createNewTables(db);
    }
    if (oldVersion < 3) {
      await _createPosTables(db);
    }
    if (oldVersion < 4) {
      await _createV4Tables(db);
    }
  }

  Future<void> _createNewTables(Database db) async {
    // ── Suppliers ────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        email      TEXT,
        phone      TEXT,
        address    TEXT,
        city       TEXT,
        ice        TEXT,
        rc         TEXT,
        if_number  TEXT,
        patente    TEXT,
        rib        TEXT,
        notes      TEXT,
        status     TEXT    NOT NULL DEFAULT 'Actif',
        created_at INTEGER NOT NULL
      )
    ''');

    // ── Purchase orders ──────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_orders (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        reference   TEXT    NOT NULL UNIQUE,
        supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
        date        INTEGER NOT NULL,
        status      TEXT    NOT NULL DEFAULT 'Brouillon',
        notes       TEXT,
        total_ht    REAL    NOT NULL DEFAULT 0,
        total_tva   REAL    NOT NULL DEFAULT 0,
        total_ttc   REAL    NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_order_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id      INTEGER NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
        product_id    INTEGER REFERENCES products(id) ON DELETE SET NULL,
        description   TEXT    NOT NULL,
        quantity      REAL    NOT NULL DEFAULT 1,
        unit_price_ht REAL    NOT NULL DEFAULT 0,
        tva_rate      REAL    NOT NULL DEFAULT 20,
        received_qty  REAL    NOT NULL DEFAULT 0
      )
    ''');

    // ── Supplier invoices ────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_invoices (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        reference     TEXT    NOT NULL,
        supplier_id   INTEGER NOT NULL REFERENCES suppliers(id),
        order_id      INTEGER REFERENCES purchase_orders(id) ON DELETE SET NULL,
        issued_date   INTEGER NOT NULL,
        due_date      INTEGER NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'Reçue',
        notes         TEXT,
        total_ht      REAL    NOT NULL DEFAULT 0,
        total_tva     REAL    NOT NULL DEFAULT 0,
        total_ttc     REAL    NOT NULL DEFAULT 0
      )
    ''');

    // ── HR: Employees ────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        email         TEXT,
        phone         TEXT,
        cin           TEXT,
        cnss_num      TEXT,
        department    TEXT,
        position      TEXT,
        salary_brut   REAL    NOT NULL DEFAULT 0,
        hire_date     INTEGER NOT NULL,
        birth_date    INTEGER,
        address       TEXT,
        city          TEXT,
        rib           TEXT,
        is_active     INTEGER NOT NULL DEFAULT 1,
        created_at    INTEGER NOT NULL
      )
    ''');

    // ── HR: Payroll slips ────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payroll_slips (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id    INTEGER NOT NULL REFERENCES employees(id),
        period_year    INTEGER NOT NULL,
        period_month   INTEGER NOT NULL,
        salary_brut    REAL    NOT NULL DEFAULT 0,
        cnss_employee  REAL    NOT NULL DEFAULT 0,
        amo_employee   REAL    NOT NULL DEFAULT 0,
        igr            REAL    NOT NULL DEFAULT 0,
        other_deductions REAL  NOT NULL DEFAULT 0,
        salary_net     REAL    NOT NULL DEFAULT 0,
        cnss_employer  REAL    NOT NULL DEFAULT 0,
        amo_employer   REAL    NOT NULL DEFAULT 0,
        status         TEXT    NOT NULL DEFAULT 'Brouillon',
        notes          TEXT,
        created_at     INTEGER NOT NULL,
        UNIQUE(employee_id, period_year, period_month)
      )
    ''');

    // ── HR: Leaves ───────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS leaves (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL REFERENCES employees(id),
        type        TEXT    NOT NULL DEFAULT 'Congé annuel',
        start_date  INTEGER NOT NULL,
        end_date    INTEGER NOT NULL,
        days        REAL    NOT NULL DEFAULT 1,
        status      TEXT    NOT NULL DEFAULT 'En attente',
        reason      TEXT,
        created_at  INTEGER NOT NULL
      )
    ''');

    // ── Accounting: Chart of accounts (PCM) ──────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_chart (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        code        TEXT    NOT NULL UNIQUE,
        label       TEXT    NOT NULL,
        class_num   INTEGER NOT NULL,
        type        TEXT    NOT NULL DEFAULT 'bilan',
        is_active   INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // ── Accounting: Journal entries ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        reference   TEXT    NOT NULL UNIQUE,
        date        INTEGER NOT NULL,
        description TEXT,
        journal     TEXT    NOT NULL DEFAULT 'OD',
        is_validated INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entry_lines (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id    INTEGER NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
        account_id  INTEGER NOT NULL REFERENCES account_chart(id),
        label       TEXT,
        debit       REAL    NOT NULL DEFAULT 0,
        credit      REAL    NOT NULL DEFAULT 0
      )
    ''');

    // ── Manufacturing: BOM ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS manufacturing_boms (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        description TEXT,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bom_components (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        bom_id      INTEGER NOT NULL REFERENCES manufacturing_boms(id) ON DELETE CASCADE,
        product_id  INTEGER NOT NULL REFERENCES products(id),
        quantity    REAL    NOT NULL DEFAULT 1,
        unit        TEXT,
        role        TEXT    NOT NULL DEFAULT 'input',
        notes       TEXT
      )
    ''');

    // ── Manufacturing: Production orders ──────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS production_orders (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        reference    TEXT    NOT NULL UNIQUE,
        bom_id       INTEGER NOT NULL REFERENCES manufacturing_boms(id),
        planned_date INTEGER NOT NULL,
        start_date   INTEGER,
        end_date     INTEGER,
        status       TEXT    NOT NULL DEFAULT 'Brouillon',
        notes        TEXT,
        created_at   INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS production_order_outputs (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        production_order_id INTEGER NOT NULL REFERENCES production_orders(id) ON DELETE CASCADE,
        product_id          INTEGER NOT NULL REFERENCES products(id),
        planned_qty         REAL    NOT NULL DEFAULT 0,
        actual_qty          REAL    NOT NULL DEFAULT 0,
        role                TEXT    NOT NULL DEFAULT 'output'
      )
    ''');
  }

  Future<void> _createPosTables(Database db) async {
    // ── Price lists ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS price_lists (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT    NOT NULL,
        description      TEXT,
        discount_percent REAL    NOT NULL DEFAULT 0,
        is_default       INTEGER NOT NULL DEFAULT 0,
        created_at       INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS price_list_items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        price_list_id    INTEGER NOT NULL REFERENCES price_lists(id) ON DELETE CASCADE,
        product_id       INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        fixed_price      REAL,
        discount_percent REAL    NOT NULL DEFAULT 0,
        UNIQUE(price_list_id, product_id)
      )
    ''');

    // ── POS sessions ─────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_sessions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        opened_at     INTEGER NOT NULL,
        closed_at     INTEGER,
        opening_cash  REAL    NOT NULL DEFAULT 0,
        closing_cash  REAL,
        status        TEXT    NOT NULL DEFAULT 'open',
        user_id       INTEGER NOT NULL REFERENCES users(id)
      )
    ''');

    // ── POS sales ────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_sales (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        reference      TEXT    NOT NULL UNIQUE,
        session_id     INTEGER NOT NULL REFERENCES pos_sessions(id),
        client_id      INTEGER REFERENCES clients(id) ON DELETE SET NULL,
        sale_date      INTEGER NOT NULL,
        total_ht       REAL    NOT NULL DEFAULT 0,
        total_tva      REAL    NOT NULL DEFAULT 0,
        total_ttc      REAL    NOT NULL DEFAULT 0,
        payment_method TEXT    NOT NULL DEFAULT 'Espèces',
        amount_tendered REAL   NOT NULL DEFAULT 0,
        change_given   REAL    NOT NULL DEFAULT 0,
        price_list_id  INTEGER REFERENCES price_lists(id) ON DELETE SET NULL,
        notes          TEXT,
        invoice_id     INTEGER REFERENCES invoices(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_sale_items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id          INTEGER NOT NULL REFERENCES pos_sales(id) ON DELETE CASCADE,
        product_id       INTEGER NOT NULL REFERENCES products(id),
        description      TEXT    NOT NULL,
        quantity         REAL    NOT NULL DEFAULT 1,
        unit_price_ht    REAL    NOT NULL DEFAULT 0,
        tva_rate         REAL    NOT NULL DEFAULT 20,
        discount_percent REAL    NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createV4Tables(Database db) async {
    // ── Supplier invoice items (the table existed but items sub-table was missing)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_invoice_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id    INTEGER NOT NULL REFERENCES supplier_invoices(id) ON DELETE CASCADE,
        product_id    INTEGER REFERENCES products(id) ON DELETE SET NULL,
        description   TEXT    NOT NULL,
        quantity      REAL    NOT NULL DEFAULT 1,
        unit_price_ht REAL    NOT NULL DEFAULT 0,
        tva_rate      REAL    NOT NULL DEFAULT 20
      )
    ''');

    // ── Credit notes (avoirs) ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_notes (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        reference   TEXT    NOT NULL UNIQUE,
        client_id   INTEGER NOT NULL REFERENCES clients(id),
        invoice_id  INTEGER NOT NULL REFERENCES invoices(id),
        issue_date  INTEGER NOT NULL,
        total_ht    REAL    NOT NULL DEFAULT 0,
        total_tva   REAL    NOT NULL DEFAULT 0,
        total_ttc   REAL    NOT NULL DEFAULT 0,
        reason      TEXT,
        status      TEXT    NOT NULL DEFAULT 'Brouillon',
        created_at  INTEGER NOT NULL
      )
    ''');

    // ── Recurring invoice templates ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_templates (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        client_id     INTEGER NOT NULL REFERENCES clients(id),
        frequency     TEXT    NOT NULL DEFAULT 'monthly',
        next_due_date INTEGER NOT NULL,
        total_ht      REAL    NOT NULL DEFAULT 0,
        total_tva     REAL    NOT NULL DEFAULT 0,
        total_ttc     REAL    NOT NULL DEFAULT 0,
        notes         TEXT,
        is_active     INTEGER NOT NULL DEFAULT 1,
        created_at    INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id   INTEGER NOT NULL REFERENCES recurring_templates(id) ON DELETE CASCADE,
        description   TEXT    NOT NULL,
        quantity      REAL    NOT NULL DEFAULT 1,
        unit_price_ht REAL    NOT NULL DEFAULT 0,
        tva_rate      REAL    NOT NULL DEFAULT 20
      )
    ''');

    // ── Stock movements log ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id  INTEGER NOT NULL REFERENCES products(id),
        quantity    REAL    NOT NULL,
        type        TEXT    NOT NULL,
        reference   TEXT,
        date        INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed users
    // Default admin: admin@winsoft.ma / Admin123
    await db.insert('users', {
      'name': 'Administrateur',
      'email': 'admin@winsoft.ma',
      'password_hash': 'h\$c4f9a2b1', // Admin123
      'role': 'admin',
      'is_active': 1,
      'created_at': now,
    });
    await db.insert('users', {
      'name': 'Karim Bensouda',
      'email': 'k.bensouda@winsoft.ma',
      'password_hash': 'h\$a1b2c3d4',
      'role': 'manager',
      'is_active': 1,
      'created_at': now,
    });
    await db.insert('users', {
      'name': 'Samira El Alami',
      'email': 's.elalami@winsoft.ma',
      'password_hash': 'h\$d4c3b2a1',
      'role': 'comptable',
      'is_active': 1,
      'created_at': now,
    });
    await db.insert('settings', {'key': 'subscription_plan', 'value': 'pro'});
    await db.insert('settings', {'key': 'subscription_status', 'value': 'trial'});
    await db.insert('settings',
        {'key': 'subscription_end', 'value': DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch.toString()});

    // Seed companies
    final acmeId = await db.insert('companies', {
      'name': 'Acme Maroc SARL',
      'industry': 'Industrie',
      'email': 'contact@acme.ma',
      'phone': '0522334455',
      'address': '12, Bd Zerktouni',
      'city': 'Casablanca',
      'ice': '002345678000067',
      'rc': 'RC 12345',
      'if_number': 'IF 87654321',
      'patente': '29876543',
      'status': 'Active',
      'created_at': now,
    });

    final globeId = await db.insert('companies', {
      'name': 'Globe Industries SA',
      'industry': 'Technologie',
      'email': 'info@globe.ma',
      'phone': '0537123456',
      'address': '5, Avenue Mohammed V',
      'city': 'Rabat',
      'ice': '001234567000089',
      'rc': 'RC 67890',
      'if_number': 'IF 12345678',
      'status': 'Active',
      'created_at': now,
    });

    final techId = await db.insert('companies', {
      'name': 'TechStart SARL',
      'industry': 'Logiciels',
      'email': 'hello@techstart.ma',
      'phone': '0524789012',
      'address': '23, Rue Ibn Sina',
      'city': 'Marrakech',
      'ice': '003456789000012',
      'status': 'Active',
      'created_at': now,
    });

    final deltaId = await db.insert('companies', {
      'name': 'Delta Conseil',
      'industry': 'Conseil',
      'email': 'equipe@delta.ma',
      'phone': '0535456789',
      'address': '8, Rue Allal Ben Abdellah',
      'city': 'Fès',
      'ice': '004567890000034',
      'status': 'Active',
      'created_at': now,
    });

    // Seed clients
    final c1 = await db.insert('clients', {
      'name': 'Hassan Benali',
      'company_id': acmeId,
      'email': 'h.benali@acme.ma',
      'phone': '0661234567',
      'city': 'Casablanca',
      'cin': 'AB123456',
      'created_at': now,
    });

    final c2 = await db.insert('clients', {
      'name': 'Fatima Zahra Alaoui',
      'company_id': globeId,
      'email': 'fz.alaoui@globe.ma',
      'phone': '0671234567',
      'city': 'Rabat',
      'cin': 'CD789012',
      'created_at': now,
    });

    final c3 = await db.insert('clients', {
      'name': 'Youssef Chraibi',
      'company_id': techId,
      'email': 'y.chraibi@techstart.ma',
      'phone': '0651234567',
      'city': 'Marrakech',
      'cin': 'EF345678',
      'created_at': now,
    });

    final c4 = await db.insert('clients', {
      'name': 'Nadia Tazi',
      'company_id': deltaId,
      'email': 'n.tazi@delta.ma',
      'phone': '0641234567',
      'city': 'Fès',
      'cin': 'GH901234',
      'created_at': now,
    });

    final c5 = await db.insert('clients', {
      'name': 'Omar Senhaji',
      'company_id': null,
      'email': 'o.senhaji@gmail.com',
      'phone': '0612345678',
      'city': 'Tanger',
      'cin': 'IJ567890',
      'created_at': now,
    });

    // Seed products
    final p1 = await db.insert('products', {
      'name': 'Pack Conseil Standard',
      'reference': 'CONS-001',
      'category': 'Services',
      'price_ht': 10000.0,
      'tva_rate': 20.0,
      'unit': 'forfait',
      'status': 'Actif',
      'created_at': now,
    });

    final p2 = await db.insert('products', {
      'name': 'Pack Conseil Premium',
      'reference': 'CONS-002',
      'category': 'Services',
      'price_ht': 25000.0,
      'tva_rate': 20.0,
      'unit': 'forfait',
      'status': 'Actif',
      'created_at': now,
    });

    final p3 = await db.insert('products', {
      'name': 'Licence Logiciel — Annuelle',
      'reference': 'LOG-101',
      'category': 'Logiciels',
      'price_ht': 7500.0,
      'tva_rate': 20.0,
      'unit': 'licence',
      'status': 'Actif',
      'created_at': now,
    });

    final p4 = await db.insert('products', {
      'name': 'Kit Matériel Informatique',
      'reference': 'MAT-201',
      'category': 'Matériel',
      'price_ht': 3500.0,
      'tva_rate': 20.0,
      'stock': 25,
      'unit': 'pièce',
      'status': 'Actif',
      'created_at': now,
    });

    final p5 = await db.insert('products', {
      'name': 'Support Technique — Mensuel',
      'reference': 'SUP-010',
      'category': 'Support',
      'price_ht': 1500.0,
      'tva_rate': 20.0,
      'unit': 'mois',
      'status': 'Actif',
      'created_at': now,
    });

    // Seed sale orders
    final so1 = await db.insert('sale_orders', {
      'reference': 'BC-2026-001',
      'client_id': c1,
      'date': DateTime(2026, 4, 5).millisecondsSinceEpoch,
      'status': 'Terminée',
      'total_ht': 10000.0,
      'total_tva': 2000.0,
      'total_ttc': 12000.0,
    });
    await db.insert('sale_order_items', {
      'order_id': so1, 'product_id': p1, 'description': 'Pack Conseil Standard',
      'quantity': 1, 'unit_price_ht': 10000.0, 'tva_rate': 20.0,
    });

    final so2 = await db.insert('sale_orders', {
      'reference': 'BC-2026-002',
      'client_id': c2,
      'date': DateTime(2026, 4, 4).millisecondsSinceEpoch,
      'status': 'En cours',
      'total_ht': 32500.0,
      'total_tva': 6500.0,
      'total_ttc': 39000.0,
    });
    await db.insert('sale_order_items', {
      'order_id': so2, 'product_id': p2, 'description': 'Pack Conseil Premium',
      'quantity': 1, 'unit_price_ht': 25000.0, 'tva_rate': 20.0,
    });
    await db.insert('sale_order_items', {
      'order_id': so2, 'product_id': p3, 'description': 'Licence Logiciel',
      'quantity': 1, 'unit_price_ht': 7500.0, 'tva_rate': 20.0,
    });

    final so3 = await db.insert('sale_orders', {
      'reference': 'BC-2026-003',
      'client_id': c3,
      'date': DateTime(2026, 3, 28).millisecondsSinceEpoch,
      'status': 'Terminée',
      'total_ht': 7000.0,
      'total_tva': 1400.0,
      'total_ttc': 8400.0,
    });
    await db.insert('sale_order_items', {
      'order_id': so3, 'product_id': p4, 'description': 'Kit Matériel x2',
      'quantity': 2, 'unit_price_ht': 3500.0, 'tva_rate': 20.0,
    });

    final so4 = await db.insert('sale_orders', {
      'reference': 'BC-2026-004',
      'client_id': c4,
      'date': DateTime(2026, 4, 6).millisecondsSinceEpoch,
      'status': 'En attente',
      'total_ht': 26500.0,
      'total_tva': 5300.0,
      'total_ttc': 31800.0,
    });
    await db.insert('sale_order_items', {
      'order_id': so4, 'product_id': p2, 'description': 'Pack Conseil Premium',
      'quantity': 1, 'unit_price_ht': 25000.0, 'tva_rate': 20.0,
    });
    await db.insert('sale_order_items', {
      'order_id': so4, 'product_id': p5, 'description': 'Support Technique',
      'quantity': 1, 'unit_price_ht': 1500.0, 'tva_rate': 20.0,
    });

    // Seed invoices
    await db.insert('invoices', {
      'reference': 'FAC-2026-001',
      'client_id': c1,
      'order_id': so1,
      'issued_date': DateTime(2026, 4, 5).millisecondsSinceEpoch,
      'due_date': DateTime(2026, 4, 19).millisecondsSinceEpoch,
      'status': 'Payée',
      'notes': 'Merci pour votre confiance.',
      'total_ht': 10000.0,
      'total_tva': 2000.0,
      'total_ttc': 12000.0,
    });

    await db.insert('invoices', {
      'reference': 'FAC-2026-002',
      'client_id': c2,
      'order_id': so2,
      'issued_date': DateTime(2026, 4, 4).millisecondsSinceEpoch,
      'due_date': DateTime(2026, 4, 18).millisecondsSinceEpoch,
      'status': 'Envoyée',
      'total_ht': 32500.0,
      'total_tva': 6500.0,
      'total_ttc': 39000.0,
    });

    await db.insert('invoices', {
      'reference': 'FAC-2026-003',
      'client_id': c3,
      'order_id': so3,
      'issued_date': DateTime(2026, 3, 28).millisecondsSinceEpoch,
      'due_date': DateTime(2026, 4, 11).millisecondsSinceEpoch,
      'status': 'En retard',
      'total_ht': 7000.0,
      'total_tva': 1400.0,
      'total_ttc': 8400.0,
    });

    await db.insert('invoices', {
      'reference': 'FAC-2026-004',
      'client_id': c4,
      'order_id': null,
      'issued_date': DateTime(2026, 4, 6).millisecondsSinceEpoch,
      'due_date': DateTime(2026, 4, 20).millisecondsSinceEpoch,
      'status': 'Brouillon',
      'total_ht': 26500.0,
      'total_tva': 5300.0,
      'total_ttc': 31800.0,
    });

    await db.insert('invoices', {
      'reference': 'FAC-2026-005',
      'client_id': c5,
      'order_id': null,
      'issued_date': DateTime(2026, 3, 15).millisecondsSinceEpoch,
      'due_date': DateTime(2026, 3, 29).millisecondsSinceEpoch,
      'status': 'En retard',
      'total_ht': 3000.0,
      'total_tva': 600.0,
      'total_ttc': 3600.0,
    });

    // Seed default settings
    await db.insert('settings', {'key': 'company_name', 'value': 'Ma Société SARL'});
    await db.insert('settings', {'key': 'company_email', 'value': ''});
    await db.insert('settings', {'key': 'company_phone', 'value': ''});
    await db.insert('settings', {'key': 'company_address', 'value': ''});
    await db.insert('settings', {'key': 'company_city', 'value': 'Casablanca'});
    await db.insert('settings', {'key': 'company_ice', 'value': ''});
    await db.insert('settings', {'key': 'company_rc', 'value': ''});
    await db.insert('settings', {'key': 'company_if', 'value': ''});
    await db.insert('settings', {'key': 'invoice_prefix', 'value': 'FAC'});
    await db.insert('settings', {'key': 'invoice_terms', 'value': '30 jours net'});
    await db.insert('settings', {'key': 'invoice_notes', 'value': 'Merci pour votre confiance.'});
    await db.insert('settings', {'key': 'tva_default', 'value': '20'});
  }

  // ── Generic helpers ────────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(
      String table, Map<String, dynamic> values, int id) async {
    final db = await database;
    return db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
      String sql, List<Object?> args) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<int?> rawQueryScalar(String sql, List<Object?> args) async {
    final db = await database;
    final rows = await db.rawQuery(sql, args);
    if (rows.isEmpty) return null;
    final val = rows.first.values.first;
    if (val == null) return null;
    return (val as num).toInt();
  }

  Future<double?> rawQueryDouble(String sql, List<Object?> args) async {
    final db = await database;
    final rows = await db.rawQuery(sql, args);
    if (rows.isEmpty) return null;
    final val = rows.first.values.first;
    if (val == null) return null;
    return (val as num).toDouble();
  }

  Future<String?> getSetting(String key) async {
    final rows = await query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String? ?? ''};
  }
}
