class ReturnNoteItem {
  final int? id;
  final int? returnNoteId;
  final int? deliveryItemId; // traceability back to delivery_items
  final int? productId;
  final String? productName; // joined
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;

  const ReturnNoteItem({
    this.id,
    this.returnNoteId,
    this.deliveryItemId,
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

  factory ReturnNoteItem.fromMap(Map<String, dynamic> m) => ReturnNoteItem(
        id: m['id'] as int?,
        returnNoteId: m['return_note_id'] as int?,
        deliveryItemId: m['delivery_item_id'] as int?,
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20.0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (returnNoteId != null) 'return_note_id': returnNoteId,
        'delivery_item_id': deliveryItemId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
      };

  ReturnNoteItem copyWith({
    int? id,
    int? returnNoteId,
    int? deliveryItemId,
    int? productId,
    String? productName,
    String? description,
    double? quantity,
    double? unitPriceHt,
    double? tvaRate,
  }) =>
      ReturnNoteItem(
        id: id ?? this.id,
        returnNoteId: returnNoteId ?? this.returnNoteId,
        deliveryItemId: deliveryItemId ?? this.deliveryItemId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unitPriceHt: unitPriceHt ?? this.unitPriceHt,
        tvaRate: tvaRate ?? this.tvaRate,
      );
}

class ReturnNote {
  final int? id;
  final String reference;   // BR-YYYYMM-NNNN
  final int? deliveryId;    // FK → deliveries
  final int clientId;
  final String? clientName;  // joined
  final String? companyName; // joined
  final DateTime date;
  final String reason;
  final String status; // Brouillon | Confirmé | Traité | Annulé
  final String? notes;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final List<ReturnNoteItem> items;

  const ReturnNote({
    this.id,
    required this.reference,
    this.deliveryId,
    required this.clientId,
    this.clientName,
    this.companyName,
    required this.date,
    this.reason = '',
    this.status = 'Brouillon',
    this.notes,
    this.totalHt = 0,
    this.totalTva = 0,
    this.totalTtc = 0,
    this.items = const [],
  });

  factory ReturnNote.fromMap(Map<String, dynamic> m,
      {List<ReturnNoteItem> items = const []}) =>
      ReturnNote(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        deliveryId: m['delivery_id'] as int?,
        clientId: m['client_id'] as int,
        clientName: m['client_name'] as String?,
        companyName: m['company_name'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        reason: m['reason'] as String? ?? '',
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
        'delivery_id': deliveryId,
        'client_id': clientId,
        'date': date.millisecondsSinceEpoch,
        'reason': reason,
        'status': status,
        'notes': notes,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
      };

  ReturnNote copyWith({
    int? id,
    String? reference,
    int? deliveryId,
    int? clientId,
    String? clientName,
    String? companyName,
    DateTime? date,
    String? reason,
    String? status,
    String? notes,
    double? totalHt,
    double? totalTva,
    double? totalTtc,
    List<ReturnNoteItem>? items,
  }) =>
      ReturnNote(
        id: id ?? this.id,
        reference: reference ?? this.reference,
        deliveryId: deliveryId ?? this.deliveryId,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        companyName: companyName ?? this.companyName,
        date: date ?? this.date,
        reason: reason ?? this.reason,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        totalHt: totalHt ?? this.totalHt,
        totalTva: totalTva ?? this.totalTva,
        totalTtc: totalTtc ?? this.totalTtc,
        items: items ?? this.items,
      );
}
