import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class StatsMedecinCard extends StatelessWidget {
  final int nombrePatients;
  final int nombreCritiques;
  final int nombreASurveiller;

  const StatsMedecinCard({
    super.key,
    required this.nombrePatients,
    required this.nombreCritiques,
    required this.nombreASurveiller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStat(
          'PATIENTS',
          '$nombrePatients',
          'suivis',
          AppColors.primary,
          AppColors.primarySurface,
          Icons.people_outline,
        ),
        const SizedBox(width: 8),
        _buildStat(
          'ALERTES',
          '$nombreCritiques',
          'critiques',
          AppColors.critique,
          AppColors.critiqueLight,
          Icons.warning_amber_outlined,
        ),
        const SizedBox(width: 8),
        _buildStat(
          'À SURVEILLER',
          '$nombreASurveiller',
          'élevés',
          AppColors.elevee,
          AppColors.eleveeLight,
          Icons.visibility_outlined,
        ),
      ],
    );
  }

  Widget _buildStat(
    String label,
    String value,
    String sublabel,
    Color color,
    Color bgColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(color: color),
            ),
            Text(
              sublabel,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}