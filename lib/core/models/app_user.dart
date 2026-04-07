class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash; // bcrypt-style hash placeholder; replace with real hash in prod
  final String role;         // 'admin' | 'manager' | 'employee' | 'comptable'
  final String? avatar;
  final bool isActive;
  final int createdAt;
  final int? lastLoginAt;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.role = 'employee',
    this.avatar,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';

  static String roleLabel(String role) {
    switch (role) {
      case 'admin':       return 'Administrateur';
      case 'manager':     return 'Manager';
      case 'comptable':   return 'Comptable';
      default:            return 'Employé';
    }
  }

  static const roles = ['admin', 'manager', 'comptable', 'employee'];

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as int?,
        name: m['name'] as String,
        email: m['email'] as String,
        passwordHash: m['password_hash'] as String,
        role: m['role'] as String? ?? 'employee',
        avatar: m['avatar'] as String?,
        isActive: (m['is_active'] as int? ?? 1) == 1,
        createdAt: m['created_at'] as int,
        lastLoginAt: m['last_login_at'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'role': role,
        'avatar': avatar,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'last_login_at': lastLoginAt,
      };

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    String? avatar,
    bool? isActive,
    int? createdAt,
    int? lastLoginAt,
  }) =>
      AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        avatar: avatar ?? this.avatar,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      );
}
