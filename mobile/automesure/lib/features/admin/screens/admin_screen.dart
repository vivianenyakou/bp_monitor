
import 'package:automesure/core/constants/app_colors.dart';
import 'package:automesure/features/admin/screens/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_text_styles.dart' show AppTextStyles;
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../home/widgets/bp_bottom_nav.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}
class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(homeProvider.notifier).charger(user.id);
    }
  }

@override
  Widget build(BuildContext context) {
    final auth  = ref.watch(authProvider);
    final user  = auth.user;

    return Scaffold(
      drawer:  const AdminDrawer(),
      appBar: AppBar(
        title: Center(
          child: Text(
            'Bienvenue, ${[user?.firstName, user?.lastName,].where((e) => e != null && e.isNotEmpty).join(' ')}',
            style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20),
           ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profil'),
          ),
        ],
        ),
      body: const Center(
        child: Text('Espace administrateur'),
      ),
     bottomNavigationBar: const BPAdminBottomNav(currentIndex: 0),
    );
  }
}