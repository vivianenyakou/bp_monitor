import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/historique_provider.dart';

class BPChart extends StatelessWidget {
  final List<MesureHistorique> mesures;

  const BPChart({super.key, required this.mesures});

  @override
  Widget build(BuildContext context) {
    if (mesures.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Aucune donnée disponible',
            style: AppTextStyles.bodySecondary,
          ),
        ),
      );
    }

    // Prendre les 7 dernières mesures
    final dernieres = mesures.take(7).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('7 derniers jours', style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              )),
              Row(
                children: [
                  _buildLegend('Sys.', AppColors.hypertension),
                  const SizedBox(width: 12),
                  _buildLegend('Dia.', AppColors.primary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 20,
                      getTitlesWidget: (v, _) => Text(
                        '${v.round()}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i >= dernieres.length) {
                          return const SizedBox();
                        }
                        final jours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                        final jour = dernieres[i].priseLE.weekday - 1;
                        return Text(
                          jours[jour % 7],
                          style: AppTextStyles.caption,
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Systolique
                  LineChartBarData(
                    spots: dernieres.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(),
                            e.value.systolique.toDouble())).toList(),
                    isCurved: true,
                    color: AppColors.hypertension,
                    barWidth: 2,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.hypertension,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.hypertension.withOpacity(0.05),
                    ),
                  ),
                  // Diastolique
                  LineChartBarData(
                    spots: dernieres.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(),
                            e.value.diastolique.toDouble())).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
                    dashArray: [5, 3],
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) => Row(
        children: [
          Container(
            width: 16, height: 2,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      );
}