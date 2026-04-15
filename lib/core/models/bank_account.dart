class BankAccount {
  final int? id;
  final String name;
  final String? bankName;
  final String? iban;
  final String? swift;
  final String? rib;
  final String currency;
  final bool isDefault;
  final int createdAt;

  const BankAccount({
    this.id,
    required this.name,
    this.bankName,
    this.iban,
    this.swift,
    this.rib,
    this.currency = 'MAD',
    this.isDefault = false,
    required this.createdAt,
  });

  factory BankAccount.fromMap(Map<String, dynamic> m) => BankAccount(
        id: m['id'] as int?,
        name: m['name'] as String,
        bankName: m['bank_name'] as String?,
        iban: m['iban'] as String?,
        swift: m['swift'] as String?,
        rib: m['rib'] as String?,
        currency: m['currency'] as String? ?? 'MAD',
        isDefault: (m['is_default'] as int?) == 1,
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'bank_name': bankName,
        'iban': iban,
        'swift': swift,
        'rib': rib,
        'currency': currency,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt,
      };

  BankAccount copyWith({
    int? id,
    String? name,
    String? bankName,
    String? iban,
    String? swift,
    String? rib,
    String? currency,
    bool? isDefault,
    int? createdAt,
  }) =>
      BankAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        bankName: bankName ?? this.bankName,
        iban: iban ?? this.iban,
        swift: swift ?? this.swift,
        rib: rib ?? this.rib,
        currency: currency ?? this.currency,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
      );
}
