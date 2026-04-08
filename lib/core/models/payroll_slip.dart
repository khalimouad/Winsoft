class PayrollSlip {
  const PayrollSlip({
    this.id,
    required this.employeeId,
    required this.periodYear,
    required this.periodMonth,
    required this.salaryBrut,
    required this.cnssEmployee,
    required this.amoEmployee,
    required this.igr,
    this.otherDeductions = 0,
    required this.salaryNet,
    required this.cnssEmployer,
    required this.amoEmployer,
    this.status = 'Brouillon',
    this.notes,
    required this.createdAt,
    // Joined
    this.employeeName,
    this.employeeCin,
    this.employeePosition,
  });

  final int? id;
  final int employeeId;
  final int periodYear;
  final int periodMonth;
  final double salaryBrut;
  final double cnssEmployee;
  final double amoEmployee;
  final double igr;
  final double otherDeductions;
  final double salaryNet;
  final double cnssEmployer;
  final double amoEmployer;
  final String status;
  final String? notes;
  final int createdAt;
  // Joined
  final String? employeeName;
  final String? employeeCin;
  final String? employeePosition;

  static const List<String> statuses = ['Brouillon', 'Validé', 'Payé'];

  String get periodLabel {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[periodMonth]} $periodYear';
  }

  factory PayrollSlip.fromMap(Map<String, dynamic> m) => PayrollSlip(
        id: m['id'] as int?,
        employeeId: m['employee_id'] as int,
        periodYear: m['period_year'] as int,
        periodMonth: m['period_month'] as int,
        salaryBrut: (m['salary_brut'] as num).toDouble(),
        cnssEmployee: (m['cnss_employee'] as num).toDouble(),
        amoEmployee: (m['amo_employee'] as num).toDouble(),
        igr: (m['igr'] as num).toDouble(),
        otherDeductions: (m['other_deductions'] as num?)?.toDouble() ?? 0,
        salaryNet: (m['salary_net'] as num).toDouble(),
        cnssEmployer: (m['cnss_employer'] as num).toDouble(),
        amoEmployer: (m['amo_employer'] as num).toDouble(),
        status: m['status'] as String? ?? 'Brouillon',
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as int,
        employeeName: m['employee_name'] as String?,
        employeeCin: m['employee_cin'] as String?,
        employeePosition: m['employee_position'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'period_year': periodYear,
        'period_month': periodMonth,
        'salary_brut': salaryBrut,
        'cnss_employee': cnssEmployee,
        'amo_employee': amoEmployee,
        'igr': igr,
        'other_deductions': otherDeductions,
        'salary_net': salaryNet,
        'cnss_employer': cnssEmployer,
        'amo_employer': amoEmployer,
        'status': status,
        'notes': notes,
        'created_at': createdAt,
      };
}
