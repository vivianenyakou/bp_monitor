import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/historique_provider.dart';

class SessionCard extends StatelessWidget {
  final SessionResume session;

  const SessionCard({super.key, required this.session});

  Color get _color {
    switch (session.categorie) {
      case 'critique':     return AppColors.critique;
      case 'hypertension': return AppColors.hypertension;
      case 'elevee':       return AppColors.elevee;
      default:             return AppColors.normale;
    }
  }

  Color get _bgColor {
    switch (session.categorie) {
      case 'critique':     return AppColors.critiqueLight;
      case 'hypertension': return AppColors.hypertensionLight;
      case 'elevee':       return AppColors.eleveeLight;
      default:             return AppColors.normaleLight;
    }
  }

  String get _label {
    switch (session.categorie) {
      case 'critique':     return 'Critique';
      case 'hypertension': return 'Hypertension';
      case 'elevee':       return 'Élevée';
      default:             return 'Normale';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                    _formatDate(session.date),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${session.nombreMesures} mesures',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label,
                  style: AppTextStyles.caption.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Moyennes
          Row(
            children: [
              _buildMoyenne(
                'Sys. moy.',
                '${session.moyenneSys.round()}',
                AppColors.hypertension,
              ),
              const SizedBox(width: 24),
              _buildMoyenne(
                'Dia. moy.',
                '${session.moyenneDia.round()}',
                AppColors.primary,
              ),
              if (session.moyennePouls != null) ...[
                const SizedBox(width: 24),
                _buildMoyenne(
                  'Pouls',
                  '${session.moyennePouls!.round()}',
                  Colors.pink,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoyenne(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
        ],
      );
}