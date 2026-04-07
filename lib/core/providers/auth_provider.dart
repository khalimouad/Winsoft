import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/subscription.dart';
import '../repositories/user_repository.dart';
import '../database/database_helper.dart';

// ── Current session user ──────────────────────────────────────────────────

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isManager => user?.isManager ?? false;
}

class AuthNotifier extends Notifier<AuthState> {
  final _repo = UserRepository();

  @override
  AuthState build() => const AuthState();

  Future<bool> login(String email, String password) async {
    state = const AuthState(isLoading: true);
    final user = await _repo.authenticate(email, password);
    if (user == null) {
      state = const AuthState(error: 'Email ou mot de passe incorrect.');
      return false;
    }
    state = AuthState(user: user);
    return true;
  }

  void logout() => state = const AuthState();

  void clearError() {
    if (state.error != null) state = AuthState(user: state.user);
  }

  void refreshUser(AppUser user) {
    state = AuthState(user: user);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// ── Team / Users list ─────────────────────────────────────────────────────

class UserListNotifier extends AsyncNotifier<List<AppUser>> {
  final _repo = UserRepository();

  @override
  Future<List<AppUser>> build() => _repo.getAll();

  Future<void> add(AppUser user) async {
    await _repo.insert(user);
    ref.invalidateSelf();
  }

  Future<void> edit(AppUser user) async {
    await _repo.update(user);
    ref.invalidateSelf();
    // Refresh current user if it's the same
    final auth = ref.read(authProvider);
    if (auth.user?.id == user.id) {
      ref.read(authProvider.notifier).refreshUser(user);
    }
  }

  Future<void> toggleActive(AppUser user) async {
    await _repo.update(user.copyWith(isActive: !user.isActive));
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
  }
}

final userListProvider =
    AsyncNotifierProvider<UserListNotifier, List<AppUser>>(UserListNotifier.new);

// ── Active subscription ───────────────────────────────────────────────────

final subscriptionProvider = FutureProvider<ActiveSubscription>((ref) async {
  final settings = await DatabaseHelper.instance.getAllSettings();
  final planId = settings['subscription_plan'] ?? 'starter';
  final status = settings['subscription_status'] ?? 'trial';
  final endMs = int.tryParse(settings['subscription_end'] ?? '') ??
      DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch;

  return ActiveSubscription(
    planId: planId,
    isYearly: false,
    startDate: DateTime.now().subtract(const Duration(days: 1)),
    endDate: DateTime.fromMillisecondsSinceEpoch(endMs),
    status: status,
  );
});
