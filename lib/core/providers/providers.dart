import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/sale_order.dart';
import '../models/invoice.dart';
import '../repositories/company_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_order_repository.dart';
import '../repositories/invoice_repository.dart';
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
