import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../home/presentation/home_screen.dart';
import 'welcome_screen.dart';
import '../../../providers/farmora_state.dart';

/// AuthGate listens to Firebase Auth state changes.
/// If the user is signed in, show Home; otherwise show WelcomeScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // For testing bypass
    final state = Provider.of<FarmoraState>(context);
    if (state.signedIn) {
      return const HomeScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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

        // User is signed in → show Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // No user → show Welcome / Sign-up screen
        return const WelcomeScreen();
      },
    );
  }
}
