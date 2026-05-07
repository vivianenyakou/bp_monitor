import 'package:automesure/features/admin/screens/admin_organisations_screen.dart';
import 'package:automesure/features/admin/screens/admin_utilisateurs_screen.dart';
import 'package:automesure/features/alerte/screens/alertes_screen.dart';
import 'package:automesure/features/home/screens/home_screen.dart';
import 'package:automesure/features/mesure/screens/saisie_mesure_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'features/admin/screens/admin_roles_screen.dart';
import 'features/historique/screens/historique_screen.dart';
import 'features/medecin/screens/dashboard_medecin_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/profil/screens/profil_screen.dart';

void main() {
  runApp(const ProviderScope(child: BPMonitorApp()));
}

final _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/saisie',
      builder: (_, __) => const SaisieMesureScreen(),
    ),
    GoRoute(
      path: '/historique',
      builder: (_, __) => const HistoriqueScreen(),
    ),
    GoRoute(
      path: '/alertes',
      builder: (_, __) => const AlertesScreen(),
    ),
    GoRoute(
      path: '/medecin/dashboard',
      builder: (_, __) => const DashboardMedecinScreen(),
    ),
    GoRoute(
      path: '/medecin/patients',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text('Patients — à venir')),
      ),
    ),
    GoRoute(
      path: '/medecin/stats',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text('Stats — à venir')),
      ),
    ),
    GoRoute(
      path: '/profil',
      builder: (_, __) => const ProfilScreen(),
    ),
    GoRoute(
      path: '/admin/organisations',
      builder: (_, __) => const AdminOrganisationsScreen(),
    ),
    GoRoute(
      path: '/admin/utilisateurs',
      builder: (_, __) => const AdminUtilisateursScreen(),
    ),
    GoRoute(
      path: '/admin/roles',
      builder: (_, __) => const AdminRolesScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (_, __) => const AdminRolesScreen(),
    ),
  ],
);

class BPMonitorApp extends StatelessWidget {
  const BPMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AutoMesure de la Pression Artérielle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}