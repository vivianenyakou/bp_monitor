import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const BPMonitorApp());
}

final _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // On ajoutera les autres routes au fur et à mesure
    GoRoute(
      path: '/login',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Login — à venir')),
      ),
    ),
  ],
);

class BPMonitorApp extends StatelessWidget {
  const BPMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BP Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}