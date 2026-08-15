import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/farmora_state.dart';
import '../../home/presentation/home_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<FarmoraState>().signedIn;
    return signedIn ? const Home() : const WelcomeScreen();
  }
}
