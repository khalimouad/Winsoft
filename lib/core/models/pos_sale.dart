class PriceList {
  const PriceList({
    this.id,
    required this.name,
    this.description,
    this.discountPercent = 0,
    this.isDefault = false,
    required this.createdAt,
    this.items = const [],
  });

  final int? id;
  final String name;
  final String? description;
  /// Global discount % applied to all products (overridden per-product by items)
  final double discountPercent;
  final bool isDefault;
  final int createdAt;
  final List<PriceListItem> items;

  factory PriceList.fromMap(Map<String, dynamic> m,
          {List<PriceListItem> items = const []}) =>
      PriceList(
        id: m['id'] as int?,
        name: m['name'] as String,
        description: m['description'] as String?,
        discountPercent:
            (m['discount_percent'] as num?)?.toDouble() ?? 0,
        isDefault: (m['is_default'] as int?) == 1,
        createdAt: m['created_at'] as int,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'discount_percent': discountPercent,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt,
      };

  /// Get the effective price for a product (from specific item or global discount).
  double effectivePrice(int productId, double basePrice) {
    final item = items.where((i) => i.productId == productId).firstOrNull;
    if (item != null) return item.fixedPrice ?? basePrice * (1 - item.discountPercent / 100);
    if (discountPercent > 0) return basePrice * (1 - discountPercent / 100);
    return basePrice;
  }
}

class PriceListItem {
  const PriceListItem({
    this.id,
    required this.priceListId,
    required this.productId,
    this.fixedPrice,
    this.discountPercent = 0,
    this.productName,
  });

  final int? id;
  final int priceListId;
  final int productId;
  final double? fixedPrice;
  final double discountPercent;
  final String? productName;

  factory PriceListItem.fromMap(Map<String, dynamic> m) => PriceListItem(
        id: m['id'] as int?,
        priceListId: m['price_list_id'] as int,
        productId: m['product_id'] as int,
        fixedPrice: (m['fixed_price'] as num?)?.toDouble(),
        discountPercent:
            (m['discount_percent'] as num?)?.toDouble() ?? 0,
        productName: m['product_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'price_list_id': priceListId,
        'product_id': productId,
        'fixed_price': fixedPrice,
        'discount_percent': discountPercent,
      };
}

// ── POS Session ───────────────────────────────────────────────────────────────

class PosSession {
  const PosSession({
    this.id,
    required this.openedAt,
    this.closedAt,
    this.openingCash = 0,
    this.closingCash,
    this.status = 'open',
    required this.userId,
    this.userName,
  });

  final int? id;
  final int openedAt;
  final int? closedAt;
  final double openingCash;
  final double? closingCash;
  final String status; // 'open' | 'closed'
  final int userId;
  final String? userName;

  factory PosSession.fromMap(Map<String, dynamic> m) => PosSession(
        id: m['id'] as int?,
        openedAt: m['opened_at'] as int,
        closedAt: m['closed_at'] as int?,
        openingCash: (m['opening_cash'] as num?)?.toDouble() ?? 0,
        closingCash: (m['closing_cash'] as num?)?.toDouble(),
        status: m['status'] as String? ?? 'open',
        userId: m['user_id'] as int,
        userName: m['user_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'opened_at': openedAt,
        'closed_at': closedAt,
        'opening_cash': openingCash,
        'closing_cash': closingCash,
        'status': status,
        'user_id': userId,
      };
}

// ── POS Sale (receipt) ────────────────────────────────────────────────────────

class PosSaleItem {
  const PosSaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.description,
    required this.quantity,
    required this.unitPriceHt,
    this.tvaRate = 20,
    this.discountPercent = 0,
    this.productName,
  });

  final int? id;
  final int saleId;
  final int productId;
  final String description;
  final double quantity;
  final double unitPriceHt;
  final double tvaRate;
  final double discountPercent;
  final String? productName;

  double get lineHt => quantity * unitPriceHt * (1 - discountPercent / 100);
  double get lineTva => lineHt * tvaRate / 100;
  double get lineTtc => lineHt + lineTva;

  factory PosSaleItem.fromMap(Map<String, dynamic> m) => PosSaleItem(
        id: m['id'] as int?,
        saleId: m['sale_id'] as int,
        productId: m['product_id'] as int,
        description: m['description'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitPriceHt: (m['unit_price_ht'] as num).toDouble(),
        tvaRate: (m['tva_rate'] as num?)?.toDouble() ?? 20,
        discountPercent: (m['discount_percent'] as num?)?.toDouble() ?? 0,
        productName: m['product_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'sale_id': saleId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price_ht': unitPriceHt,
        'tva_rate': tvaRate,
        'discount_percent': discountPercent,
      };
}

class PosSale {
  const PosSale({
    this.id,
    required this.reference,
    required this.sessionId,
    this.clientId,
    required this.saleDate,
    required this.totalHt,
    required this.totalTva,
    required this.totalTtc,
    this.paymentMethod = 'Espèces',
    this.amountTendered = 0,
    this.change = 0,
    this.priceListId,
    this.notes,
    this.invoiceId,
    this.clientName,
    this.items = const [],
  });

  final int? id;
  final String reference;
  final int sessionId;
  final int? clientId;
  final int saleDate;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final String paymentMethod; // 'Espèces' | 'Carte' | 'Chèque'
  final double amountTendered;
  final double change;
  final int? priceListId;
  final String? notes;
  final int? invoiceId;
  // Joined
  final String? clientName;
  final List<PosSaleItem> items;

  factory PosSale.fromMap(Map<String, dynamic> m,
          {List<PosSaleItem> items = const []}) =>
      PosSale(
        id: m['id'] as int?,
        reference: m['reference'] as String,
        sessionId: m['session_id'] as int,
        clientId: m['client_id'] as int?,
        saleDate: m['sale_date'] as int,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        paymentMethod: m['payment_method'] as String? ?? 'Espèces',
        amountTendered: (m['amount_tendered'] as num?)?.toDouble() ?? 0,
        change: m['change_given'] != null
            ? (m['change_given'] as num).toDouble()
            : 0,
        priceListId: m['price_list_id'] as int?,
        notes: m['notes'] as String?,
        invoiceId: m['invoice_id'] as int?,
        clientName: m['client_name'] as String?,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reference': reference,
        'session_id': sessionId,
        'client_id': clientId,
        'sale_date': saleDate,
        'total_ht': totalHt,
        'total_tva': totalTva,
        'total_ttc': totalTtc,
        'payment_method': paymentMethod,
        'amount_tendered': amountTendered,
        'change_given': change,
        'price_list_id': priceListId,
        'notes': notes,
        'invoice_id': invoiceId,
      };
}
