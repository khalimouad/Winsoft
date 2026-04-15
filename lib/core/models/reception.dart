class ReceptionItem {
  final int? id;
  final int? receptionId;
  final int? poItemId;
  final int? productId;
  final String? productName;
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;

  const ReceptionItem({
    this.id,
    this.receptionId,
    this.poItemId,
    this.productId,
    this.productName,
    required this.description,
    required this.quantity,
    required this.unitPriceHt,
    this.tvaRate = 20.0,
  });

  double get totalHt => quantity * unitPriceHt;
  double get totalTva => totalHt * (tvaRate / 100);
  double get totalTtc => totalHt + totalTva;

  factory ReceptionItem.fromMap(Map<String, dynamic> m) => ReceptionItem(
        id: m['id'] as int?,
        receptionId: m['reception_id'] as int?,
        poItemId: m['po_item_id'] as int?,
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20.0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (receptionId != null) 'reception_id': receptionId,
        'po_item_id': poItemId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
      };
}

class Reception {
  final int? id;
  final String reference;
  final int? purchaseOrderId;
  final int supplierId;
  final String? supplierName;
  final int date;
  final String status;
  final String? notes;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final List<ReceptionItem> items;

  const Reception({
    this.id,
    required this.reference,
    this.purchaseOrderId,
    required this.supplierId,
    this.supplierName,
    required this.date,
    this.status = 'Brouillon',
    this.notes,
    this.totalHt = 0,
    this.totalTva = 0,
    this.totalTtc = 0,
    this.items = const [],
  });

  factory Reception.fromMap(Map<String, dynamic> m,
      {List<ReceptionItem> items = const []}) =>
      Reception(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        purchaseOrderId: m['purchase_order_id'] as int?,
        supplierId: m['supplier_id'] as int,
        supplierName: m['supplier_name'] as String?,
        date: m['date'] as int,
        status: m['status'] as String? ?? 'Brouillon',
        notes: m['notes'] as String?,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'purchase_order_id': purchaseOrderId,
        'supplier_id': supplierId,
        'date': date,
        'status': status,
        'notes': notes,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
      };

  Reception copyWith({
    int? id,
    String? reference,
    int? purchaseOrderId,
    int? supplierId,
    String? supplierName,
    int? date,
    String? status,
    String? notes,
    double? totalHt,
    double? totalTva,
    double? totalTtc,
    List<ReceptionItem>? items,
  }) =>
      Reception(
        id: id ?? this.id,
        reference: reference ?? this.reference,
        purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
        supplierId: supplierId ?? this.supplierId,
        supplierName: supplierName ?? this.supplierName,
        date: date ?? this.date,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        totalHt: totalHt ?? this.totalHt,
        totalTva: totalTva ?? this.totalTva,
        totalTtc: totalTtc ?? this.totalTtc,
        items: items ?? this.items,
      );
}
