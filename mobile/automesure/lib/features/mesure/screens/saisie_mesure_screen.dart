import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/bp_bottom_nav.dart';
import '../providers/mesure_provider.dart';
import '../widgets/bp_input_field.dart';
import '../widgets/analyse_result_card.dart';

class SaisieMesureScreen extends ConsumerWidget {
  const SaisieMesureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mesureProvider);
    final notifier = ref.read(mesureProvider.notifier);
    final user = ref.read(authProvider).user;

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
              'Mesure ${state.numeroMesure}/3 aujourd\'hui',
              style: AppTextStyles.caption,
            ),
            Text('Nouvelle mesure', style: AppTextStyles.heading3),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Indicateur analyse temps réel
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.normale,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Entrez vos valeurs — analyse en temps réel',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sélecteur Jour + Période
            Row(
              children: [
                Expanded(
                  child: _buildSelector(
                    label: 'Jour',
                    value: state.jour,
                    options: [1, 2, 3],
                    labels: ['Jour 1', 'Jour 2', 'Jour 3'],
                    onChanged: notifier.mettreAJourJour,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelector(
                    label: 'Période',
                    value: state.periode == 'matin' ? 0 : 1,
                    options: [0, 1],
                    labels: ['🌅 Matin', '🌙 Soir'],
                    onChanged: (v) => notifier.mettreAJourPeriode(
                      v == 0 ? 'matin' : 'soir',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Systolique
            BPInputField(
              label: 'SYSTOLIQUE',
              sublabel: 'Pression maximale',
              value: state.systolique,
              min: 60,
              max: 250,
              unit: 'mmHg',
              unitColor: AppColors.hypertension,
              onChanged: notifier.mettreAJourSystolique,
            ),
            const SizedBox(height: 12),

            // Diastolique
            BPInputField(
              label: 'DIASTOLIQUE',
              sublabel: 'Pression minimale',
              value: state.diastolique,
              min: 40,
              max: 150,
              unit: 'mmHg',
              unitColor: AppColors.primary,
              onChanged: notifier.mettreAJourDiastolique,
            ),
            const SizedBox(height: 12),

            // Pouls
            BPInputField(
              label: 'POULS',
              sublabel: 'Fréquence cardiaque',
              value: state.pouls ?? 70,
              min: 30,
              max: 220,
              unit: 'bpm',
              unitColor: Colors.pink,
              onChanged: notifier.mettreAJourPouls,
            ),
            const SizedBox(height: 16),

            // Analyse temps réel
            AnalyseResultCard(
              categorie: state.categorieActuelle,
              systolique: state.systolique,
              diastolique: state.diastolique,
            ),
            const SizedBox(height: 16),

            // Erreur
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.critiqueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.error!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.critique,
                  ),
                ),
              ),

            // Bouton enregistrer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        if (user == null) return;
                        final ok = await ref
                            .read(mesureProvider.notifier)
                            .enregistrer(user.id);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✅ Mesure enregistrée !',
                              ),
                              backgroundColor: AppColors.normale,
                            ),
                          );
                          context.go('/home');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Enregistrer la mesure',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const BPBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSelector({
    required String label,
    required int value,
    required List<int> options,
    required List<String> labels,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Row(
            children: List.generate(options.length, (i) {
              final selected = value == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(options[i]),
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 4 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labels[i],
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}