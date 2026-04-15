import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_lists.dart';
import '../models/payroll_config.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/sale_order.dart';
import '../models/invoice.dart';
import '../models/delivery.dart';
import '../models/return_note.dart';
import '../models/payment.dart';
import '../models/reception.dart';
import '../models/purchase_request.dart';
import '../models/warehouse.dart';
import '../models/product_category.dart';
import '../models/physical_inventory.dart';
import '../models/fiscal_year.dart';
import '../models/bank_account.dart';
import '../models/employee_contract.dart';
import '../models/employee_loan.dart';
import '../models/expense.dart';
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
import '../repositories/delivery_repository.dart';
import '../repositories/return_note_repository.dart';
import '../repositories/payments_received_repository.dart';
import '../repositories/payments_sent_repository.dart';
import '../repositories/reception_repository.dart';
import '../repositories/purchase_request_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../repositories/product_category_repository.dart';
import '../repositories/physical_inventory_repository.dart';
import '../repositories/fiscal_year_repository.dart';
import '../repositories/bank_account_repository.dart';
import '../repositories/employee_contract_repository.dart';
import '../repositories/employee_loan_repository.dart';
import '../repositories/expense_repository.dart';
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

  final int lowStockThreshold;

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
    this.lowStockThreshold = 5,
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

  final settings = await ref.watch(settingsProvider.future);
  final lowStockThreshold =
      int.tryParse(settings['low_stock_threshold'] ?? '5') ?? 5;

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
    // Low stock count (threshold from settings)
    StockService.getLowStock(threshold: lowStockThreshold),
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
    lowStockThreshold: lowStockThreshold,
  );
});

// ── Settings ──────────────────────────────────────────────────────────────

final settingsProvider = FutureProvider<Map<String, String>>((ref) async {
  return DatabaseHelper.instance.getAllSettings();
});

/// All user-configurable lists (cities, TVA rates, formes juridiques, etc.)
final appListsProvider = FutureProvider<AppLists>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return AppLists.fromSettings(settings);
});

/// Moroccan payroll configuration (CNSS/AMO rates + IGR brackets).
final payrollConfigProvider = FutureProvider<PayrollConfig>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final raw = settings[PayrollConfig.kSettings];
  if (raw == null || raw.isEmpty) return PayrollConfig.defaults;
  return PayrollConfig.fromJson(raw);
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

// ── Deliveries (Bons de livraison) ────────────────────────────────────────────

final deliveryRepoProvider = Provider((_) => DeliveryRepository());

class DeliveryNotifier extends AsyncNotifier<List<Delivery>> {
  @override
  Future<List<Delivery>> build() =>
      ref.read(deliveryRepoProvider).getAll();

  Future<void> add(Delivery delivery, List<DeliveryItem> items) async {
    await ref.read(deliveryRepoProvider).insert(delivery, items);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(deliveryRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(deliveryRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final deliveryProvider =
    AsyncNotifierProvider<DeliveryNotifier, List<Delivery>>(
        DeliveryNotifier.new);

// ── Return Notes (Bons de retour) ─────────────────────────────────────────────

final returnNoteRepoProvider = Provider((_) => ReturnNoteRepository());

class ReturnNoteNotifier extends AsyncNotifier<List<ReturnNote>> {
  @override
  Future<List<ReturnNote>> build() =>
      ref.read(returnNoteRepoProvider).getAll();

  Future<void> add(ReturnNote rn, List<ReturnNoteItem> items) async {
    await ref.read(returnNoteRepoProvider).insert(rn, items);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(returnNoteRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(returnNoteRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final returnNoteProvider =
    AsyncNotifierProvider<ReturnNoteNotifier, List<ReturnNote>>(
        ReturnNoteNotifier.new);

// ── Payments Received ─────────────────────────────────────────────────────────

final paymentsReceivedRepoProvider =
    Provider((_) => PaymentsReceivedRepository());

class PaymentsReceivedNotifier extends AsyncNotifier<List<PaymentReceived>> {
  @override
  Future<List<PaymentReceived>> build() =>
      ref.read(paymentsReceivedRepoProvider).getAll();

  /// Records a new payment and auto-marks invoice as Payée if fully settled.
  Future<void> record(PaymentReceived payment, double invoiceTtc) async {
    final repo = ref.read(paymentsReceivedRepoProvider);
    await repo.insert(payment);
    // Check if invoice is now fully paid
    final total = await repo.totalByInvoiceId(payment.invoiceId);
    if (total >= invoiceTtc - 0.01) {
      await ref
          .read(invoiceRepoProvider)
          .updateStatus(payment.invoiceId, 'Payée');
      ref.invalidate(invoiceProvider);
    }
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(paymentsReceivedRepoProvider).delete(id);
    ref.invalidate(invoiceProvider);
    ref.invalidateSelf();
  }
}

final paymentsReceivedProvider =
    AsyncNotifierProvider<PaymentsReceivedNotifier, List<PaymentReceived>>(
        PaymentsReceivedNotifier.new);

// ── Payments Sent ─────────────────────────────────────────────────────────────

final paymentsSentRepoProvider =
    Provider((_) => PaymentsSentRepository());

class PaymentsSentNotifier extends AsyncNotifier<List<PaymentSent>> {
  @override
  Future<List<PaymentSent>> build() =>
      ref.read(paymentsSentRepoProvider).getAll();

  /// Records a payment to a supplier and auto-marks invoice as Payée if settled.
  Future<void> record(PaymentSent payment, double invoiceTtc) async {
    final repo = ref.read(paymentsSentRepoProvider);
    await repo.insert(payment);
    final total =
        await repo.totalBySupplierInvoiceId(payment.supplierInvoiceId);
    if (total >= invoiceTtc - 0.01) {
      await ref
          .read(supplierInvoiceRepoProvider)
          .updateStatus(payment.supplierInvoiceId, 'Payée');
      ref.invalidate(supplierInvoiceProvider);
    }
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(paymentsSentRepoProvider).delete(id);
    ref.invalidate(supplierInvoiceProvider);
    ref.invalidateSelf();
  }
}

final paymentsSentProvider =
    AsyncNotifierProvider<PaymentsSentNotifier, List<PaymentSent>>(
        PaymentsSentNotifier.new);

// ── Receptions (GRN) ─────────────────────────────────────────────────────────

final receptionRepoProvider = Provider((_) => ReceptionRepository());

class ReceptionNotifier extends AsyncNotifier<List<Reception>> {
  @override
  Future<List<Reception>> build() =>
      ref.read(receptionRepoProvider).getAll();

  Future<void> add(Reception reception, List<ReceptionItem> items) async {
    await ref.read(receptionRepoProvider).insert(reception, items);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(receptionRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(receptionRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final receptionProvider =
    AsyncNotifierProvider<ReceptionNotifier, List<Reception>>(
        ReceptionNotifier.new);

// ── Purchase Requests (DA) ────────────────────────────────────────────────────

final purchaseRequestRepoProvider =
    Provider((_) => PurchaseRequestRepository());

class PurchaseRequestNotifier
    extends AsyncNotifier<List<PurchaseRequest>> {
  @override
  Future<List<PurchaseRequest>> build() =>
      ref.read(purchaseRequestRepoProvider).getAll();

  Future<void> add(
      PurchaseRequest request, List<PurchaseRequestItem> items) async {
    await ref.read(purchaseRequestRepoProvider).insert(request, items);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(purchaseRequestRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(purchaseRequestRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final purchaseRequestProvider =
    AsyncNotifierProvider<PurchaseRequestNotifier, List<PurchaseRequest>>(
        PurchaseRequestNotifier.new);

// ── Warehouses ────────────────────────────────────────────────────────────────

final warehouseRepoProvider = Provider((_) => WarehouseRepository());

class WarehouseNotifier extends AsyncNotifier<List<Warehouse>> {
  @override
  Future<List<Warehouse>> build() =>
      ref.read(warehouseRepoProvider).getAll();

  Future<void> add(Warehouse warehouse) async {
    await ref.read(warehouseRepoProvider).insert(warehouse);
    ref.invalidateSelf();
  }

  Future<void> edit(Warehouse warehouse) async {
    await ref.read(warehouseRepoProvider).update(warehouse);
    ref.invalidateSelf();
  }

  Future<void> setDefault(int id) async {
    await ref.read(warehouseRepoProvider).setDefault(id);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(warehouseRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final warehouseProvider =
    AsyncNotifierProvider<WarehouseNotifier, List<Warehouse>>(
        WarehouseNotifier.new);

// ── Product Categories ────────────────────────────────────────────────────────

final productCategoryRepoProvider =
    Provider((_) => ProductCategoryRepository());

class ProductCategoryNotifier extends AsyncNotifier<List<ProductCategory>> {
  @override
  Future<List<ProductCategory>> build() =>
      ref.read(productCategoryRepoProvider).getAll();

  Future<void> add(ProductCategory category) async {
    await ref.read(productCategoryRepoProvider).insert(category);
    ref.invalidateSelf();
  }

  Future<void> edit(ProductCategory category) async {
    await ref.read(productCategoryRepoProvider).update(category);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(productCategoryRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final productCategoryProvider =
    AsyncNotifierProvider<ProductCategoryNotifier, List<ProductCategory>>(
        ProductCategoryNotifier.new);

// ── Physical Inventories ──────────────────────────────────────────────────────

final physicalInventoryRepoProvider =
    Provider((_) => PhysicalInventoryRepository());

class PhysicalInventoryNotifier
    extends AsyncNotifier<List<PhysicalInventory>> {
  @override
  Future<List<PhysicalInventory>> build() =>
      ref.read(physicalInventoryRepoProvider).getAll();

  Future<void> add(
      PhysicalInventory inventory, List<PhysicalInventoryLine> lines) async {
    await ref
        .read(physicalInventoryRepoProvider)
        .insert(inventory, lines);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref
        .read(physicalInventoryRepoProvider)
        .updateStatus(id, status);
    // If validated, apply variances to product stock
    if (status == 'Validé') {
      final inv =
          await ref.read(physicalInventoryRepoProvider).getById(id);
      if (inv != null) {
        final productRepo = ref.read(productRepoProvider);
        for (final line in inv.lines) {
          if (line.productId != null && line.hasVariance) {
            final product =
                await productRepo.getById(line.productId!);
            if (product != null) {
              await productRepo.update(
                  product.copyWith(stock: line.countedQty.round()));
            }
          }
        }
        ref.invalidate(productProvider);
      }
    }
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(physicalInventoryRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final physicalInventoryProvider =
    AsyncNotifierProvider<PhysicalInventoryNotifier, List<PhysicalInventory>>(
        PhysicalInventoryNotifier.new);

// ── Fiscal Years ──────────────────────────────────────────────────────────────

final fiscalYearRepoProvider = Provider((_) => FiscalYearRepository());

class FiscalYearNotifier extends AsyncNotifier<List<FiscalYear>> {
  @override
  Future<List<FiscalYear>> build() =>
      ref.read(fiscalYearRepoProvider).getAll();

  Future<void> add(FiscalYear fy) async {
    await ref.read(fiscalYearRepoProvider).insert(fy);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(fiscalYearRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(fiscalYearRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final fiscalYearProvider =
    AsyncNotifierProvider<FiscalYearNotifier, List<FiscalYear>>(
        FiscalYearNotifier.new);

// ── Bank Accounts ─────────────────────────────────────────────────────────────

final bankAccountRepoProvider = Provider((_) => BankAccountRepository());

class BankAccountNotifier extends AsyncNotifier<List<BankAccount>> {
  @override
  Future<List<BankAccount>> build() =>
      ref.read(bankAccountRepoProvider).getAll();

  Future<void> add(BankAccount account) async {
    await ref.read(bankAccountRepoProvider).insert(account);
    ref.invalidateSelf();
  }

  Future<void> edit(BankAccount account) async {
    await ref.read(bankAccountRepoProvider).update(account);
    ref.invalidateSelf();
  }

  Future<void> setDefault(int id) async {
    await ref.read(bankAccountRepoProvider).setDefault(id);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(bankAccountRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final bankAccountProvider =
    AsyncNotifierProvider<BankAccountNotifier, List<BankAccount>>(
        BankAccountNotifier.new);

// ── Employee Contracts ────────────────────────────────────────────────────────

final employeeContractRepoProvider =
    Provider((_) => EmployeeContractRepository());

class EmployeeContractNotifier
    extends AsyncNotifier<List<EmployeeContract>> {
  @override
  Future<List<EmployeeContract>> build() =>
      ref.read(employeeContractRepoProvider).getAll();

  Future<void> add(EmployeeContract contract) async {
    await ref.read(employeeContractRepoProvider).insert(contract);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(employeeContractRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(employeeContractRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final employeeContractProvider =
    AsyncNotifierProvider<EmployeeContractNotifier, List<EmployeeContract>>(
        EmployeeContractNotifier.new);

// ── Employee Loans ────────────────────────────────────────────────────────────

final employeeLoanRepoProvider =
    Provider((_) => EmployeeLoanRepository());

class EmployeeLoanNotifier extends AsyncNotifier<List<EmployeeLoan>> {
  @override
  Future<List<EmployeeLoan>> build() =>
      ref.read(employeeLoanRepoProvider).getAll();

  Future<void> add(EmployeeLoan loan) async {
    await ref.read(employeeLoanRepoProvider).insert(loan);
    ref.invalidateSelf();
  }

  Future<void> recordPayment(int id, double payment) async {
    await ref.read(employeeLoanRepoProvider).recordPayment(id, payment);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(employeeLoanRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(employeeLoanRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final employeeLoanProvider =
    AsyncNotifierProvider<EmployeeLoanNotifier, List<EmployeeLoan>>(
        EmployeeLoanNotifier.new);

// ── Expenses ──────────────────────────────────────────────────────────────────

final expenseRepoProvider = Provider((_) => ExpenseRepository());

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() =>
      ref.read(expenseRepoProvider).getAll();

  Future<void> add(Expense expense) async {
    await ref.read(expenseRepoProvider).insert(expense);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ref.read(expenseRepoProvider).updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(expenseRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
        ExpenseNotifier.new);
