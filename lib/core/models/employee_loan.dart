class EmployeeLoan {
  final int? id;
  final int employeeId;
  final String? employeeName;
  final double amount;
  final double monthlyDeduction;
  final int startDate;
  final String status; // En cours / Remboursé / Annulé
  final String? reason;
  final double amountPaid;

  const EmployeeLoan({
    this.id,
    required this.employeeId,
    this.employeeName,
    required this.amount,
    required this.monthlyDeduction,
    required this.startDate,
    this.status = 'En cours',
    this.reason,
    this.amountPaid = 0,
  });

  double get amountRemaining => amount - amountPaid;
  int get monthsRemaining =>
      monthlyDeduction > 0
          ? (amountRemaining / monthlyDeduction).ceil()
          : 0;

  factory EmployeeLoan.fromMap(Map<String, dynamic> m) => EmployeeLoan(
        id: m['id'] as int?,
        employeeId: m['employee_id'] as int,
        employeeName: m['employee_name'] as String?,
        amount: (m['amount'] as num).toDouble(),
        monthlyDeduction: (m['monthly_deduction'] as num).toDouble(),
        startDate: m['start_date'] as int,
        status: m['status'] as String? ?? 'En cours',
        reason: m['reason'] as String?,
        amountPaid: (m['amount_paid'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'amount': amount,
        'monthly_deduction': monthlyDeduction,
        'start_date': startDate,
        'status': status,
        'reason': reason,
        'amount_paid': amountPaid,
      };
}
