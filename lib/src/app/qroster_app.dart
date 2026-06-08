import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/qroster_controller.dart';
import '../ui/home_screen.dart';
import '../ui/onboarding_screen.dart';

class QrosterApp extends StatelessWidget {
  const QrosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q名册',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6FA5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: CircleBorder(),
        ),
      ),
      home: Consumer<QrosterController>(
        builder: (context, controller, _) {
          if (!controller.isLoaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return controller.settings.onboardingCompleted
              ? const HomeScreen()
              : const OnboardingScreen();
        },
      ),
    );
  }
}
