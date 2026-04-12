class CreditNote {
  const CreditNote({
    this.id,
    required this.reference,
    required this.clientId,
    required this.invoiceId,
    required this.issueDate,
    required this.totalHt,
    required this.totalTva,
    required this.totalTtc,
    this.reason,
    this.status = 'Brouillon',
    required this.createdAt,
    // Joined
    this.clientName,
    this.invoiceReference,
  });

  final int? id;
  final String reference;
  final int clientId;
  final int invoiceId;
  final int issueDate;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final String? reason;
  final String status;
  final int createdAt;
  final String? clientName;
  final String? invoiceReference;

  factory CreditNote.fromMap(Map<String, dynamic> m) => CreditNote(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        clientId: m['client_id'] as int,
        invoiceId: m['invoice_id'] as int,
        issueDate: m['issue_date'] as int,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        reason: m['reason'] as String?,
        status: m['status'] as String? ?? 'Brouillon',
        createdAt: m['created_at'] as int,
        clientName: m['client_name'] as String?,
        invoiceReference: m['invoice_reference'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'client_id': clientId,
        'invoice_id': invoiceId,
        'issue_date': issueDate,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
        'reason': reason,
        'status': status,
        'created_at': createdAt,
      };
}
