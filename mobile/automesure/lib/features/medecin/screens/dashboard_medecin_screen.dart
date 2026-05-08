import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/models/auth_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/bp_bottom_nav.dart';
import '../../profil/widgets/profil_menu_button.dart';
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
                  color: AppColors.background,
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Tableau de bord',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.textPrimary,
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
                         const ProfilMenuButton(),

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

                    // Code invitation actif
                    if (state.aCodeActif) ...[
                      const SizedBox(height: 24),
                      _CodeInvitationCard(
                        code:      state.codeInvitation!,
                        expireLE:  state.invitationExpireLE!,
                      ),
                    ],

                    // Bouton invitation
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _genererInvitation(context),
                      icon: const Icon(
                        Icons.person_add_outlined,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        state.aCodeActif ? 'Générer un nouveau code' : 'Inviter un patient',
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
                    // Menu Admin — visible uniquement si admin ou super_admin
                    if (user?.hasAdminAccess == true) ...[
                      const SizedBox(height: 24),
                      _buildSectionAdmin(context, user!),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const BPBottomNav(currentIndex: 0),
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
      if (!context.mounted) return;
      final state = ref.read(medecinProvider);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Code d\'invitation généré'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color:        AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.codeInvitation ?? '',
                  style: AppTextStyles.heading2.copyWith(
                    color:       AppColors.primary,
                    letterSpacing: 6,
                    fontWeight:  FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Valable 48h — communiquez ce code à votre patient.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
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

class _CodeInvitationCard extends StatelessWidget {
  final String code;
  final DateTime expireLE;

  const _CodeInvitationCard({required this.code, required this.expireLE});

  @override
  Widget build(BuildContext context) {
    final heuresRestantes = expireLE.difference(DateTime.now()).inHours;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Code d\'invitation actif',
                style: AppTextStyles.body.copyWith(
                  color:      AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Expire dans ${heuresRestantes}h',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              code,
              style: AppTextStyles.heading2.copyWith(
                color:         AppColors.primary,
                letterSpacing: 8,
                fontWeight:    FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Communiquez ce code à votre patient',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSectionAdmin(BuildContext context, UserModel user) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header section
      Row(
        children: [
          const Text('⚙️'),
          const SizedBox(width: 8),
          Text(
            'Administration',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // Carte menus admin
      Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:     Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [

            // Gérer organisations
            if (user.canGererOrganisations)
              _buildAdminMenuItem(
                icon:     Icons.business_outlined,
                label:    'Gérer les organisations',
                sublabel: 'Cliniques et hôpitaux',
                onTap:    () => context.go('/admin/organisations'),
              ),

            // Gérer utilisateurs
            if (user.canGererUtilisateurs) ...[
              const Divider(height: 1),
              _buildAdminMenuItem(
                icon:     Icons.people_outline,
                label:    'Gérer les utilisateurs',
                sublabel: 'Patients, médecins, admins',
                onTap:    () => context.go('/admin/utilisateurs'),
              ),
            ],

            // Gérer rôles — super admin uniquement
            if (user.isSuperAdmin) ...[
              const Divider(height: 1),
              _buildAdminMenuItem(
                icon:     Icons.admin_panel_settings_outlined,
                label:    'Gérer les rôles',
                sublabel: 'Permissions et accès',
                color:    AppColors.elevee,
                onTap:    () => context.go('/admin/roles'),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

Widget _buildAdminMenuItem({
  required IconData    icon,
  required String      label,
  required String      sublabel,
  required VoidCallback onTap,
  Color?               color,
}) {
  return ListTile(
    onTap: onTap,
    leading: Container(
      width:  40,
      height: 40,
      decoration: BoxDecoration(
        color:        (color ?? AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: color ?? AppColors.primary,
        size:  20,
      ),
    ),
    title: Text(
      label,
      style: AppTextStyles.body.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(sublabel, style: AppTextStyles.caption),
    trailing: const Icon(
      Icons.arrow_forward_ios,
      size:  16,
      color: AppColors.textSecondary,
    ),
  );
}