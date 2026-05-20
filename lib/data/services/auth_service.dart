import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class LocalUser {
  final String uid;
  final String email;

  LocalUser({required this.uid, required this.email});
}

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  AuthService();

  /// Current local user
  LocalUser? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      return LocalUser(uid: user.uid, email: user.email ?? '');
    }
    return null;
  }

  /// Sign in with email and password
  Future<LocalUser?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        return LocalUser(uid: user.uid, email: user.email ?? '');
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// Global provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Global provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Notifier to manage local authentication state
class LocalAuthNotifier extends StateNotifier<AsyncValue<LocalUser?>> {
  final AuthService _authService;

  LocalAuthNotifier(this._authService)
      : super(AsyncValue.data(_authService.currentUser));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

/// Provider for local auth state
final authStateProvider =
    StateNotifierProvider<LocalAuthNotifier, AsyncValue<LocalUser?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return LocalAuthNotifier(authService);
    });
