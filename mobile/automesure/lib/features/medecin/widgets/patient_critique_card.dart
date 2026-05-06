import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../alerte/providers/alertes_provider.dart';
import 'package:url_launcher/url_launcher.dart';


class PatientCritiqueCard extends StatelessWidget {
  final Alerte alerte;
  final VoidCallback? onAcquitter;
  final String? telephone;

  const PatientCritiqueCard({
    super.key,
    required this.alerte,
    this.onAcquitter,
    this.telephone,
  });

  Color get _color {
    if (alerte.estCritique) return AppColors.critique;
    return AppColors.elevee;
  }

  Color get _bgColor {
    if (alerte.estCritique) return AppColors.critiqueLight;
    return AppColors.eleveeLight;
  }

  String get _niveauLabel {
    if (alerte.estCritique) return 'Critique';
    return 'Élevée';
  }

  String _formatDate(DateTime date) {
    final now  = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'il y a ${diff.inHours}h';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color:   Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
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
              children: [
                // Avatar patient
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:  _color.withOpacity(0.2),
                    shape:  BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'P${alerte.patientId}',
                      style: AppTextStyles.caption.copyWith(
                        color:      _color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info patient
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient #${alerte.patientId}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(alerte.declencheeLE),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),

                // Badge niveau
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:        _color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _niveauLabel,
                    style: AppTextStyles.caption.copyWith(
                      color:      Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Corps — valeurs BP
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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

                // Boutons actions
                Row(
                  children: [
                    // Appeler
                    if (telephone != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _appeler(telephone!),
                          icon: const Icon(
                            Icons.phone,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Appeler',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (telephone != null) const SizedBox(width: 8),

                    // Acquitter
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAcquitter,
                        icon: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Acquitter',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Future<void> _appeler(String tel) async {
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}