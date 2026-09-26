import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../home/presentation/home_screen.dart';
import 'session_actions.dart';
import 'welcome_screen.dart';
import '../../../providers/farmora_state.dart';

/// AuthGate routes by auth state + profile:
/// signed in → [HomeScreen] (which applies the maintenance / version /
/// verification gates); signed out → [WelcomeScreen].
///
/// When a session ends (sign-out, account deletion, suspension, inactivity
/// timeout) every route pushed above the gate is removed so the user lands
/// back on the sign-in flow instead of a stale screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  /// True while an auth flow that temporarily signs in (registration before
  /// the profile exists, OTP password reset) runs. The gate then keeps the
  /// signed-out UI so [HomeScreen] does not start loading a half-created /
  /// transient session.
  static final ValueNotifier<bool> authFlowInProgress = ValueNotifier(false);

  /// Runs [body] with [authFlowInProgress] set.
  static Future<T> guardAuthFlow<T>(Future<T> Function() body) async {
    authFlowInProgress.value = true;
    try {
      return await body();
    } finally {
      // A flow that ends signed out: let the auth stream deliver the
      // sign-out before the gate listens again (no Home flash).
      if (Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser == null) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      authFlowInProgress.value = false;
    }
  }

  static bool _resetScheduled = false;

  /// Clears the whole navigation stack and shows a fresh [AuthGate] from the
  /// root navigator. Safe to call several times in a row.
  static void resetTo(BuildContext context) {
    if (_resetScheduled) return;
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator == null) return;
    _resetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetScheduled = false;
      if (!navigator.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  FarmoraState? _state;
  bool _wasSignedIn = false;
  Stream<User?>? _authStream;

  /// Created once so rebuilds do not resubscribe (and flash the spinner).
  Stream<User?> get _authChanges =>
      _authStream ??= FirebaseAuth.instance.authStateChanges();

  @override
  void initState() {
    super.initState();
    final state = context.read<FarmoraState>();
    _state = state;
    _wasSignedIn = state.currentUserId.isNotEmpty;
    state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state?.removeListener(_onStateChanged);
    super.dispose();
  }

  /// Signed in → signed out (any reason): drop every route above the gate.
  void _onStateChanged() {
    final state = _state;
    if (state == null || !mounted) return;
    final signedInNow = state.currentUserId.isNotEmpty;
    if (_wasSignedIn && !signedInNow) {
      _wasSignedIn = false;
      // Covers forced sign-outs (timeout, suspension) too.
      unbindTransporterController(context);
      final route = ModalRoute.of(context);
      // Only needed when something is stacked on top of the gate.
      if (route == null || !route.isCurrent || !route.isFirst) {
        AuthGate.resetTo(context);
      }
      return;
    }
    _wasSignedIn = signedInNow;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<FarmoraState>(context);
    return ValueListenableBuilder<bool>(
      valueListenable: AuthGate.authFlowInProgress,
      builder: (context, inProgress, _) {
        if (inProgress) return const WelcomeScreen();
        if (state.signedIn) {
          return const HomeScreen();
        }

        if (Firebase.apps.isEmpty) {
          return const Scaffold(
            body: Center(
                child: Text(
                    'Farmora could not connect to Firebase. Please restart the app.')),
          );
        }

        return StreamBuilder<User?>(
          stream: _authChanges,
          builder: (context, snapshot) {
            // Show loading indicator while Firebase initializes
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff1f7a4d),
                  ),
                ),
              );
            }

            // User is signed in → show Home (it loads the profile)
            if (snapshot.hasData) {
              return const HomeScreen();
            }

            // No user → show Welcome / Sign-up screen
            return const WelcomeScreen();
          },
        );
      },
    );
  }
}
