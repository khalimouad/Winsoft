class FiscalYear {
  final int? id;
  final String name;
  final int startDate;
  final int endDate;
  final String status; // Ouverte / Clôturée / Verrouillée

  const FiscalYear({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = 'Ouverte',
  });

  bool get isOpen => status == 'Ouverte';
  bool get isClosed => status == 'Clôturée' || status == 'Verrouillée';

  factory FiscalYear.fromMap(Map<String, dynamic> m) => FiscalYear(
        id: m['id'] as int?,
        name: m['name'] as String,
        startDate: m['start_date'] as int,
        endDate: m['end_date'] as int,
        status: m['status'] as String? ?? 'Ouverte',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
      };

  FiscalYear copyWith({
    int? id,
    String? name,
    int? startDate,
    int? endDate,
    String? status,
  }) =>
      FiscalYear(
        id: id ?? this.id,
        name: name ?? this.name,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
      );
}
