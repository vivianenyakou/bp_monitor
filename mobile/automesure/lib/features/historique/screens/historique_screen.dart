import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/bp_bottom_nav.dart';
import '../providers/historique_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/bp_chart.dart';
import '../widgets/session_card.dart';

class HistoriqueScreen extends ConsumerStatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  ConsumerState<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends ConsumerState<HistoriqueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(historiqueProvider.notifier).charger(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historiqueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${state.mesures.length} mesures ce mois',
              style: AppTextStyles.caption,
            ),
            Text('Historique', style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _charger,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Stats globales
                    StatsCard(
                      moyenneSys:    state.moyenneSys,
                      moyenneDia:    state.moyenneDia,
                      moyennePouls:  state.moyennePouls,
                      nombreMesures: state.mesures.length,
                    ),
                    const SizedBox(height: 16),

                    // Graphique
                    BPChart(mesures: state.mesures),
                    const SizedBox(height: 24),

                    // Sessions récentes
                    Text(
                      'Sessions récentes',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 12),

                    if (state.sessions.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Text('📊',
                                style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune session enregistrée',
                              style: AppTextStyles.bodySecondary,
                            ),
                          ],
                        ),
                      )
                    else
                      ...state.sessions
                          .map((s) => SessionCard(session: s))
                          .toList(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BPBottomNav(currentIndex: 2),
    );
  }
}