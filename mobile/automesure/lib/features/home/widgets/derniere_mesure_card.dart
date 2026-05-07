import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/home_provider.dart';

class DerniereMesureCard extends StatelessWidget {
  final DerniereMesure? mesure;

  const DerniereMesureCard({super.key, this.mesure});

  Color get _categorieColor {
    switch (mesure?.categorie) {
      case 'critique':     return AppColors.critique;
      case 'hypertension': return AppColors.hypertension;
      case 'elevee':       return AppColors.elevee;
      default:             return AppColors.normale;
    }
  }

  Color get _categorieBg {
    switch (mesure?.categorie) {
      case 'critique':     return AppColors.critiqueLight;
      case 'hypertension': return AppColors.hypertensionLight;
      case 'elevee':       return AppColors.eleveeLight;
      default:             return AppColors.normaleLight;
    }
  }

  String get _categorieLabel {
    switch (mesure?.categorie) {
      case 'critique':     return 'Critique 🚨';
      case 'hypertension': return 'Hypertension';
      case 'elevee':       return 'Élevée';
      default:             return 'Normale';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mesure == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              const Text('📊', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'Aucune mesure encore',
                style: AppTextStyles.body,
              ),
              Text(
                'Prenez votre première mesure',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DERNIÈRE MESURE',
                    style: AppTextStyles.caption.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(mesure!.priseLE),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _categorieBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categorieLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: _categorieColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Valeurs BP
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${mesure!.systolique}',
                style: AppTextStyles.bpValue,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ' / ${mesure!.diastolique}',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8),
                child: Text(
                  'mmHg',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),

          // Pouls
          if (mesure!.pouls != null)
            Row(
              children: [
                const Icon(Icons.favorite,
                    color: AppColors.normale, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${mesure!.pouls} bpm · Pouls',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.normale,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Aujourd\'hui, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day}/${date.month}/${date.year}';
  }
}