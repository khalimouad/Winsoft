import '../database/database_helper.dart';
import '../models/delivery.dart';
import '../models/invoice.dart';
import '../models/return_note.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/return_note_repository.dart';
import '../repositories/sale_order_repository.dart';

/// Central document workflow service.
///
/// Manages the creation of downstream documents from upstream ones with
/// automatic reference numbering: PREFIX-YYYYMM-NNNN.
///
/// Supported chains:
///   Sale Order → Delivery (BL)
///   Delivery   → Invoice  (FAC)
///   Delivery   → Return Note (BR)  [partial quantities]
///   Invoice    → Credit Note (AV)  [handled in credit_note flow]
class DocumentWorkflowService {
  DocumentWorkflowService._();
  static final DocumentWorkflowService instance = DocumentWorkflowService._();

  final _db = DatabaseHelper.instance;
  final _deliveryRepo = DeliveryRepository();
  final _invoiceRepo = InvoiceRepository();
  final _returnNoteRepo = ReturnNoteRepository();
  final _orderRepo = SaleOrderRepository();

  // ── Reference generation ─────────────────────────────────────────────────

  /// Generates the next document reference for a given prefix and table.
  ///
  /// Format: `PREFIX-YYYYMM-NNNN`
  /// Example: BL-202604-0003
  Future<String> generateReference(String prefix, String table) async {
    final now = DateTime.now();
    final yearMonth =
        '${now.year}${now.month.toString().padLeft(2, '0')}';
    final pattern = '$prefix-$yearMonth-%';

    final rows = await _db.rawQuery(
      'SELECT reference FROM $table '
      "WHERE reference LIKE ? ORDER BY reference DESC LIMIT 1",
      [pattern],
    );

    if (rows.isEmpty) return '$prefix-$yearMonth-0001';

    final last = rows.first['reference'] as String;
    final seq = int.tryParse(last.split('-').last) ?? 0;
    return '$prefix-$yearMonth-${(seq + 1).toString().padLeft(4, '0')}';
  }

  // ── Sale Order → Delivery ────────────────────────────────────────────────

  /// Creates a Bon de Livraison from a confirmed Sale Order.
  ///
  /// - Auto-numbers the BL (prefix from settings, default BL)
  /// - Copies all order lines into delivery lines with traceability
  /// - Updates order status to 'En cours' (shipping)
  ///
  /// Returns the newly created [Delivery].
  Future<Delivery> createDeliveryFromOrder(int orderId) async {
    final order = await _orderRepo.getById(orderId);
    if (order == null) throw Exception('Commande introuvable: $orderId');

    final prefix = await _db.getSetting('bl_prefix') ?? 'BL';
    final ref = await generateReference(prefix, 'deliveries');

    final deliveryItems = order.items
        .map((oi) => DeliveryItem(
              orderItemId: oi.id,
              productId: oi.productId,
              productName: oi.productName,
              description: oi.description,
              quantity: oi.quantity,
              unitPriceHt: oi.unitPriceHt,
              tvaRate: oi.tvaRate,
            ))
        .toList();

    final delivery = Delivery(
      reference: ref,
      orderId: orderId,
      clientId: order.clientId,
      clientName: order.clientName,
      companyName: order.companyName,
      date: DateTime.now(),
      status: 'Brouillon',
    );

    final saved = await _deliveryRepo.insert(delivery, deliveryItems);

    // Update order status to shipping
    await _orderRepo.updateStatus(orderId, 'En cours');

    return saved;
  }

  // ── Delivery → Invoice ───────────────────────────────────────────────────

  /// Creates a Facture Client from a delivered Bon de Livraison.
  ///
  /// - Auto-numbers the FAC
  /// - Copies BL lines into invoice lines with traceability
  /// - Sets due date 30 days out (or from `invoice_due_days` setting)
  ///
  /// Returns the newly created [Invoice].
  Future<Invoice> createInvoiceFromDelivery(int deliveryId) async {
    final delivery = await _deliveryRepo.getById(deliveryId);
    if (delivery == null) throw Exception('Livraison introuvable: $deliveryId');

    final prefix = await _db.getSetting('invoice_prefix') ?? 'FAC';
    final ref = await generateReference(prefix, 'invoices');
    final dueDays =
        int.tryParse(await _db.getSetting('invoice_due_days') ?? '30') ?? 30;

    final now = DateTime.now();
    final dueDate = now.add(Duration(days: dueDays));

    final invoiceItems = delivery.items
        .map((di) => InvoiceItem(
              productId: di.productId,
              productName: di.productName,
              description: di.description,
              quantity: di.quantity,
              unitPriceHt: di.unitPriceHt,
              tvaRate: di.tvaRate,
            ))
        .toList();

    final invoice = Invoice(
      reference: ref,
      clientId: delivery.clientId,
      clientName: delivery.clientName,
      companyName: delivery.companyName,
      orderId: delivery.orderId,
      issuedDate: now,
      dueDate: dueDate,
      status: 'Brouillon',
    );

    final saved = await _invoiceRepo.insert(invoice, invoiceItems);

    // Update delivery status to invoiced
    await _deliveryRepo.updateStatus(deliveryId, 'Livré');

    return saved;
  }

  // ── Delivery → Return Note ────────────────────────────────────────────────

  /// Creates a Bon de Retour from a delivered Bon de Livraison.
  ///
  /// [items] contains the items to return — caller sets the quantity to
  /// return for each line (may be partial).
  ///
  /// Returns the newly created [ReturnNote].
  Future<ReturnNote> createReturnNoteFromDelivery(
    int deliveryId,
    List<ReturnNoteItem> items, {
    String reason = '',
  }) async {
    final delivery = await _deliveryRepo.getById(deliveryId);
    if (delivery == null) throw Exception('Livraison introuvable: $deliveryId');

    final prefix = await _db.getSetting('br_prefix') ?? 'BR';
    final ref = await generateReference(prefix, 'return_notes');

    final returnNote = ReturnNote(
      reference: ref,
      deliveryId: deliveryId,
      clientId: delivery.clientId,
      clientName: delivery.clientName,
      companyName: delivery.companyName,
      date: DateTime.now(),
      reason: reason,
      status: 'Brouillon',
    );

    return _returnNoteRepo.insert(returnNote, items);
  }

  // ── Sale Order → Invoice (direct, no BL) ────────────────────────────────

  /// Creates a Facture directly from a Sale Order (skipping BL step).
  Future<Invoice> createInvoiceFromOrder(int orderId) async {
    final order = await _orderRepo.getById(orderId);
    if (order == null) throw Exception('Commande introuvable: $orderId');

    final prefix = await _db.getSetting('invoice_prefix') ?? 'FAC';
    final ref = await generateReference(prefix, 'invoices');
    final dueDays =
        int.tryParse(await _db.getSetting('invoice_due_days') ?? '30') ?? 30;

    final now = DateTime.now();
    final dueDate = now.add(Duration(days: dueDays));

    final invoiceItems = order.items
        .map((oi) => InvoiceItem(
              productId: oi.productId,
              productName: oi.productName,
              description: oi.description,
              quantity: oi.quantity,
              unitPriceHt: oi.unitPriceHt,
              tvaRate: oi.tvaRate,
            ))
        .toList();

    final invoice = Invoice(
      reference: ref,
      clientId: order.clientId,
      clientName: order.clientName,
      companyName: order.companyName,
      orderId: orderId,
      issuedDate: now,
      dueDate: dueDate,
      status: 'Brouillon',
    );

    final saved = await _invoiceRepo.insert(invoice, invoiceItems);
    await _orderRepo.updateStatus(orderId, 'Terminée');
    return saved;
  }
}
