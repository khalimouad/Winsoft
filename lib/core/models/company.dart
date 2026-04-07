class Company {
  final int? id;
  final String name;
  final String? industry;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? ice;       // Identifiant Commun de l'Entreprise (15 chiffres)
  final String? rc;        // Registre de Commerce
  final String? ifNumber;  // Identifiant Fiscal
  final String? patente;   // Numéro de Patente
  final String? cnss;      // CNSS
  final double? capitalSocial;
  final String status;
  final int createdAt;

  const Company({
    this.id,
    required this.name,
    this.industry,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.ice,
    this.rc,
    this.ifNumber,
    this.patente,
    this.cnss,
    this.capitalSocial,
    this.status = 'Active',
    required this.createdAt,
  });

  factory Company.fromMap(Map<String, dynamic> m) => Company(
        id: m['id'] as int?,
        name: m['name'] as String,
        industry: m['industry'] as String?,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        city: m['city'] as String?,
        ice: m['ice'] as String?,
        rc: m['rc'] as String?,
        ifNumber: m['if_number'] as String?,
        patente: m['patente'] as String?,
        cnss: m['cnss'] as String?,
        capitalSocial: m['capital_social'] as double?,
        status: m['status'] as String? ?? 'Active',
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'industry': industry,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'ice': ice,
        'rc': rc,
        'if_number': ifNumber,
        'patente': patente,
        'cnss': cnss,
        'capital_social': capitalSocial,
        'status': status,
        'created_at': createdAt,
      };

  Company copyWith({
    int? id,
    String? name,
    String? industry,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? ice,
    String? rc,
    String? ifNumber,
    String? patente,
    String? cnss,
    double? capitalSocial,
    String? status,
    int? createdAt,
  }) =>
      Company(
        id: id ?? this.id,
        name: name ?? this.name,
        industry: industry ?? this.industry,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        city: city ?? this.city,
        ice: ice ?? this.ice,
        rc: rc ?? this.rc,
        ifNumber: ifNumber ?? this.ifNumber,
        patente: patente ?? this.patente,
        cnss: cnss ?? this.cnss,
        capitalSocial: capitalSocial ?? this.capitalSocial,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
