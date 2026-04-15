class Warehouse {
  final int? id;
  final String name;
  final String? code;
  final String? city;
  final String? address;
  final bool isDefault;
  final bool isActive;
  final int createdAt;

  const Warehouse({
    this.id,
    required this.name,
    this.code,
    this.city,
    this.address,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory Warehouse.fromMap(Map<String, dynamic> m) => Warehouse(
        id: m['id'] as int?,
        name: m['name'] as String,
        code: m['code'] as String?,
        city: m['city'] as String?,
        address: m['address'] as String?,
        isDefault: (m['is_default'] as int?) == 1,
        isActive: (m['is_active'] as int?) != 0,
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'code': code,
        'city': city,
        'address': address,
        'is_default': isDefault ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  Warehouse copyWith({
    int? id,
    String? name,
    String? code,
    String? city,
    String? address,
    bool? isDefault,
    bool? isActive,
    int? createdAt,
  }) =>
      Warehouse(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        city: city ?? this.city,
        address: address ?? this.address,
        isDefault: isDefault ?? this.isDefault,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
}
