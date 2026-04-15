class PurchaseRequestItem {
  final int? id;
  final int? requestId;
  final int? productId;
  final String? productName;
  final String description;
  final double quantity;
  final double estimatedPrice;

  const PurchaseRequestItem({
    this.id,
    this.requestId,
    this.productId,
    this.productName,
    required this.description,
    required this.quantity,
    this.estimatedPrice = 0,
  });

  double get totalEstimated => quantity * estimatedPrice;

  factory PurchaseRequestItem.fromMap(Map<String, dynamic> m) =>
      PurchaseRequestItem(
        id: m['id'] as int?,
        requestId: m['request_id'] as int?,
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        estimatedPrice: (m['estimated_price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (requestId != null) 'request_id': requestId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'estimated_price': estimatedPrice,
      };
}

class PurchaseRequest {
  final int? id;
  final String reference;
  final String? requestedBy;
  final String? department;
  final int date;
  final String status;
  final String? notes;
  final List<PurchaseRequestItem> items;

  const PurchaseRequest({
    this.id,
    required this.reference,
    this.requestedBy,
    this.department,
    required this.date,
    this.status = 'Brouillon',
    this.notes,
    this.items = const [],
  });

  double get totalEstimated =>
      items.fold(0, (sum, i) => sum + i.totalEstimated);

  factory PurchaseRequest.fromMap(Map<String, dynamic> m,
      {List<PurchaseRequestItem> items = const []}) =>
      PurchaseRequest(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        requestedBy: m['requested_by'] as String?,
        department: m['department'] as String?,
        date: m['date'] as int,
        status: m['status'] as String? ?? 'Brouillon',
        notes: m['notes'] as String?,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'requested_by': requestedBy,
        'department': department,
        'date': date,
        'status': status,
        'notes': notes,
      };

  PurchaseRequest copyWith({
    int? id,
    String? reference,
    String? requestedBy,
    String? department,
    int? date,
    String? status,
    String? notes,
    List<PurchaseRequestItem>? items,
  }) =>
      PurchaseRequest(
        id: id ?? this.id,
        reference: reference ?? this.reference,
        requestedBy: requestedBy ?? this.requestedBy,
        department: department ?? this.department,
        date: date ?? this.date,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        items: items ?? this.items,
      );
}
