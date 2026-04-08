class PurchaseOrderItem {
  const PurchaseOrderItem({
    this.id,
    required this.orderId,
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPriceHt,
    this.tvaRate = 20,
    this.receivedQty = 0,
  });

  final int? id;
  final int orderId;
  final int? productId;
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;
  final double receivedQty;

  double get lineHt => quantity * unitPriceHt;
  double get lineTva => lineHt * tvaRate / 100;
  double get lineTtc => lineHt + lineTva;

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> m) =>
      PurchaseOrderItem(
        id: m['id'] as int?,
        orderId: m['order_id'] as int,
        productId: m['product_id'] as int?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20,
        receivedQty: (m['received_qty'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'order_id': orderId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
        'received_qty': receivedQty,
      };
}

class PurchaseOrder {
  const PurchaseOrder({
    this.id,
    required this.reference,
    required this.supplierId,
    required this.date,
    this.status = 'Brouillon',
    this.notes,
    required this.totalHt,
    required this.totalTva,
    required this.totalTtc,
    this.supplierName,
    this.items = const [],
  });

  final int? id;
  final String reference;
  final int supplierId;
  final int date;
  final String status;
  final String? notes;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  // Joined fields
  final String? supplierName;
  final List<PurchaseOrderItem> items;

  static const List<String> statuses = [
    'Brouillon', 'Envoyé', 'Reçu', 'Partiel', 'Annulé',
  ];

  factory PurchaseOrder.fromMap(Map<String, dynamic> m,
          {List<PurchaseOrderItem> items = const []}) =>
      PurchaseOrder(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        supplierId: m['supplier_id'] as int,
        date: m['date'] as int,
        status: m['status'] as String? ?? 'Brouillon',
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
        'date': date,
        'status': status,
        'notes': notes,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
      };
}
