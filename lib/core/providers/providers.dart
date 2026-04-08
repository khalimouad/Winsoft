import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/sale_order.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';
import '../models/supplier_invoice.dart';
import '../models/credit_note.dart';
import '../models/recurring_template.dart';
import '../models/employee.dart';
import '../models/payroll_slip.dart';
import '../models/journal_entry.dart';
import '../models/manufacturing_bom.dart';
import '../models/pos_sale.dart';
import '../repositories/company_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_order_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/purchase_order_repository.dart';
import '../repositories/supplier_invoice_repository.dart';
import '../repositories/credit_note_repository.dart';
import '../repositories/recurring_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/accounting_repository.dart';
import '../repositories/manufacturing_repository.dart';
import '../repositories/pos_repository.dart';
import '../repositories/report_repository.dart';
import '../services/accounting_integration.dart';
import '../services/stock_service.dart';
import '../database/database_helper.dart';

// ── Repositories (singletons) ─────────────────────────────────────────────

final companyRepoProvider = Provider((_) => CompanyRepository());
final clientRepoProvider = Provider((_) => ClientRepository());
final productRepoProvider = Provider((_) => ProductRepository());
final saleOrderRepoProvider = Provider((_) => SaleOrderRepository());
final invoiceRepoProvider = Provider((_) => InvoiceRepository());

// ── Companies ─────────────────────────────────────────────────────────────

class CompanyNotifier extends AsyncNotifier<List<Company>> {
  @override
  Future<List<Company>> build() =>
      ref.read(companyRepoProvider).getAll();

  Future<void> add(Company company) async {
    final repo = ref.read(companyRepoProvider);
    await repo.insert(company);
    ref.invalidateSelf();
  }

  Future<void> edit(Company company) async {
    final repo = ref.read(companyRepoProvider);
    await repo.update(company);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    final repo = ref.read(companyRepoProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final companyProvider =
    AsyncNotifierProvider<CompanyNotifier, List<Company>>(CompanyNotifier.new);

// ── Clients ───────────────────────────────────────────────────────────────

class ClientNotifier extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() =>
      ref.read(clientRepoProvider).getAll();

  Future<void> add(Client client) async {
    await ref.read(clientRepoProvider).insert(client);
    ref.invalidateSelf();
  }

  Future<void> edit(Client client) async {
    await ref.read(clientRepoProvider).update(client);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(clientRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final clientProvider =
    AsyncNotifierProvider<ClientNotifier, List<Client>>(ClientNotifier.new);

// ── Products ──────────────────────────────────────────────────────────────

class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() =>
      ref.read(productRepoProvider).getAll();

  Future<void> add(Product product) async {
    await ref.read(productRepoProvider).insert(product);
    ref.invalidateSelf();
  }

  Future<void> edit(Product product) async {
    await ref.read(productRepoProvider).update(product);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(productRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final productProvider =
    AsyncNotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);

// ── Sale Orders ───────────────────────────────────────────────────────────

class SaleOrderNotifier extends AsyncNotifier<List<SaleOrder>> {
  @override
  Future<List<SaleOrder>> build() =>
      ref.read(saleOrderRepoProvider).getAll();

  Future<void> add(SaleOrder order, List<SaleOrderItem> items) async {
    await ref.read(saleOrderRepoProvider).insert(order, items);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(saleOrderRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(saleOrderRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final saleOrderProvider =
    AsyncNotifierProvider<SaleOrderNotifier, List<SaleOrder>>(
        SaleOrderNotifier.new);

// ── Invoices ──────────────────────────────────────────────────────────────

class InvoiceNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() =>
      ref.read(invoiceRepoProvider).getAll();

  Future<void> add(Invoice invoice, List<InvoiceItem> items) async {
    await ref.read(invoiceRepoProvider).insert(invoice, items);
    // Auto-post to accounting journal
    AccountingIntegration.postInvoice(invoice).ignore();
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(invoiceRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(invoiceRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final invoiceProvider =
    AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(InvoiceNotifier.new);

// ── Dashboard aggregates ──────────────────────────────────────────────────

class DashboardStats {
  final double totalRevenue;
  final int pendingCount;
  final double pendingAmount;
  final int clientCount;
  final int orderCount;
  final Map<String, int> invoiceStatusCounts;
  final List<Map<String, dynamic>> revenueByMonth;
  // Extended
  final double posRevenueTotal;
  final double hrMonthlyPayroll;
  final int lowStockCount;

  const DashboardStats({
    required this.totalRevenue,
    required this.pendingCount,
    required this.pendingAmount,
    required this.clientCount,
    required this.orderCount,
    required this.invoiceStatusCounts,
    required this.revenueByMonth,
    this.posRevenueTotal = 0,
    this.hrMonthlyPayroll = 0,
    this.lowStockCount = 0,
  });
}

final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final invoiceRepo = ref.read(invoiceRepoProvider);
  final clientRepo  = ref.read(clientRepoProvider);
  final orderRepo   = ref.read(saleOrderRepoProvider);
  final db          = DatabaseHelper.instance;

  final now   = DateTime.now();
  final month = now.month;
  final year  = now.year;

  final results = await Future.wait([
    invoiceRepo.totalRevenue(),
    invoiceRepo.pendingCount(),
    invoiceRepo.pendingAmount(),
    invoiceRepo.statusCounts(),
    invoiceRepo.revenueByMonth(6),
    // POS total revenue
    db.rawQueryScalar('SELECT COALESCE(SUM(total_ttc),0) FROM pos_sales', []),
    // HR payroll cost for current month
    db.rawQueryScalar(
      'SELECT COALESCE(SUM(salary_net),0) FROM payroll_slips WHERE period_year=? AND period_month=?',
      [year, month]),
    // Low stock count
    StockService.getLowStock(threshold: 5),
  ]);

  final clients = await clientRepo.getAll();
  final orders  = await orderRepo.getAll();

  return DashboardStats(
    totalRevenue:   results[0] as double,
    pendingCount:   results[1] as int,
    pendingAmount:  results[2] as double,
    clientCount:    clients.length,
    orderCount:     orders.length,
    invoiceStatusCounts: results[3] as Map<String, int>,
    revenueByMonth: results[4] as List<Map<String, dynamic>>,
    posRevenueTotal: (results[5] as num?)?.toDouble() ?? 0,
    hrMonthlyPayroll: (results[6] as num?)?.toDouble() ?? 0,
    lowStockCount: (results[7] as List).length,
  );
});

// ── Settings ──────────────────────────────────────────────────────────────

final settingsProvider = FutureProvider<Map<String, String>>((ref) async {
  return DatabaseHelper.instance.getAllSettings();
});

// ── Suppliers ─────────────────────────────────────────────────────────────

final supplierRepoProvider = Provider((_) => SupplierRepository());

class SupplierNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() => ref.read(supplierRepoProvider).getAll();

  Future<void> add(Supplier s) async {
    await ref.read(supplierRepoProvider).insert(s);
    ref.invalidateSelf();
  }

  Future<void> edit(Supplier s) async {
    await ref.read(supplierRepoProvider).update(s);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(supplierRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final supplierProvider =
    AsyncNotifierProvider<SupplierNotifier, List<Supplier>>(
        SupplierNotifier.new);

// ── Purchase Orders ───────────────────────────────────────────────────────

final purchaseOrderRepoProvider = Provider((_) => PurchaseOrderRepository());

class PurchaseOrderNotifier extends AsyncNotifier<List<PurchaseOrder>> {
  @override
  Future<List<PurchaseOrder>> build() =>
      ref.read(purchaseOrderRepoProvider).getAll();

  Future<void> add(PurchaseOrder order) async {
    await ref.read(purchaseOrderRepoProvider).insert(order);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(purchaseOrderRepoProvider).updateStatus(id, status);
    // Auto-post to accounting + increment stock when received
    if (status == 'Reçu') {
      final orders = await ref.read(purchaseOrderRepoProvider).getAll();
      final order = orders.where((o) => o.id == id).firstOrNull;
      if (order != null) {
        AccountingIntegration.postPurchaseReceived(order).ignore();
        // Increment stock for items that have a linked product
        final items = order.items
            .where((i) => i.productId != null)
            .map((i) => {'product_id': i.productId!, 'quantity': i.quantity})
            .toList();
        if (items.isNotEmpty) {
          StockService.incrementForPurchase(order.reference, items).ignore();
        }
      }
    }
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(purchaseOrderRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final purchaseOrderProvider =
    AsyncNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>(
        PurchaseOrderNotifier.new);

// ── Employees ─────────────────────────────────────────────────────────────

final employeeRepoProvider = Provider((_) => EmployeeRepository());

class EmployeeNotifier extends AsyncNotifier<List<Employee>> {
  @override
  Future<List<Employee>> build() => ref.read(employeeRepoProvider).getAll();

  Future<void> add(Employee e) async {
    await ref.read(employeeRepoProvider).insert(e);
    ref.invalidateSelf();
  }

  Future<void> edit(Employee e) async {
    await ref.read(employeeRepoProvider).update(e);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(employeeRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final employeeProvider =
    AsyncNotifierProvider<EmployeeNotifier, List<Employee>>(
        EmployeeNotifier.new);

// ── Payroll ───────────────────────────────────────────────────────────────

class PayrollNotifier extends AsyncNotifier<List<PayrollSlip>> {
  @override
  Future<List<PayrollSlip>> build() =>
      ref.read(employeeRepoProvider).getPayrollSlips();

  Future<void> add(PayrollSlip slip) async {
    await ref.read(employeeRepoProvider).insertPayrollSlip(slip);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(employeeRepoProvider).updatePayrollStatus(id, status);
    // Auto-post when validated
    if (status == 'Validé') {
      final slips = await ref.read(employeeRepoProvider).getPayrollSlips();
      final slip = slips.where((s) => s.id == id).firstOrNull;
      if (slip != null) AccountingIntegration.postPayroll(slip).ignore();
    }
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(employeeRepoProvider).deletePayrollSlip(id);
    ref.invalidateSelf();
  }
}

final payrollProvider =
    AsyncNotifierProvider<PayrollNotifier, List<PayrollSlip>>(
        PayrollNotifier.new);

// ── Accounting ────────────────────────────────────────────────────────────

final accountingRepoProvider = Provider((_) => AccountingRepository());

class AccountChartNotifier extends AsyncNotifier<List<AccountChart>> {
  @override
  Future<List<AccountChart>> build() async {
    final repo = ref.read(accountingRepoProvider);
    await repo.seedPcm();
    return repo.getAccounts();
  }
}

final accountChartProvider =
    AsyncNotifierProvider<AccountChartNotifier, List<AccountChart>>(
        AccountChartNotifier.new);

class JournalEntryNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() =>
      ref.read(accountingRepoProvider).getEntries();

  Future<void> add(JournalEntry entry) async {
    await ref.read(accountingRepoProvider).insertEntry(entry);
    ref.invalidateSelf();
  }

  Future<void> validate(int id) async {
    await ref.read(accountingRepoProvider).validateEntry(id);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(accountingRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final journalEntryProvider =
    AsyncNotifierProvider<JournalEntryNotifier, List<JournalEntry>>(
        JournalEntryNotifier.new);

// ── Manufacturing ─────────────────────────────────────────────────────────

final manufacturingRepoProvider = Provider((_) => ManufacturingRepository());

class BomNotifier extends AsyncNotifier<List<ManufacturingBom>> {
  @override
  Future<List<ManufacturingBom>> build() =>
      ref.read(manufacturingRepoProvider).getAllBoms();

  Future<void> add(ManufacturingBom bom) async {
    await ref.read(manufacturingRepoProvider).insertBom(bom);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(manufacturingRepoProvider).deleteBom(id);
    ref.invalidateSelf();
  }
}

final bomProvider =
    AsyncNotifierProvider<BomNotifier, List<ManufacturingBom>>(BomNotifier.new);

class ProductionOrderNotifier extends AsyncNotifier<List<ProductionOrder>> {
  @override
  Future<List<ProductionOrder>> build() =>
      ref.read(manufacturingRepoProvider).getAllOrders();

  Future<void> add(ProductionOrder order) async {
    await ref.read(manufacturingRepoProvider).insertOrder(order);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(manufacturingRepoProvider).updateOrderStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(manufacturingRepoProvider).deleteOrder(id);
    ref.invalidateSelf();
  }
}

final productionOrderProvider =
    AsyncNotifierProvider<ProductionOrderNotifier, List<ProductionOrder>>(
        ProductionOrderNotifier.new);

// ── POS ───────────────────────────────────────────────────────────────────────

final posRepoProvider = Provider((_) => PosRepository());

class PriceListNotifier extends AsyncNotifier<List<PriceList>> {
  @override
  Future<List<PriceList>> build() =>
      ref.read(posRepoProvider).getAllPriceLists();

  Future<void> add(PriceList pl) async {
    await ref.read(posRepoProvider).insertPriceList(pl);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(posRepoProvider).deletePriceList(id);
    ref.invalidateSelf();
  }
}

final priceListProvider =
    AsyncNotifierProvider<PriceListNotifier, List<PriceList>>(
        PriceListNotifier.new);

class PosSaleNotifier extends AsyncNotifier<List<PosSale>> {
  @override
  Future<List<PosSale>> build() => ref.read(posRepoProvider).getSales();

  Future<int> completeSale(PosSale sale) async {
    final id = await ref.read(posRepoProvider).insertSale(sale);
    // Auto-post to accounting
    AccountingIntegration.postPosSale(sale).ignore();
    // Decrement stock for each item
    final items = sale.items
        .map((i) => {'product_id': i.productId, 'quantity': i.quantity})
        .toList();
    StockService.decrementForPosSale(sale.reference, items).ignore();
    ref.invalidateSelf();
    return id;
  }
}

final posSaleProvider =
    AsyncNotifierProvider<PosSaleNotifier, List<PosSale>>(PosSaleNotifier.new);

// ── Reports ───────────────────────────────────────────────────────────────────

final reportRepoProvider = Provider((_) => ReportRepository());

// ── Supplier Invoices ─────────────────────────────────────────────────────────

final supplierInvoiceRepoProvider = Provider((_) => SupplierInvoiceRepository());

class SupplierInvoiceNotifier extends AsyncNotifier<List<SupplierInvoice>> {
  @override
  Future<List<SupplierInvoice>> build() =>
      ref.read(supplierInvoiceRepoProvider).getAll();

  Future<void> add(SupplierInvoice inv) async {
    await ref.read(supplierInvoiceRepoProvider).insert(inv);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(supplierInvoiceRepoProvider).updateStatus(id, status);
    // Post to accounting when validated
    if (status == 'Validée') {
      final all = await ref.read(supplierInvoiceRepoProvider).getAll();
      final inv = all.where((i) => i.id == id).firstOrNull;
      if (inv != null) AccountingIntegration.postSupplierInvoice(inv).ignore();
    }
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(supplierInvoiceRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final supplierInvoiceProvider =
    AsyncNotifierProvider<SupplierInvoiceNotifier, List<SupplierInvoice>>(
        SupplierInvoiceNotifier.new);

// ── Credit Notes ──────────────────────────────────────────────────────────────

final creditNoteRepoProvider = Provider((_) => CreditNoteRepository());

class CreditNoteNotifier extends AsyncNotifier<List<CreditNote>> {
  @override
  Future<List<CreditNote>> build() =>
      ref.read(creditNoteRepoProvider).getAll();

  Future<void> add(CreditNote cn) async {
    await ref.read(creditNoteRepoProvider).insert(cn);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(creditNoteRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(creditNoteRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final creditNoteProvider =
    AsyncNotifierProvider<CreditNoteNotifier, List<CreditNote>>(
        CreditNoteNotifier.new);

// ── Recurring Templates ───────────────────────────────────────────────────────

final recurringRepoProvider = Provider((_) => RecurringRepository());

class RecurringNotifier extends AsyncNotifier<List<RecurringTemplate>> {
  @override
  Future<List<RecurringTemplate>> build() =>
      ref.read(recurringRepoProvider).getAll();

  Future<void> add(RecurringTemplate t) async {
    await ref.read(recurringRepoProvider).insert(t);
    ref.invalidateSelf();
  }

  Future<void> updateNextDue(int id, int nextDueDate) async {
    await ref.read(recurringRepoProvider).updateNextDue(id, nextDueDate);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(recurringRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final recurringProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringTemplate>>(
        RecurringNotifier.new);
