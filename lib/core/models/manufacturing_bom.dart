class ManufacturingBom {
  const ManufacturingBom({
    this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.components = const [],
  });

  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final int createdAt;
  final List<BomComponent> components;

  factory ManufacturingBom.fromMap(Map<String, dynamic> m,
          {List<BomComponent> components = const []}) =>
      ManufacturingBom(
        id: m['id'] as int?,
        name: m['name'] as String,
        description: m['description'] as String?,
        isActive: (m['is_active'] as int?) == 1,
        createdAt: m['created_at'] as int,
        components: components,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  ManufacturingBom copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    int? createdAt,
    List<BomComponent>? components,
  }) =>
      ManufacturingBom(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        components: components ?? this.components,
      );

  List<BomComponent> get inputs =>
      components.where((c) => c.role == 'input').toList();
  List<BomComponent> get outputs =>
      components.where((c) => c.role == 'output').toList();
  List<BomComponent> get byproducts =>
      components.where((c) => c.role == 'byproduct').toList();
}

class BomComponent {
  const BomComponent({
    this.id,
    required this.bomId,
    required this.productId,
    required this.quantity,
    this.unit,
    this.role = 'input',
    this.notes,
    this.productName,
    this.productReference,
  });

  final int? id;
  final int bomId;
  final int productId;
  final double quantity;
  final String? unit;
  /// 'input' | 'output' | 'byproduct'
  final String role;
  final String? notes;
  // Joined fields
  final String? productName;
  final String? productReference;

  factory BomComponent.fromMap(Map<String, dynamic> m) => BomComponent(
        id: m['id'] as int?,
        bomId: m['bom_id'] as int,
        productId: m['product_id'] as int,
        quantity: (m['quantity'] as num).toDouble(),
        unit: m['unit'] as String?,
        role: m['role'] as String? ?? 'input',
        notes: m['notes'] as String?,
        productName: m['product_name'] as String?,
        productReference: m['product_reference'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'bom_id': bomId,
        'product_id': productId,
        'quantity': quantity,
        'unit': unit,
        'role': role,
        'notes': notes,
      };
}

class ProductionOrder {
  const ProductionOrder({
    this.id,
    required this.reference,
    required this.bomId,
    required this.plannedDate,
    this.startDate,
    this.endDate,
    this.status = 'Brouillon',
    this.notes,
    required this.createdAt,
    this.bomName,
    this.outputs = const [],
  });

  final int? id;
  final String reference;
  final int bomId;
  final int plannedDate;
  final int? startDate;
  final int? endDate;
  final String status;
  final String? notes;
  final int createdAt;
  // Joined
  final String? bomName;
  final List<ProductionOutput> outputs;

  static const List<String> statuses = [
    'Brouillon', 'Planifié', 'En cours', 'Terminé', 'Annulé'
  ];

  factory ProductionOrder.fromMap(Map<String, dynamic> m,
          {List<ProductionOutput> outputs = const []}) =>
      ProductionOrder(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        bomId: m['bom_id'] as int,
        plannedDate: m['planned_date'] as int,
        startDate: m['start_date'] as int?,
        endDate: m['end_date'] as int?,
        status: m['status'] as String? ?? 'Brouillon',
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as int,
        bomName: m['bom_name'] as String?,
        outputs: outputs,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'bom_id': bomId,
        'planned_date': plannedDate,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'notes': notes,
        'created_at': createdAt,
      };
}

class ProductionOutput {
  const ProductionOutput({
    this.id,
    required this.productionOrderId,
    required this.productId,
    required this.plannedQty,
    this.actualQty = 0,
    this.role = 'output',
    this.productName,
  });

  final int? id;
  final int productionOrderId;
  final int productId;
  final double plannedQty;
  final double actualQty;
  final String role;
  final String? productName;

  factory ProductionOutput.fromMap(Map<String, dynamic> m) => ProductionOutput(
        id: m['id'] as int?,
        productionOrderId: m['production_order_id'] as int,
        productId: m['product_id'] as int,
        plannedQty: (m['planned_qty'] as num).toDouble(),
        actualQty: (m['actual_qty'] as num?)?.toDouble() ?? 0,
        role: m['role'] as String? ?? 'output',
        productName: m['product_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'production_order_id': productionOrderId,
        'product_id': productId,
        'planned_qty': plannedQty,
        'actual_qty': actualQty,
        'role': role,
      };
}
