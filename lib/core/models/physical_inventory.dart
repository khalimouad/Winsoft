class PhysicalInventoryLine {
  final int? id;
  final int? inventoryId;
  final int? productId;
  final String? productName;
  final String? productRef;
  final double expectedQty;
  final double countedQty;

  const PhysicalInventoryLine({
    this.id,
    this.inventoryId,
    this.productId,
    this.productName,
    this.productRef,
    required this.expectedQty,
    required this.countedQty,
  });

  double get variance => countedQty - expectedQty;
  bool get hasVariance => variance.abs() > 0.001;

  factory PhysicalInventoryLine.fromMap(Map<String, dynamic> m) =>
      PhysicalInventoryLine(
        id: m['id'] as int?,
        inventoryId: m['inventory_id'] as int?,
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String?,
        productRef: m['product_ref'] as String?,
        expectedQty: (m['expected_qty'] as num).toDouble(),
        countedQty: (m['counted_qty'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (inventoryId != null) 'inventory_id': inventoryId,
        'product_id': productId,
        'expected_qty': expectedQty,
        'counted_qty': countedQty,
      };

  PhysicalInventoryLine copyWith({
    double? expectedQty,
    double? countedQty,
  }) =>
      PhysicalInventoryLine(
        id: id,
        inventoryId: inventoryId,
        productId: productId,
        productName: productName,
        productRef: productRef,
        expectedQty: expectedQty ?? this.expectedQty,
        countedQty: countedQty ?? this.countedQty,
      );
}

class PhysicalInventory {
  final int? id;
  final String reference;
  final int? warehouseId;
  final String? warehouseName;
  final int date;
  final String status;
  final String? notes;
  final List<PhysicalInventoryLine> lines;

  const PhysicalInventory({
    this.id,
    required this.reference,
    this.warehouseId,
    this.warehouseName,
    required this.date,
    this.status = 'Brouillon',
    this.notes,
    this.lines = const [],
  });

  int get varianceCount => lines.where((l) => l.hasVariance).length;

  factory PhysicalInventory.fromMap(Map<String, dynamic> m,
      {List<PhysicalInventoryLine> lines = const []}) =>
      PhysicalInventory(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        warehouseId: m['warehouse_id'] as int?,
        warehouseName: m['warehouse_name'] as String?,
        date: m['date'] as int,
        status: m['status'] as String? ?? 'Brouillon',
        notes: m['notes'] as String?,
        lines: lines,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'warehouse_id': warehouseId,
        'date': date,
        'status': status,
        'notes': notes,
      };

  PhysicalInventory copyWith({
    int? id,
    String? reference,
    int? warehouseId,
    String? warehouseName,
    int? date,
    String? status,
    String? notes,
    List<PhysicalInventoryLine>? lines,
  }) =>
      PhysicalInventory(
        id: id ?? this.id,
        reference: reference ?? this.reference,
        warehouseId: warehouseId ?? this.warehouseId,
        warehouseName: warehouseName ?? this.warehouseName,
        date: date ?? this.date,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        lines: lines ?? this.lines,
      );
}
