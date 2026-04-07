class Product {
  final int? id;
  final String name;
  final String? reference; // SKU / Référence
  final String? category;
  final double priceHt;    // Prix Hors Taxe
  final double tvaRate;    // TVA rate: 0, 7, 10, 14, 20
  final int? stock;        // null = service (unlimited)
  final String? unit;      // pièce, heure, forfait, m², kg…
  final String? description;
  final String status;
  final int createdAt;

  const Product({
    this.id,
    required this.name,
    this.reference,
    this.category,
    required this.priceHt,
    this.tvaRate = 20.0,
    this.stock,
    this.unit,
    this.description,
    this.status = 'Actif',
    required this.createdAt,
  });

  double get priceTtc => priceHt * (1 + tvaRate / 100);
  double get tvaAmount => priceHt * (tvaRate / 100);

  bool get isService => stock == null;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        reference: m['reference'] as String?,
        category: m['category'] as String?,
        priceHt: (m['price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20.0,
        stock: m['stock'] as int?,
        unit: m['unit'] as String?,
        description: m['description'] as String?,
        status: m['status'] as String? ?? 'Actif',
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'reference': reference,
        'category': category,
        'price_ht': priceHt,
        'tva_rate': tvaRate,
        'stock': stock,
        'unit': unit,
        'description': description,
        'status': status,
        'created_at': createdAt,
      };

  Product copyWith({
    int? id,
    String? name,
    String? reference,
    String? category,
    double? priceHt,
    double? tvaRate,
    int? stock,
    String? unit,
    String? description,
    String? status,
    int? createdAt,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        reference: reference ?? this.reference,
        category: category ?? this.category,
        priceHt: priceHt ?? this.priceHt,
        tvaRate: tvaRate ?? this.tvaRate,
        stock: stock ?? this.stock,
        unit: unit ?? this.unit,
        description: description ?? this.description,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
