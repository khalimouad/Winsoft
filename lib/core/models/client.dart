class Client {
  final int? id;
  final String name;
  final int? companyId;
  final String? companyName; // joined field, not stored
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? cin;   // Carte d'Identité Nationale
  final String? ice;   // ICE for company-clients
  final String? notes;
  final int createdAt;

  const Client({
    this.id,
    required this.name,
    this.companyId,
    this.companyName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.cin,
    this.ice,
    this.notes,
    required this.createdAt,
  });

  factory Client.fromMap(Map<String, dynamic> m) => Client(
        id: m['id'] as int?,
        name: m['name'] as String,
        companyId: m['company_id'] as int?,
        companyName: m['company_name'] as String?,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        city: m['city'] as String?,
        cin: m['cin'] as String?,
        ice: m['ice'] as String?,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'company_id': companyId,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'cin': cin,
        'ice': ice,
        'notes': notes,
        'created_at': createdAt,
      };

  Client copyWith({
    int? id,
    String? name,
    int? companyId,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? cin,
    String? ice,
    String? notes,
    int? createdAt,
  }) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
        companyId: companyId ?? this.companyId,
        companyName: companyName ?? this.companyName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        city: city ?? this.city,
        cin: cin ?? this.cin,
        ice: ice ?? this.ice,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
