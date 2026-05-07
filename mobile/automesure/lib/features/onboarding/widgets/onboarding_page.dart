import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class OnboardingData {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final List<String> steps;
  final bool showBpExample;
  final bool showRegle333;
  final bool showCategories;

  const OnboardingData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    this.steps = const [],
    this.showBpExample = false,
    this.showRegle333 = false,
    this.showCategories = false,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Emoji illustration
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Titre
          Text(
            data.title,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            data.description,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Étapes
          if (data.steps.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: data.steps
                    .map((step) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  step,
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Exemple BP
          if (data.showBpExample) _buildBpExample(),

          // Règle 3-3-3
          if (data.showRegle333) _buildRegle333(),

          // Catégories
          if (data.showCategories) _buildCategories(),
        ],
      ),
    );
  }

  Widget _buildBpExample() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Exemple de lecture', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBpValue('120', 'SYSTOLIQUE', AppColors.hypertension),
              Text(
                '/',
                style: AppTextStyles.bpValue.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              _buildBpValue('80', 'DIASTOLIQUE', AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.normaleLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '💚 72 bpm — Pouls normal',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.normale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpValue(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bpValue.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: color),
        ),
        Text(
          'mmHg',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildRegle333() {
    return Row(
      children: [
        _buildRegle333Card('3', 'jours\nconsécutifs', '📆'),
        const SizedBox(width: 8),
        _buildRegle333Card('3', 'mesures\n/jour', '📊'),
        const SizedBox(width: 8),
        _buildRegle333Card('1min', 'entre\nchaque', '⏱️'),
      ],
    );
  }

  Widget _buildRegle333Card(String value, String label, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {
        'label': 'Normale',
        'range': '< 130 / 85 mmHg',
        'color': AppColors.normale,
        'bg': AppColors.normaleLight,
        'emoji': '💚',
      },
      {
        'label': 'Élevée',
        'range': '130-139 / 85-89 mmHg',
        'color': AppColors.elevee,
        'bg': AppColors.eleveeLight,
        'emoji': '🟡',
      },
      {
        'label': 'Hypertension',
        'range': '140-179 / 90-109 mmHg',
        'color': AppColors.hypertension,
        'bg': AppColors.hypertensionLight,
        'emoji': '🔴',
      },
      {
        'label': 'Critique',
        'range': '≥ 180 / ≥ 110 mmHg',
        'color': AppColors.critique,
        'bg': AppColors.critiqueLight,
        'emoji': '🚨',
      },
    ];

    return Column(
      children: categories.map((cat) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12,
          ),
          decoration: BoxDecoration(
            color: cat['bg'] as Color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                cat['emoji'] as String,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat['label'] as String,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cat['color'] as Color,
                    ),
                  ),
                  Text(
                    cat['range'] as String,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}