import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    const OnboardingData(
      emoji: '🩺',
      title: 'Bienvenue sur Auto-mesure Santé',
      description:
          'Votre assistant de suivi de tension artérielle.\n'
          'Apprenez à mesurer votre tension correctement.',
      color: AppColors.primary,
    ),
    const OnboardingData(
      emoji: '🪑',
      title: 'Préparez-vous',
      description:
          'Asseyez-vous confortablement.\n'
          'Reposez-vous 5 minutes avant la mesure.\n'
          'Ne parlez pas pendant la prise.',
      color: AppColors.primary,
      steps: [
        '✅ Dos droit, pieds à plat',
        '✅ Bras au niveau du cœur',
        '✅ Vessie vide',
        '✅ Pas de café ni cigarette 30 min avant',
      ],
    ),
    const OnboardingData(
      emoji: '💪',
      title: 'Placez le brassard',
      description:
          'Placez le brassard sur le bras gauche,\n'
          '2 à 3 cm au-dessus du coude.',
      color: AppColors.primary,
      steps: [
        '✅ Brassard pas trop serré (1 doigt doit passer)',
        '✅ Repère artère sur la face interne du bras',
        '✅ Paume tournée vers le haut',
        '✅ Bras posé sur une surface plane',
      ],
    ),
    const OnboardingData(
      emoji: '📊',
      title: 'Lisez les chiffres',
      description:
          'Votre tensiomètre affiche deux chiffres.\n'
          'Notez-les soigneusement.',
      color: AppColors.primary,
      steps: [
        '❤️ SYSTOLIQUE — le grand chiffre (ex: 120)',
        '💙 DIASTOLIQUE — le petit chiffre (ex: 80)',
        '💚 POULS — les battements par minute',
      ],
      showBpExample: true,
    ),
    const OnboardingData(
      emoji: '📅',
      title: 'La règle des 3-3-3',
      description:
          'Pour un suivi fiable, suivez la règle médicale recommandée.',
      color: AppColors.primary,
      steps: [
        '🌅 3 mesures le matin — au réveil',
        '🌙 3 mesures le soir — avant de dormir',
        '📆 Pendant 3 jours consécutifs',
        '⏱️ 1 minute entre chaque mesure',
      ],
      showRegle333: true,
    ),
    const OnboardingData(
      emoji: '🎯',
      title: 'Comprenez vos résultats',
      description: 'Voici comment interpréter vos valeurs.',
      color: AppColors.primary,
      showCategories: true,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _skip() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentPage + 1}/${_pages.length}',
                    style: AppTextStyles.caption,
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Passer',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) =>
                    OnboardingPage(data: _pages[i]),
              ),
            ),

            // Indicateurs
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Powered by
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Powered by G-Medic',
                style: TextStyle(
                  fontSize: 11, color: Color(0xFFAAAAAA), letterSpacing: 0.5,
                ),
              ),
            ),

            // Bouton
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1
                        ? 'Suivant'
                        : 'Commencer',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}