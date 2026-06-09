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
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  QrosterController? _controller;
  bool _isLoaded = false;
  bool _onboardingCompleted = false;
  bool _syncScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<QrosterController>();
    if (_controller == controller) {
      return;
    }
    _controller?.removeListener(_onControllerChanged);
    _controller = controller..addListener(_onControllerChanged);
    _isLoaded = controller.isLoaded;
    _onboardingCompleted = controller.settings.onboardingCompleted;
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _onboardingCompleted ? const HomeScreen() : const OnboardingScreen();
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final nextLoaded = controller.isLoaded;
    final nextOnboardingCompleted = controller.settings.onboardingCompleted;
    if (nextLoaded == _isLoaded &&
        nextOnboardingCompleted == _onboardingCompleted) {
      return;
    }
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted || _controller == null) {
        return;
      }
      setState(() {
        _isLoaded = _controller!.isLoaded;
        _onboardingCompleted = _controller!.settings.onboardingCompleted;
      });
    });
  }
}
