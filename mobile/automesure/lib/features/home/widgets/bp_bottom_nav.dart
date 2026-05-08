import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class BPBottomNav extends ConsumerWidget {
  final int currentIndex;

  const BPBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    if (user.isAdmin || user.isSuperAdmin) return _adminNav(context);
    if (user.isMedecin)                    return _medecinNav(context);
    return _patientNav(context);
  }

  NavigationBar _patientNav(BuildContext context) => NavigationBar(
        selectedIndex:    currentIndex,
        backgroundColor:  Colors.white,
        indicatorColor:   AppColors.primarySurface,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');       break;
            case 1: context.go('/saisie');     break;
            case 2: context.go('/historique'); break;
            case 3: context.go('/alertes');    break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label:        'Accueil',
          ),
          NavigationDestination(
            icon:         Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit, color: AppColors.primary),
            label:        'Saisie',
          ),
          NavigationDestination(
            icon:         Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: AppColors.primary),
            label:        'Historique',
          ),
          NavigationDestination(
            icon:         Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label:        'Alertes',
          ),
        ],
      );

  NavigationBar _medecinNav(BuildContext context) => NavigationBar(
        selectedIndex:    currentIndex,
        backgroundColor:  Colors.white,
        indicatorColor:   AppColors.primarySurface,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/medecin/dashboard'); break;
            case 1: context.go('/medecin/patients');  break;
            case 2: context.go('/medecin/stats');     break;
            case 3: context.go('/alertes');            break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label:        'Accueil',
          ),
          NavigationDestination(
            icon:         Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label:        'Patients',
          ),
          NavigationDestination(
            icon:         Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label:        'Stats',
          ),
          NavigationDestination(
            icon:         Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label:        'Alertes',
          ),
        ],
      );

  NavigationBar _adminNav(BuildContext context) => NavigationBar(
        selectedIndex:    currentIndex,
        backgroundColor:  AppColors.background,
        indicatorColor:   AppColors.primarySurface,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/admin');                break;
            case 1: context.go('/admin/roles');          break;
            case 2: context.go('/admin/organisations');  break;
            case 3: context.go('/admin/utilisateurs');   break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label:        'Accueil',
          ),
          NavigationDestination(
            icon:         Icon(Icons.policy_outlined),
            selectedIcon: Icon(Icons.policy, color: AppColors.primary),
            label:        'Rôles',
          ),
          NavigationDestination(
            icon:         Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital, color: AppColors.primary),
            label:        'Organisations',
          ),
          NavigationDestination(
            icon:         Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label:        'Utilisateurs',
          ),
        ],
      );
}
