import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/sale_order.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';
import '../models/employee.dart';
import '../models/payroll_slip.dart';
import '../models/journal_entry.dart';
import '../models/manufacturing_bom.dart';
import '../repositories/company_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_order_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/purchase_order_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/accounting_repository.dart';
import '../repositories/manufacturing_repository.dart';
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

  const DashboardStats({
    required this.totalRevenue,
    required this.pendingCount,
    required this.pendingAmount,
    required this.clientCount,
    required this.orderCount,
    required this.invoiceStatusCounts,
    required this.revenueByMonth,
  });
}

final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final invoiceRepo = ref.read(invoiceRepoProvider);
  final clientRepo = ref.read(clientRepoProvider);
  final orderRepo = ref.read(saleOrderRepoProvider);

  final results = await Future.wait([
    invoiceRepo.totalRevenue(),
    invoiceRepo.pendingCount(),
    invoiceRepo.pendingAmount(),
    invoiceRepo.statusCounts(),
    invoiceRepo.revenueByMonth(6),
  ]);

  final clients = await clientRepo.getAll();
  final orders = await orderRepo.getAll();

  return DashboardStats(
    totalRevenue: results[0] as double,
    pendingCount: results[1] as int,
    pendingAmount: results[2] as double,
    clientCount: clients.length,
    orderCount: orders.length,
    invoiceStatusCounts: results[3] as Map<String, int>,
    revenueByMonth: results[4] as List<Map<String, dynamic>>,
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
