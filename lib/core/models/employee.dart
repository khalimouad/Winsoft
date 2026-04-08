class Employee {
  const Employee({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.cin,
    this.cnssNum,
    this.department,
    this.position,
    required this.salaryBrut,
    required this.hireDate,
    this.birthDate,
    this.address,
    this.city,
    this.rib,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? cin;
  final String? cnssNum;
  final String? department;
  final String? position;
  final double salaryBrut;
  final int hireDate;
  final int? birthDate;
  final String? address;
  final String? city;
  final String? rib;
  final bool isActive;
  final int createdAt;

  factory Employee.fromMap(Map<String, dynamic> m) => Employee(
        id: m['id'] as int?,
        name: m['name'] as String,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        cin: m['cin'] as String?,
        cnssNum: m['cnss_num'] as String?,
        department: m['department'] as String?,
        position: m['position'] as String?,
        salaryBrut: (m['salary_brut'] as num?)?.toDouble() ?? 0,
        hireDate: m['hire_date'] as int,
        birthDate: m['birth_date'] as int?,
        address: m['address'] as String?,
        city: m['city'] as String?,
        rib: m['rib'] as String?,
        isActive: (m['is_active'] as int?) == 1,
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'cin': cin,
        'cnss_num': cnssNum,
        'department': department,
        'position': position,
        'salary_brut': salaryBrut,
        'hire_date': hireDate,
        'birth_date': birthDate,
        'address': address,
        'city': city,
        'rib': rib,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  Employee copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? cin,
    String? cnssNum,
    String? department,
    String? position,
    double? salaryBrut,
    int? hireDate,
    int? birthDate,
    String? address,
    String? city,
    String? rib,
    bool? isActive,
    int? createdAt,
  }) =>
      Employee(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        cin: cin ?? this.cin,
        cnssNum: cnssNum ?? this.cnssNum,
        department: department ?? this.department,
        position: position ?? this.position,
        salaryBrut: salaryBrut ?? this.salaryBrut,
        hireDate: hireDate ?? this.hireDate,
        birthDate: birthDate ?? this.birthDate,
        address: address ?? this.address,
        city: city ?? this.city,
        rib: rib ?? this.rib,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Moroccan payroll calculator — 2024 rates
class MoroccanPayroll {
  MoroccanPayroll._();

  // CNSS rates
  static const double cnssEmployeeRate = 0.0448; // 4.48%
  static const double cnssEmployerRate = 0.1064; // 10.64%
  static const double cnssEmployeeApec = 0.0096; // 0.96% — Formation prof.
  static const double cnssEmployerApec = 0.0396; // 3.96% — Formation prof.
  static const double cnssPlafond = 6000.0; // Monthly ceiling DH

  // AMO (assurance maladie) rates
  static const double amoEmployeeRate = 0.0226; // 2.26%
  static const double amoEmployerRate = 0.0411; // 4.11%

  static double cnssEmployee(double brutMensuel) {
    final base = brutMensuel > cnssPlafond ? cnssPlafond : brutMensuel;
    return base * (cnssEmployeeRate + cnssEmployeeApec);
  }

  static double cnssEmployer(double brutMensuel) {
    final base = brutMensuel > cnssPlafond ? cnssPlafond : brutMensuel;
    return base * (cnssEmployerRate + cnssEmployerApec);
  }

  static double amoEmployee(double brutMensuel) => brutMensuel * amoEmployeeRate;
  static double amoEmployer(double brutMensuel) => brutMensuel * amoEmployerRate;

  /// IGR (IR) on net imposable = brut - CNSS - AMO (employee shares)
  static double igr(double brutMensuel) {
    final netImposable =
        brutMensuel - cnssEmployee(brutMensuel) - amoEmployee(brutMensuel);
    // Annual basis for bracket calculation
    final annual = netImposable * 12;
    double tax = 0;
    if (annual <= 30000) {
      tax = 0;
    } else if (annual <= 50000) {
      tax = (annual - 30000) * 0.10;
    } else if (annual <= 60000) {
      tax = 2000 + (annual - 50000) * 0.20;
    } else if (annual <= 80000) {
      tax = 4000 + (annual - 60000) * 0.30;
    } else if (annual <= 180000) {
      tax = 10000 + (annual - 80000) * 0.34;
    } else {
      tax = 44000 + (annual - 180000) * 0.38;
    }
    // Monthly IGR
    return (tax / 12).clamp(0, double.infinity);
  }

  static double netSalary(double brutMensuel) {
    return brutMensuel -
        cnssEmployee(brutMensuel) -
        amoEmployee(brutMensuel) -
        igr(brutMensuel);
  }
}
