class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? productId;
  final String? productName; // joined
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;

  const InvoiceItem({
    this.id,
    this.invoiceId,
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

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
        id: m['id'] as int?,
        invoiceId: m['invoice_id'] as int?,
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String?,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20.0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (invoiceId != null) 'invoice_id': invoiceId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
      };
}

class Invoice {
  final int? id;
  final String reference;
  final int clientId;
  final String? clientName;   // joined
  final String? companyName;  // joined
  final int? orderId;
  final DateTime issuedDate;
  final DateTime dueDate;
  final String status;
  final String? notes;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final double amountPaid;    // sum of payments_received for this invoice
  final List<InvoiceItem> items;

  const Invoice({
    this.id,
    required this.reference,
    required this.clientId,
    this.clientName,
    this.companyName,
    this.orderId,
    required this.issuedDate,
    required this.dueDate,
    this.status = 'Brouillon',
    this.notes,
    this.totalHt = 0,
    this.totalTva = 0,
    this.totalTtc = 0,
    this.amountPaid = 0,
    this.items = const [],
  });

  double get amountDue => totalTtc - amountPaid;
  bool get isFullyPaid => amountDue <= 0.01;

  bool get isOverdue =>
      status != 'Payée' &&
      status != 'Brouillon' &&
      dueDate.isBefore(DateTime.now());

  factory Invoice.fromMap(Map<String, dynamic> m,
      {List<InvoiceItem> items = const []}) =>
      Invoice(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        clientId: m['client_id'] as int,
        clientName: m['client_name'] as String?,
        companyName: m['company_name'] as String?,
        orderId: m['order_id'] as int?,
        issuedDate:
            DateTime.fromMillisecondsSinceEpoch(m['issued_date'] as int),
        dueDate: DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int),
        status: m['status'] as String? ?? 'Brouillon',
        notes: m['notes'] as String?,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        amountPaid: (m['amount_paid'] as num?)?.toDouble() ?? 0,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'client_id': clientId,
        'order_id': orderId,
        'issued_date': issuedDate.millisecondsSinceEpoch,
        'due_date': dueDate.millisecondsSinceEpoch,
        'status': status,
        'notes': notes,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
      };

  Invoice copyWith({
    int? id,
    String? reference,
    int? clientId,
    String? clientName,
    String? companyName,
    int? orderId,
    DateTime? issuedDate,
    DateTime? dueDate,
    String? status,
    String? notes,
    double? totalHt,
    double? totalTva,
    double? totalTtc,
    double? amountPaid,
    List<InvoiceItem>? items,
  }) =>
      Invoice(
        id: id ?? this.id,
        reference: reference ?? this.reference,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        companyName: companyName ?? this.companyName,
        orderId: orderId ?? this.orderId,
        issuedDate: issuedDate ?? this.issuedDate,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        totalHt: totalHt ?? this.totalHt,
        totalTva: totalTva ?? this.totalTva,
        totalTtc: totalTtc ?? this.totalTtc,
        amountPaid: amountPaid ?? this.amountPaid,
        items: items ?? this.items,
      );
}
