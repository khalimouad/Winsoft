class ProductCategory {
  final int? id;
  final String name;
  final int? parentId;
  final String? parentName;
  final String? color;
  final String? description;

  const ProductCategory({
    this.id,
    required this.name,
    this.parentId,
    this.parentName,
    this.color,
    this.description,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> m) => ProductCategory(
        id: m['id'] as int?,
        name: m['name'] as String,
        parentId: m['parent_id'] as int?,
        parentName: m['parent_name'] as String?,
        color: m['color'] as String?,
        description: m['description'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'parent_id': parentId,
        'color': color,
        'description': description,
      };

  ProductCategory copyWith({
    int? id,
    String? name,
    int? parentId,
    String? parentName,
    String? color,
    String? description,
  }) =>
      ProductCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId ?? this.parentId,
        parentName: parentName ?? this.parentName,
        color: color ?? this.color,
        description: description ?? this.description,
      );
}
