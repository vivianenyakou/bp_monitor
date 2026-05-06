import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/medecin_provider.dart';
import '../widgets/stats_medecin_card.dart';
import '../widgets/patient_critique_card.dart';

class DashboardMedecinScreen extends ConsumerStatefulWidget {
  const DashboardMedecinScreen({super.key});

  @override
  ConsumerState<DashboardMedecinScreen> createState() =>
      _DashboardMedecinScreenState();
}

class _DashboardMedecinScreenState
    extends ConsumerState<DashboardMedecinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medecinProvider.notifier).charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medecinProvider);
    final user  = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(medecinProvider.notifier).charger(),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [

              // Header
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nomComplet.isNotEmpty == true
                                ? 'Dr. ${user!.nomComplet}'
                                : 'Dr. ${user?.username ?? ''}',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Tableau de bord',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Badge alertes
                          if (state.nombreCritiques > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color:  AppColors.critique,
                                shape:  BoxShape.circle,
                              ),
                              child: Text(
                                '${state.nombreCritiques}',
                                style: AppTextStyles.caption.copyWith(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // Avatar
                          GestureDetector(
                            onTap: () => context.go('/profil'),
                            child: Container(
                              width:  44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Stats
                    StatsMedecinCard(
                      nombrePatients:    state.nombrePatients,
                      nombreCritiques:   state.nombreCritiques,
                      nombreASurveiller: state.nombreASurveiller,
                    ),
                    const SizedBox(height: 24),

                    // Alertes critiques
                    if (state.alertesCritiques.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('🚨'),
                          const SizedBox(width: 8),
                          Text(
                            'Alertes critiques',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.critique,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...state.alertesCritiques.map(
                        (a) => PatientCritiqueCard(
                          alerte:      a,
                          onAcquitter: () => _acquitter(context, a),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // À surveiller
                    if (state.alertesASurveiller.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('👁️'),
                          const SizedBox(width: 8),
                          Text(
                            'À surveiller',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.elevee,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...state.alertesASurveiller.map(
                        (a) => PatientCritiqueCard(
                          alerte:      a,
                          onAcquitter: () => _acquitter(context, a),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Aucune alerte
                    if (state.alertesCritiques.isEmpty &&
                        state.alertesASurveiller.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              '✅',
                              style: TextStyle(fontSize: 60),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune alerte active',
                              style: AppTextStyles.heading3,
                            ),
                            Text(
                              'Tous vos patients sont sous contrôle.',
                              style: AppTextStyles.bodySecondary,
                            ),
                          ],
                        ),
                      ),

                    // Bouton invitation
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => _genererInvitation(context),
                      icon: const Icon(
                        Icons.person_add_outlined,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Inviter un patient',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom nav médecin
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySurface,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/medecin/dashboard'); break;
            case 1: context.go('/medecin/patients');  break;
            case 2: context.go('/medecin/stats');     break;
            case 3: context.go('/medecin/dashboard'); break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label:        'Accueil',
          ),
          NavigationDestination(
            icon:         Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label:        'Patients',
          ),
          NavigationDestination(
            icon:         Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label:        'Stats',
          ),
          NavigationDestination(
            icon:         Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label:        'Alertes',
          ),
        ],
      ),
    );
  }

  Future<void> _acquitter(BuildContext context, alerte) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Acquitter l\'alerte'),
        content: const Text(
          'Confirmez-vous avoir pris en charge cette alerte ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final nom = user.nomComplet.isNotEmpty
          ? 'Dr. ${user.nomComplet}'
          : 'Dr. ${user.username}';
      await ref.read(medecinProvider.notifier).acquitter(alerte.id, nom);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('✅ Alerte acquittée'),
            backgroundColor: AppColors.normale,
          ),
        );
      }
    }
  }

  Future<void> _genererInvitation(BuildContext context) async {
    try {
      await ref.read(medecinProvider.notifier).genererInvitation();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('✅ Code généré'),
            content: const Text(
              'Le code d\'invitation a été généré.\n'
              'Consultez le Swagger pour récupérer le code.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Erreur : $e'),
            backgroundColor: AppColors.critique,
          ),
        );
      }
    }
  }
}