import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class StatsCard extends StatelessWidget {
  final double moyenneSys;
  final double moyenneDia;
  final double? moyennePouls;
  final int nombreMesures;

  const StatsCard({
    super.key,
    required this.moyenneSys,
    required this.moyenneDia,
    this.moyennePouls,
    required this.nombreMesures,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$nombreMesures mesures ce mois',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat(
                'MOY. SYS.',
                '${moyenneSys.round()}',
                'mmHg',
              ),
              _buildDivider(),
              _buildStat(
                'MOY. DIA.',
                '${moyenneDia.round()}',
                'mmHg',
              ),
              _buildDivider(),
              _buildStat(
                'MOY. POULS',
                moyennePouls != null
                    ? '${moyennePouls!.round()}'
                    : '—',
                'bpm',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: Colors.white),
          ),
          Text(
            unit,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
        width: 1,
        height: 40,
        color: Colors.white24,
      );
}