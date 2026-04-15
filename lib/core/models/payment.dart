class PaymentReceived {
  final int? id;
  final int invoiceId;
  final String? invoiceRef;  // joined
  final String? clientName;  // joined
  final double amount;
  final String method;  // Espèces | Chèque | Virement | Carte
  final DateTime paymentDate;
  final String? bankRef;
  final String? notes;
  final DateTime? createdAt;

  const PaymentReceived({
    this.id,
    required this.invoiceId,
    this.invoiceRef,
    this.clientName,
    required this.amount,
    this.method = 'Espèces',
    required this.paymentDate,
    this.bankRef,
    this.notes,
    this.createdAt,
  });

  factory PaymentReceived.fromMap(Map<String, dynamic> m) => PaymentReceived(
        id: m['id'] as int?,
        invoiceId: m['invoice_id'] as int,
        invoiceRef: m['invoice_ref'] as String?,
        clientName: m['client_name'] as String?,
        amount: (m['amount'] as num).toDouble(),
        method: m['method'] as String? ?? 'Espèces',
        paymentDate:
            DateTime.fromMillisecondsSinceEpoch(m['payment_date'] as int),
        bankRef: m['bank_ref'] as String?,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'invoice_id': invoiceId,
        'amount': amount,
        'method': method,
        'payment_date': paymentDate.millisecondsSinceEpoch,
        'bank_ref': bankRef,
        'notes': notes,
        'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      };

  PaymentReceived copyWith({
    int? id,
    int? invoiceId,
    String? invoiceRef,
    String? clientName,
    double? amount,
    String? method,
    DateTime? paymentDate,
    String? bankRef,
    String? notes,
  }) =>
      PaymentReceived(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        invoiceRef: invoiceRef ?? this.invoiceRef,
        clientName: clientName ?? this.clientName,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        paymentDate: paymentDate ?? this.paymentDate,
        bankRef: bankRef ?? this.bankRef,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}

class PaymentSent {
  final int? id;
  final int supplierInvoiceId;
  final String? supplierInvoiceRef;  // joined
  final String? supplierName;        // joined
  final double amount;
  final String method;  // Espèces | Chèque | Virement | Carte
  final DateTime paymentDate;
  final String? bankRef;
  final String? notes;
  final DateTime? createdAt;

  const PaymentSent({
    this.id,
    required this.supplierInvoiceId,
    this.supplierInvoiceRef,
    this.supplierName,
    required this.amount,
    this.method = 'Virement',
    required this.paymentDate,
    this.bankRef,
    this.notes,
    this.createdAt,
  });

  factory PaymentSent.fromMap(Map<String, dynamic> m) => PaymentSent(
        id: m['id'] as int?,
        supplierInvoiceId: m['supplier_invoice_id'] as int,
        supplierInvoiceRef: m['supplier_invoice_ref'] as String?,
        supplierName: m['supplier_name'] as String?,
        amount: (m['amount'] as num).toDouble(),
        method: m['method'] as String? ?? 'Virement',
        paymentDate:
            DateTime.fromMillisecondsSinceEpoch(m['payment_date'] as int),
        bankRef: m['bank_ref'] as String?,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'supplier_invoice_id': supplierInvoiceId,
        'amount': amount,
        'method': method,
        'payment_date': paymentDate.millisecondsSinceEpoch,
        'bank_ref': bankRef,
        'notes': notes,
        'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      };

  PaymentSent copyWith({
    int? id,
    int? supplierInvoiceId,
    String? supplierInvoiceRef,
    String? supplierName,
    double? amount,
    String? method,
    DateTime? paymentDate,
    String? bankRef,
    String? notes,
  }) =>
      PaymentSent(
        id: id ?? this.id,
        supplierInvoiceId: supplierInvoiceId ?? this.supplierInvoiceId,
        supplierInvoiceRef: supplierInvoiceRef ?? this.supplierInvoiceRef,
        supplierName: supplierName ?? this.supplierName,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        paymentDate: paymentDate ?? this.paymentDate,
        bankRef: bankRef ?? this.bankRef,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
