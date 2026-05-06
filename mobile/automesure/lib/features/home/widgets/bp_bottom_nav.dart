import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class BPBottomNav extends StatelessWidget {
  final int currentIndex;

  const BPBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primarySurface,
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
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.primary),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.edit_outlined),
          selectedIcon: Icon(Icons.edit, color: AppColors.primary),
          label: 'Saisie',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_outlined),
          selectedIcon: Icon(Icons.show_chart, color: AppColors.primary),
          label: 'Historique',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
          label: 'Alertes',
        ),
      ],
    );
  }
}