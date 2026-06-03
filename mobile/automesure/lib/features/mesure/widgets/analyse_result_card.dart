import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/mesure_provider.dart';

class AnalyseResultCard extends StatelessWidget {
  final BPCategorie categorie;
  final int systolique;
  final int diastolique;

  const AnalyseResultCard({
    super.key,
    required this.categorie,
    required this.systolique,
    required this.diastolique,
  });

  Color get _color {
    switch (categorie) {
      case BPCategorie.critique:     return AppColors.critique;
      case BPCategorie.hypertension: return AppColors.hypertension;
      case BPCategorie.elevee:       return AppColors.elevee;
      default:                       return AppColors.normale;
    }
  }

  Color get _bgColor {
    switch (categorie) {
      case BPCategorie.critique:     return AppColors.critiqueLight;
      case BPCategorie.hypertension: return AppColors.hypertensionLight;
      case BPCategorie.elevee:       return AppColors.eleveeLight;
      default:                       return AppColors.normaleLight;
    }
  }

  String get _emoji {
    switch (categorie) {
      case BPCategorie.critique:     return '🚨';
      case BPCategorie.hypertension: return '🔴';
      case BPCategorie.elevee:       return '🟡';
      default:                       return '✅';
    }
  }

  String get _label {
    switch (categorie) {
      case BPCategorie.critique:     return 'Tension CRITIQUE';
      case BPCategorie.hypertension: return 'Hypertension';
      case BPCategorie.elevee:       return 'Tension élevée';
      default:                       return 'Tension normale';
    }
  }

  String get _description {
    switch (categorie) {
      case BPCategorie.critique:
        return '$systolique/$diastolique mmHg — Consultez un médecin immédiatement.';
      case BPCategorie.hypertension:
        return '$systolique/$diastolique mmHg — Suivi médical recommandé.';
      case BPCategorie.elevee:
        return '$systolique/$diastolique mmHg — Surveillance conseillée.';
      default:
        return '$systolique/$diastolique mmHg — Dans la plage optimale.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
                Text(
                  _description,
                  style: AppTextStyles.caption.copyWith(color: _color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}