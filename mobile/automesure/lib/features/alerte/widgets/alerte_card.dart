import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/alertes_provider.dart';

class AlerteCard extends StatelessWidget {
  final Alerte alerte;
  final VoidCallback? onAcquitter;

  const AlerteCard({
    super.key,
    required this.alerte,
    this.onAcquitter,
  });

  Color get _color {
    if (alerte.estCritique) return AppColors.critique;
    return AppColors.elevee;
  }

  Color get _bgColor {
    if (alerte.estCritique) return AppColors.critiqueLight;
    return AppColors.eleveeLight;
  }

  String get _emoji {
    if (alerte.estCritique) return '🚨';
    return '⚠️';
  }

  String get _niveauLabel {
    if (alerte.estCritique) return 'Critique';
    return 'Avertissement';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1)    return 'Hier';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: alerte.estCritique && !alerte.estAquittee
            ? Border.all(color: _color.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header coloré
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(_emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      _niveauLabel,
                      style: AppTextStyles.body.copyWith(
                        color:      _color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (alerte.estAquittee)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:        AppColors.normaleLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✅ Acquittée',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.normale,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(alerte.declencheeLE),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Corps
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Valeurs BP
                Row(
                  children: [
                    _buildBPValue(
                      'Systolique',
                      '${alerte.systolique}',
                      AppColors.hypertension,
                    ),
                    const SizedBox(width: 24),
                    _buildBPValue(
                      'Diastolique',
                      '${alerte.diastolique}',
                      AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  alerte.message,
                  style: AppTextStyles.bodySecondary,
                ),

                // Acquittée par
                if (alerte.estAquittee && alerte.acquitteePar != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Acquittée par ${alerte.acquitteePar}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.normale,
                    ),
                  ),
                ],

                // Bouton acquitter (médecin)
                if (!alerte.estAquittee && onAcquitter != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onAcquitter,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Acquitter',
                        style: AppTextStyles.body.copyWith(color: _color),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBPValue(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: color),
          ),
          Text('mmHg', style: AppTextStyles.caption),
        ],
      );
}