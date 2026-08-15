import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/farmora_state.dart';
import 'features/auth/presentation/auth_gate.dart';

class FarmoraApp extends StatelessWidget {
  const FarmoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FarmoraState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Farmora',
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}
