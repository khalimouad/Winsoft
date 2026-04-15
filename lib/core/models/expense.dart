class Expense {
  final int? id;
  final int? employeeId;
  final String? employeeName;
  final String category;
  final String description;
  final double amount;
  final int date;
  final String status; // Brouillon / Soumise / Approuvée / Remboursée / Rejetée
  final String? receiptRef;
  final String? notes;

  const Expense({
    this.id,
    this.employeeId,
    this.employeeName,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.status = 'Brouillon',
    this.receiptRef,
    this.notes,
  });

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as int?,
        employeeId: m['employee_id'] as int?,
        employeeName: m['employee_name'] as String?,
        category: m['category'] as String,
        description: m['description'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: m['date'] as int,
        status: m['status'] as String? ?? 'Brouillon',
        receiptRef: m['receipt_ref'] as String?,
        notes: m['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date,
        'status': status,
        'receipt_ref': receiptRef,
        'notes': notes,
      };

  Expense copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    String? category,
    String? description,
    double? amount,
    int? date,
    String? status,
    String? receiptRef,
    String? notes,
  }) =>
      Expense(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        employeeName: employeeName ?? this.employeeName,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        status: status ?? this.status,
        receiptRef: receiptRef ?? this.receiptRef,
        notes: notes ?? this.notes,
      );
}
