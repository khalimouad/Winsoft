class EmployeeContract {
  final int? id;
  final int employeeId;
  final String? employeeName;
  final String contractType; // CDI / CDD / Intérim / Stage
  final int startDate;
  final int? endDate;
  final double grossSalary;
  final String? position;
  final String? department;
  final String status; // Actif / Expiré / Résilié
  final String? notes;

  const EmployeeContract({
    this.id,
    required this.employeeId,
    this.employeeName,
    required this.contractType,
    required this.startDate,
    this.endDate,
    required this.grossSalary,
    this.position,
    this.department,
    this.status = 'Actif',
    this.notes,
  });

  bool get isExpired =>
      endDate != null &&
      DateTime.now().millisecondsSinceEpoch > endDate!;

  factory EmployeeContract.fromMap(Map<String, dynamic> m) => EmployeeContract(
        id: m['id'] as int?,
        employeeId: m['employee_id'] as int,
        employeeName: m['employee_name'] as String?,
        contractType: m['contract_type'] as String? ?? 'CDI',
        startDate: m['start_date'] as int,
        endDate: m['end_date'] as int?,
        grossSalary: (m['gross_salary'] as num).toDouble(),
        position: m['position'] as String?,
        department: m['department'] as String?,
        status: m['status'] as String? ?? 'Actif',
        notes: m['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'contract_type': contractType,
        'start_date': startDate,
        'end_date': endDate,
        'gross_salary': grossSalary,
        'position': position,
        'department': department,
        'status': status,
        'notes': notes,
      };
}
