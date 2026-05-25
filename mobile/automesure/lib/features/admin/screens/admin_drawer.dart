import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.background,
              child:  Icon(Icons.person, color: AppColors.primary, size: 36),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Tableau de bord'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Utilisateurs'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/utilisateurs');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Rôles'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/roles');
            },
          ),
           ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Rôles'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/roles');
            },
          ),
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Organisations'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/organisations');
              },
            ),
          // ListTile(
          //   leading: const Icon(Icons.bar_chart_outlined),
          //   title: const Text('Statistiques'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/admin/statistiques');
          //   },
          // ),
          // ListTile(
          //   leading: const Icon(Icons.settings_outlined),
          //   title: const Text('Paramètres'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/admin/parametres');
          //   },
          // ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}