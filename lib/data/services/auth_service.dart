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
  final SharedPreferences _prefs;

  LocalAuthNotifier(this._authService, this._prefs)
      : super(AsyncValue.data(_authService.currentUser)) {
    _init();
  }

  void _init() {
    final user = _authService.currentUser;
    if (user != null) {
      _prefs.setBool('admin_logged_in', true);
      _prefs.setString('admin_uid', user.uid);
      _prefs.setString('admin_email', user.email);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email, password);
      if (user != null) {
        await _prefs.setBool('admin_logged_in', true);
        await _prefs.setString('admin_uid', user.uid);
        await _prefs.setString('admin_email', user.email);
      }
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _authService.signOut();
    await _prefs.remove('admin_logged_in');
    await _prefs.remove('admin_uid');
    await _prefs.remove('admin_email');
    state = const AsyncValue.data(null);
  }
}

/// Provider for local auth state
final authStateProvider =
    StateNotifierProvider<LocalAuthNotifier, AsyncValue<LocalUser?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      final prefs = ref.watch(sharedPreferencesProvider);
      return LocalAuthNotifier(authService, prefs);
    });
