import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user.dart';
import '../../../core/models/user_role.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_handler.dart';

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

// ─── Auth Notifier ────────────────────────────────────────────

/// Manages authentication state using a simple in-memory approach.
/// Firebase AuthRepository will be injected when Firebase is configured.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Current user shortcut
  AppUser? get currentUser => state.user;

  /// Sign in with demo role (for development before Firebase is connected)
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

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      // TODO: Replace with Firebase AuthRepository call
      // final user = await authRepository.signInWithEmail(email: email, password: password);
      // state = state.copyWith(status: AuthStatus.authenticated, user: user);

      // Placeholder for now
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: AppUser(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          role: Role.buyer,
          email: email,
          displayName: email.split('@').first,
          isOnboardingComplete: false,
        ),
      );
    } catch (e) {
      final exception = ErrorHandler.handleError(e, context: 'signInWithEmail');
      state = state.copyWith(
        status: AuthStatus.error,
        error: exception,
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      // TODO: Replace with Firebase AuthRepository call
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: AppUser(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          role: Role.buyer,
          email: email,
          displayName: displayName,
          isOnboardingComplete: false,
        ),
      );
    } catch (e) {
      final exception = ErrorHandler.handleError(e, context: 'signUpWithEmail');
      state = state.copyWith(
        status: AuthStatus.error,
        error: exception,
      );
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

    state = state.copyWith(
      user: user.copyWith(
        role: role,
        displayName: displayName,
        phone: phone ?? user.phone,
        languageCode: languageCode ?? user.languageCode,
        isOnboardingComplete: true,
      ),
    );
  }

  /// Update user role (for demo/preview)
  void setRole(Role role) {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(user: user.copyWith(role: role));
  }

  /// Update language
  void setLanguage(String languageCode) {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(user: user.copyWith(languageCode: languageCode));
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // TODO: Replace with Firebase AuthRepository call
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      final exception = ErrorHandler.handleError(e, context: 'signOut');
      state = state.copyWith(error: exception);
    }
  }
}

// ─── Providers ────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider for just the current user
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for auth status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
