import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/widgets/bp_bottom_nav.dart';
import '../providers/medecin_provider.dart';
import '../widgets/stats_medecin_card.dart';

class StatsMedecinScreen extends ConsumerStatefulWidget {
  const StatsMedecinScreen({super.key});

  @override
  ConsumerState<StatsMedecinScreen> createState() => _StatsMedecinScreenState();
}

class _StatsMedecinScreenState extends ConsumerState<StatsMedecinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medecinProvider.notifier).charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medecinProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/medecin/dashboard'),
        ),
        title: Text(
          'Statistiques',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(medecinProvider.notifier).charger(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résumé global
                    StatsMedecinCard(
                      nombrePatients:    state.nombrePatients,
                      nombreCritiques:   state.nombreCritiques,
                      nombreASurveiller: state.nombreASurveiller,
                    ),
                    const SizedBox(height: 24),

                    // Répartition alertes
                    _sectionTitle('Alertes actives'),
                    const SizedBox(height: 12),
                    _alertesSummary(state),
                    const SizedBox(height: 24),

                    // Liste patients
                    _sectionTitle(
                      'Mes patients (${state.patients.length})',
                    ),
                    const SizedBox(height: 12),
                    if (state.patients.isEmpty)
                      _emptyCard('Aucun patient assigné pour le moment.')
                    else
                      ...state.patients.map((p) => _patientRow(p)),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BPBottomNav(currentIndex: 2),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.bold,
          fontSize:   16,
        ),
      );

  Widget _alertesSummary(MedecinState state) {
    final total =
        state.alertesCritiques.length + state.alertesASurveiller.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _alerteRow(
            '🚨 Critiques',
            state.alertesCritiques.length,
            AppColors.critique,
          ),
          const SizedBox(height: 10),
          _alerteRow(
            '⚠️ À surveiller',
            state.alertesASurveiller.length,
            AppColors.elevee,
          ),
          const Divider(height: 24),
          _alerteRow('Total non acquittées', total, AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _alerteRow(String label, int count, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.body.copyWith(
                color:      color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );

  Widget _patientRow(PatientMedecin p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primarySurface,
            child: Text(
              _initiales(p.nomComplet),
              style: AppTextStyles.body.copyWith(
                color:      AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            p.nomComplet,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: p.telephone != null
              ? Text(p.telephone!, style: AppTextStyles.caption)
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _emptyCard(String message) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: AppTextStyles.bodySecondary),
      );

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'P';
  }
}
