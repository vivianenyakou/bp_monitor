import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/bp_bottom_nav.dart';
import '../providers/alertes_provider.dart';
import '../widgets/alerte_card.dart';

class AlertesScreen extends ConsumerStatefulWidget {
  const AlertesScreen({super.key});

  @override
  ConsumerState<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends ConsumerState<AlertesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertesProvider.notifier).charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(alertesProvider);
    final user   = ref.watch(authProvider).user;
    final isMedecin = user?.isMedecin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text('Alertes', style: AppTextStyles.heading2),
            if (state.critiques.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.critique,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.critiques.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(alertesProvider.notifier).charger(),
              color: AppColors.primary,
              child: state.alertes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🔔',
                            style: TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune alerte',
                            style: AppTextStyles.heading3,
                          ),
                          Text(
                            'Votre tension est sous contrôle 👍',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [

                        // Alertes critiques en premier
                        if (state.critiques.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text('🚨'),
                              const SizedBox(width: 8),
                              Text(
                                'Alertes critiques',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.critique,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...state.critiques.map((a) => AlerteCard(
                                alerte: a,
                                onAcquitter: isMedecin
                                    ? () => _acquitter(context, a)
                                    : null,
                              )),
                          const SizedBox(height: 16),
                        ],

                        // Toutes les alertes
                        Text(
                          'Historique des alertes',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 8),
                        ...state.alertes
                            .where((a) => !a.estCritique || a.estAquittee)
                            .map((a) => AlerteCard(
                                  alerte: a,
                                  onAcquitter: isMedecin && !a.estAquittee
                                      ? () => _acquitter(context, a)
                                      : null,
                                )),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
      bottomNavigationBar: const BPBottomNav(currentIndex: 3),
    );
  }

  Future<void> _acquitter(BuildContext context, Alerte alerte) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Acquitter l\'alerte'),
        content: Text(
          'Confirmer l\'acquittement de l\'alerte pour le patient ${alerte.patientId} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(alertesProvider.notifier).acquitter(
            alerte.id,
            user.nomComplet.isNotEmpty ? user.nomComplet : user.username,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alerte acquittée'),
            backgroundColor: AppColors.normale,
          ),
        );
      }
    }
  }
}