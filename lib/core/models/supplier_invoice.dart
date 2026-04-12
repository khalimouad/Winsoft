class SupplierInvoice {
  const SupplierInvoice({
    this.id,
    required this.reference,
    required this.supplierId,
    this.orderId,
    required this.issuedDate,
    required this.dueDate,
    this.status = 'Reçue',
    this.notes,
    required this.totalHt,
    required this.totalTva,
    required this.totalTtc,
    // Joined
    this.supplierName,
    this.items = const [],
  });

  final int? id;
  final String reference;
  final int supplierId;
  final int? orderId;
  final int issuedDate;
  final int dueDate;
  final String status;
  final String? notes;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final String? supplierName;
  final List<SupplierInvoiceItem> items;

  bool get isOverdue =>
      status != 'Payée' &&
      status != 'Annulée' &&
      DateTime.now().millisecondsSinceEpoch > dueDate;

  factory SupplierInvoice.fromMap(Map<String, dynamic> m,
          {List<SupplierInvoiceItem> items = const []}) =>
      SupplierInvoice(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        supplierId: m['supplier_id'] as int,
        orderId: m['order_id'] as int?,
        issuedDate: m['issued_date'] as int,
        dueDate: m['due_date'] as int,
        status: m['status'] as String? ?? 'Reçue',
        notes: m['notes'] as String?,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        supplierName: m['supplier_name'] as String?,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'supplier_id': supplierId,
        'order_id': orderId,
        'issued_date': issuedDate,
        'due_date': dueDate,
        'status': status,
        'notes': notes,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
      };
}

class SupplierInvoiceItem {
  const SupplierInvoiceItem({
    this.id,
    required this.invoiceId,
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPriceHt,
    this.tvaRate = 20,
  });

  final int? id;
  final int invoiceId;
  final int? productId;
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;

  double get lineHt => quantity * unitPriceHt;
  double get lineTtc => lineHt * (1 + tvaRate / 100);

  factory SupplierInvoiceItem.fromMap(Map<String, dynamic> m) =>
      SupplierInvoiceItem(
        id: m['id'] as int?,
        invoiceId: m['invoice_id'] as int,
        productId: m['product_id'] as int?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'invoice_id': invoiceId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
      };
}
