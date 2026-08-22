import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';

/// GoRouter provider that watches auth state
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnboardingComplete = authState.user?.isOnboardingComplete ?? false;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/';

      // Not authenticated → show welcome/login
      if (!isAuthenticated) {
        if (isAuthRoute) return null;
        return '/';
      }

      // Authenticated but onboarding not complete → onboarding
      if (!isOnboardingComplete) {
        if (state.matchedLocation == '/onboarding') return null;
        return '/onboarding';
      }

      // Authenticated + onboarding complete, but on auth routes → home
      if (isAuthRoute || state.matchedLocation == '/onboarding') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
