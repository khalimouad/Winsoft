class Supplier {
  const Supplier({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.ice,
    this.rc,
    this.ifNumber,
    this.patente,
    this.rib,
    this.notes,
    this.status = 'Actif',
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? ice;
  final String? rc;
  final String? ifNumber;
  final String? patente;
  final String? rib;
  final String? notes;
  final String status;
  final int createdAt;

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
        id: m['id'] as int?,
        name: m['name'] as String,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        city: m['city'] as String?,
        ice: m['ice'] as String?,
        rc: m['rc'] as String?,
        ifNumber: m['if_number'] as String?,
        patente: m['patente'] as String?,
        rib: m['rib'] as String?,
        notes: m['notes'] as String?,
        status: m['status'] as String? ?? 'Actif',
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'ice': ice,
        'rc': rc,
        'if_number': ifNumber,
        'patente': patente,
        'rib': rib,
        'notes': notes,
        'status': status,
        'created_at': createdAt,
      };

  Supplier copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? ice,
    String? rc,
    String? ifNumber,
    String? patente,
    String? rib,
    String? notes,
    String? status,
    int? createdAt,
  }) =>
      Supplier(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        city: city ?? this.city,
        ice: ice ?? this.ice,
        rc: rc ?? this.rc,
        ifNumber: ifNumber ?? this.ifNumber,
        patente: patente ?? this.patente,
        rib: rib ?? this.rib,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
