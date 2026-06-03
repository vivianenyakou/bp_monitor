import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../alerte/providers/alertes_provider.dart';
import 'package:url_launcher/url_launcher.dart';


class PatientCritiqueCard extends StatelessWidget {
  final Alerte alerte;
  final VoidCallback? onAcquitter;

  const PatientCritiqueCard({
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

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'P';
  }

  @override
  Widget build(BuildContext context) {
    final nom = alerte.patientNomComplet ?? 'Patient #${alerte.patientId}';
    final tel = alerte.patientTelephone;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: _color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Avatar initiales
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:  _color.withOpacity(0.2),
                    shape:  BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initiales(nom),
                      style: AppTextStyles.caption.copyWith(
                        color:      _color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Nom + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

          // Corps — valeurs BP + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildBPValue(
                      'Sys.',
                      '${alerte.systolique}',
                      AppColors.hypertension,
                    ),
                    const SizedBox(width: 20),
                    _buildBPValue(
                      'Dia.',
                      '${alerte.diastolique}',
                      AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Boutons actions
                Row(
                  children: [
                    if (tel != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _appeler(tel),
                          icon: const Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Appeler',
                            style: AppTextStyles.body.copyWith(
                              color:    AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAcquitter,
                        icon: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Acquitter',
                          style: AppTextStyles.body.copyWith(
                            color:    Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding:         const EdgeInsets.symmetric(vertical: 8),
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
