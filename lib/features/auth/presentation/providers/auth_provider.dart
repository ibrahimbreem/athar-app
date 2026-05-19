import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/user_model.dart';
import '../../../../services/firebase_auth_service.dart';
import '../../../../services/fcm_service.dart';

// ─── Theme Mode ──────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', !isDark);
  }
}

// ─── Onboarding ───────────────────────────────────────────────────────────────

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) => OnboardingNotifier(),
);

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('onboardingDone') ?? false;
  }

  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingDone', true);
  }
}

// ─── Firebase Auth Stream ────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ─── Current User Data ────────────────────────────────────────────────────────

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>(
  (ref) => CurrentUserNotifier(),
);

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  CurrentUserNotifier() : super(null);

  void setUser(UserModel? user) => state = user;

  void updateSavedCampaigns(List<String> ids) {
    if (state != null) state = state!.copyWith(savedCases: ids);
  }
}

// ─── Auth Actions ────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  final _authService = FirebaseAuthService();
  final _fcmService = FcmService();

  Future<UserModel?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _ref.read(currentUserProvider.notifier).setUser(user);
      _updateFcmToken(user.id);
      state = const AsyncValue.data(null);
      return user;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_mapFirebaseError(e), StackTrace.current);
      return null;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? location,
    String? story,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        location: location,
        story: story,
      );
      _ref.read(currentUserProvider.notifier).setUser(user);
      _updateFcmToken(user.id);
      state = const AsyncValue.data(null);
      return user;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_mapFirebaseError(e), StackTrace.current);
      return null;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _ref.read(currentUserProvider.notifier).setUser(null);
    state = const AsyncValue.data(null);
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_mapFirebaseError(e), StackTrace.current);
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    _ref.read(currentUserProvider.notifier).setUser(user);
  }

  void _updateFcmToken(String userId) async {
    try {
      final token = await _fcmService.getToken();
      if (token != null) {
        await _authService.updateFcmToken(userId, token);
      }
    } catch (_) {}
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'too-many-requests':
        return 'محاولات كثيرة، يرجى الانتظار';
      default:
        return 'حدث خطأ، يرجى المحاولة مرة أخرى';
    }
  }
}

// ─── Selected Role ────────────────────────────────────────────────────────────

final selectedRoleProvider = StateProvider<UserRole?>((ref) => null);
