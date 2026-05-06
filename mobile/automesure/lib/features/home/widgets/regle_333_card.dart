import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class Regle333Card extends StatelessWidget {
  const Regle333Card({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Règle 3-3-3', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildItem('3', 'jours\nconsécutifs', '📆', [true, true, false]),
            const SizedBox(width: 8),
            _buildItem('3', 'mesures/jour', '📊', [true, true, true]),
            const SizedBox(width: 8),
            _buildItem('3', 'semaines\nsuivi', '📅', [true, false, false]),
          ],
        ),
      ],
    );
  }

  Widget _buildItem(
    String value,
    String label,
    String emoji,
    List<bool> dots,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(value,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dots
                  .map((done) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.primary
                              : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}