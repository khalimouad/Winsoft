import '../database/database_helper.dart';
import '../models/app_user.dart';

class UserRepository {
  final _db = DatabaseHelper.instance;

  Future<List<AppUser>> getAll() async {
    final rows = await _db.query('users', orderBy: 'name ASC');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser?> getById(int id) async {
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> getByEmail(String email) async {
    final rows = await _db.query('users',
        where: 'email = ? COLLATE NOCASE', whereArgs: [email]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> authenticate(String email, String password) async {
    final user = await getByEmail(email);
    if (user == null || !user.isActive) return null;
    // Simple hash check — replace with bcrypt in production
    if (user.passwordHash != _simpleHash(password)) return null;
    // Update lastLoginAt
    await _db.update(
      'users',
      {'last_login_at': DateTime.now().millisecondsSinceEpoch},
      user.id!,
    );
    return user;
  }

  Future<AppUser> insert(AppUser user) async {
    final id = await _db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<void> update(AppUser user) async {
    await _db.update('users', user.toMap(), user.id!);
  }

  Future<void> delete(int id) async {
    await _db.delete('users', id);
  }

  Future<bool> emailExists(String email) async {
    final n = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM users WHERE email = ? COLLATE NOCASE',
        [email]);
    return (n ?? 0) > 0;
  }

  /// Simple hash — replace with proper bcrypt in production
  static String _simpleHash(String password) {
    var hash = 0;
    for (final ch in password.codeUnits) {
      hash = (hash * 31 + ch) & 0xFFFFFFFF;
    }
    return 'h\$${hash.toRadixString(16).padLeft(8, '0')}';
  }

  static String hashPassword(String password) => _simpleHash(password);
}
