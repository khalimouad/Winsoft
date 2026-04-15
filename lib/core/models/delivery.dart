class DeliveryItem {
  final int? id;
  final int? deliveryId;
  final int? orderItemId; // traceability back to sale_order_items
  final int? productId;
  final String? productName; // joined
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;

  const DeliveryItem({
    this.id,
    this.deliveryId,
    this.orderItemId,
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

  factory DeliveryItem.fromMap(Map<String, dynamic> m) => DeliveryItem(
        id: m['id'] as int?,
        deliveryId: m['delivery_id'] as int?,
        orderItemId: m['order_item_id'] as int?,
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20.0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (deliveryId != null) 'delivery_id': deliveryId,
        'order_item_id': orderItemId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
      };

  DeliveryItem copyWith({
    int? id,
    int? deliveryId,
    int? orderItemId,
    int? productId,
    String? productName,
    String? description,
    double? quantity,
    double? unitPriceHt,
    double? tvaRate,
  }) =>
      DeliveryItem(
        id: id ?? this.id,
        deliveryId: deliveryId ?? this.deliveryId,
        orderItemId: orderItemId ?? this.orderItemId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unitPriceHt: unitPriceHt ?? this.unitPriceHt,
        tvaRate: tvaRate ?? this.tvaRate,
      );
}

class Delivery {
  final int? id;
  final String reference; // BL-YYYYMM-NNNN
  final int? orderId;     // FK → sale_orders
  final int clientId;
  final String? clientName;  // joined
  final String? companyName; // joined
  final DateTime date;
  final String status;   // Brouillon | Confirmé | Livré | Annulé
  final String? notes;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final List<DeliveryItem> items;

  const Delivery({
    this.id,
    required this.reference,
    this.orderId,
    required this.clientId,
    this.clientName,
    this.companyName,
    required this.date,
    this.status = 'Brouillon',
    this.notes,
    this.totalHt = 0,
    this.totalTva = 0,
    this.totalTtc = 0,
    this.items = const [],
  });

  factory Delivery.fromMap(Map<String, dynamic> m,
      {List<DeliveryItem> items = const []}) =>
      Delivery(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        orderId: m['order_id'] as int?,
        clientId: m['client_id'] as int,
        clientName: m['client_name'] as String?,
        companyName: m['company_name'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
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
        'order_id': orderId,
        'client_id': clientId,
        'date': date.millisecondsSinceEpoch,
        'status': status,
        'notes': notes,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
      };

  Delivery copyWith({
    int? id,
    String? reference,
    int? orderId,
    int? clientId,
    String? clientName,
    String? companyName,
    DateTime? date,
    String? status,
    String? notes,
    double? totalHt,
    double? totalTva,
    double? totalTtc,
    List<DeliveryItem>? items,
  }) =>
      Delivery(
        id: id ?? this.id,
        reference: reference ?? this.reference,
        orderId: orderId ?? this.orderId,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        companyName: companyName ?? this.companyName,
        date: date ?? this.date,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        totalHt: totalHt ?? this.totalHt,
        totalTva: totalTva ?? this.totalTva,
        totalTtc: totalTtc ?? this.totalTtc,
        items: items ?? this.items,
      );
}
