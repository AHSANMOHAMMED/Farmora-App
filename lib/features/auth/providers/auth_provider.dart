import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user.dart';
import '../../../core/models/user_role.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/data/firestore_auth_repository.dart';
import '../../../core/data/firestore_user_repository.dart';

// ─── Auth State ───────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final AppException? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    AppException? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        error: clearError ? null : (error ?? this.error),
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

// ─── Firestore Auth Notifier ──────────────────────────────────

/// Manages authentication state using Firebase Auth + Firestore profiles.
class AuthNotifier extends StateNotifier<AuthState> {
  final FirestoreAuthRepository _authRepo;
  final FirestoreUserRepository _userRepo;
  StreamSubscription? _authSub;

  AuthNotifier(this._authRepo, this._userRepo) : super(const AuthState()) {
    // Listen to Firebase auth state changes
    _authSub = _authRepo.authStateChanges.listen((appUser) {
      if (appUser != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: appUser,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  AppUser? get currentUser => state.user;

  /// Sign in with demo role (for development/preview without Firebase)
  void signInDemo(Role role) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: AppUser(
        id: 'demo-${role.name}',
        role: role,
        displayName: 'Demo User',
        isOnboardingComplete: true,
      ),
    );
  }

  /// Sign in with email and password (real Firebase Auth)
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepo.signInWithEmail(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      final exception = ErrorHandler.handleError(e, context: 'signInWithEmail');
      state = state.copyWith(status: AuthStatus.error, error: exception);
    }
  }

  /// Sign up with email and password (real Firebase Auth)
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepo.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      final exception = ErrorHandler.handleError(e, context: 'signUpWithEmail');
      state = state.copyWith(status: AuthStatus.error, error: exception);
    }
  }

  /// Verify phone number for OTP sign-in
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _authRepo.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  /// Complete phone sign-in with verification code
  Future<void> signInWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepo.signInWithPhone(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      final exception = ErrorHandler.handleError(e, context: 'signInWithPhone');
      state = state.copyWith(status: AuthStatus.error, error: exception);
    }
  }

  /// Complete onboarding (update role, name, etc.)
  Future<void> completeOnboarding({
    required Role role,
    required String displayName,
    String? phone,
    String? languageCode,
  }) async {
    final user = state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(
      role: role,
      displayName: displayName,
      phone: phone ?? user.phone,
      languageCode: languageCode ?? user.languageCode,
      isOnboardingComplete: true,
    );

    // Save to Firestore
    await _userRepo.updateUserProfile(updatedUser);

    state = state.copyWith(user: updatedUser);
  }

  /// Update user role
  void setRole(Role role) {
    final user = state.user;
    if (user == null) return;
    final updatedUser = user.copyWith(role: role);
    state = state.copyWith(user: updatedUser);
    _userRepo.updateUserProfile(updatedUser);
  }

  /// Update language
  void setLanguage(String languageCode) {
    final user = state.user;
    if (user == null) return;
    final updatedUser = user.copyWith(languageCode: languageCode);
    state = state.copyWith(user: updatedUser);
    _userRepo.updateUserProfile(updatedUser);
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authRepo.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      final exception = ErrorHandler.handleError(e, context: 'signOut');
      state = state.copyWith(error: exception);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ─── Providers ────────────────────────────────────────────────

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) {
  return fb.FirebaseAuth.instance;
});

/// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Auth repository provider (Firebase-backed)
final authRepositoryProvider = Provider<FirestoreAuthRepository>((ref) {
  return FirestoreAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

/// User repository provider (Firestore-backed)
final userRepositoryProvider = Provider<FirestoreUserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});

/// Main auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

/// Convenience provider for just the current user
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for auth status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
