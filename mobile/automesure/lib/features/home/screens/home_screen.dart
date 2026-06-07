import 'package:automesure/features/home/widgets/bp_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/widgets/profil_menu_button.dart';
import '../providers/home_provider.dart';
import '../widgets/derniere_mesure_card.dart';
import '../widgets/progression_card.dart';
import '../widgets/regle_333_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      // patient_id = id du profil patient (à récupérer depuis /auth/me)
      await ref.read(homeProvider.notifier).charger(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = ref.watch(authProvider);
    final state = ref.watch(homeProvider);
    final user  = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          child: CustomScrollView(
            slivers: [

              // Header vert
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue, ${[
                              user?.firstName,
                              user?.lastName,
                            ].where((e) => e != null && e.isNotEmpty).join(' ')}',                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'AutoMesure de la TA',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const ProfilMenuButton(),
                    ],
                  ),
                ),
              ),

              // Contenu
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
              // Card dernière mesure — remonte sur le header
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child:state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DerniereMesureCard(
                            mesure: state.derniereMesure,
                          ),
                    ),

                    const SizedBox(height: 16),

                    // Progression du jour
                    ProgressionCard(
                      nombreMesures: state.nombreMesuresAujourdhui,
                    ),
                    const SizedBox(height: 24),

                    // Règle 3-3-3
                    const Regle333Card(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bouton flottant — Nouvelle mesure
      floatingActionButton: SizedBox(
        height: 56,
        width: 350,
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/saisie'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Nouvelle mesure',
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      bottomNavigationBar: const BPBottomNav(currentIndex: 0),
    );
  }
}