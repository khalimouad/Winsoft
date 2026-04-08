class RecurringTemplate {
  const RecurringTemplate({
    this.id,
    required this.name,
    required this.clientId,
    required this.frequency,
    required this.nextDueDate,
    this.totalHt = 0,
    this.totalTva = 0,
    this.totalTtc = 0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.clientName,
    this.items = const [],
  });

  final int? id;
  final String name;
  final int clientId;
  /// 'monthly' | 'quarterly' | 'yearly'
  final String frequency;
  final int nextDueDate;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final String? notes;
  final bool isActive;
  final int createdAt;
  final String? clientName;
  final List<RecurringItem> items;

  static const List<String> frequencies = ['monthly', 'quarterly', 'yearly'];
  static const Map<String, String> frequencyLabels = {
    'monthly': 'Mensuel',
    'quarterly': 'Trimestriel',
    'yearly': 'Annuel',
  };

  /// Compute next due date after [from].
  int nextAfter(int fromMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(fromMs);
    switch (frequency) {
      case 'quarterly':
        return DateTime(dt.year, dt.month + 3, dt.day)
            .millisecondsSinceEpoch;
      case 'yearly':
        return DateTime(dt.year + 1, dt.month, dt.day)
            .millisecondsSinceEpoch;
      default: // monthly
        return DateTime(dt.year, dt.month + 1, dt.day)
            .millisecondsSinceEpoch;
    }
  }

  factory RecurringTemplate.fromMap(Map<String, dynamic> m,
          {List<RecurringItem> items = const []}) =>
      RecurringTemplate(
        id: m['id'] as int?,
        name: m['name'] as String,
        clientId: m['client_id'] as int,
        frequency: m['frequency'] as String? ?? 'monthly',
        nextDueDate: m['next_due_date'] as int,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        notes: m['notes'] as String?,
        isActive: (m['is_active'] as int?) == 1,
        createdAt: m['created_at'] as int,
        clientName: m['client_name'] as String?,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'client_id': clientId,
        'frequency': frequency,
        'next_due_date': nextDueDate,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
        'notes': notes,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };
}

class RecurringItem {
  const RecurringItem({
    this.id,
    required this.templateId,
    required this.description,
    required this.quantity,
    required this.unitPriceHt,
    this.tvaRate = 20,
  });

  final int? id;
  final int templateId;
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;

  factory RecurringItem.fromMap(Map<String, dynamic> m) => RecurringItem(
        id: m['id'] as int?,
        templateId: m['template_id'] as int,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'template_id': templateId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
      };
}
