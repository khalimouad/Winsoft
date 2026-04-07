class SaleOrderItem {
  final int? id;
  final int? orderId;
  final int? productId;
  final String? productName; // joined
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;

  const SaleOrderItem({
    this.id,
    this.orderId,
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

  factory SaleOrderItem.fromMap(Map<String, dynamic> m) => SaleOrderItem(
        id: m['id'] as int?,
        orderId: m['order_id'] as int?,
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20.0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (orderId != null) 'order_id': orderId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
      };
}

class SaleOrder {
  final int? id;
  final String reference;
  final int clientId;
  final String? clientName;   // joined
  final String? companyName;  // joined
  final DateTime date;
  final String status;
  final String? notes;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final List<SaleOrderItem> items;

  const SaleOrder({
    this.id,
    required this.reference,
    required this.clientId,
    this.clientName,
    this.companyName,
    required this.date,
    this.status = 'En attente',
    this.notes,
    this.totalHt = 0,
    this.totalTva = 0,
    this.totalTtc = 0,
    this.items = const [],
  });

  factory SaleOrder.fromMap(Map<String, dynamic> m,
      {List<SaleOrderItem> items = const []}) =>
      SaleOrder(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        clientId: m['client_id'] as int,
        clientName: m['client_name'] as String?,
        companyName: m['company_name'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        status: m['status'] as String? ?? 'En attente',
        notes: m['notes'] as String?,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'client_id': clientId,
        'date': date.millisecondsSinceEpoch,
        'status': status,
        'notes': notes,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
      };

  SaleOrder copyWith({
    int? id,
    String? reference,
    int? clientId,
    String? clientName,
    String? companyName,
    DateTime? date,
    String? status,
    String? notes,
    double? totalHt,
    double? totalTva,
    double? totalTtc,
    List<SaleOrderItem>? items,
  }) =>
      SaleOrder(
        id: id ?? this.id,
        reference: reference ?? this.reference,
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
