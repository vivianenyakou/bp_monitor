import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/bp_bottom_nav.dart';
import '../../medecin/providers/medecin_provider.dart';
import '../providers/profil_provider.dart';
import '../widgets/profil_header.dart';
import '../widgets/profil_info_card.dart';
import '../widgets/choisir_medecin_sheet.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.isPatient) {
      await ref.read(profilProvider.notifier).charger(user.id);
    }
    if (user.isMedecin) {
      await ref.read(medecinProvider.notifier).charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go(
            user.isMedecin ? '/medecin/dashboard' : '/home',
          ),
        ),
        title: Text(
          'Mon profil',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ProfilHeader(user: user),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _charger,
                color:     AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (user.isPatient)  ..._corpsPatient(context, user),
                      if (user.isMedecin)  ..._corpsMedecin(context, user),
                      if (user.isAdmin || user.isSuperAdmin) ..._corpsAdmin(context, user),

                      const SizedBox(height: 16),
                      _boutonDeconnexion(context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BPBottomNav(currentIndex: 0),
    );
  }

  // ── PATIENT ──────────────────────────────────────────────────────────────

  List<Widget> _corpsPatient(BuildContext context, user) {
    final state = ref.watch(profilProvider);

    return [
      if (state.success != null)
        Container(
          padding: const EdgeInsets.all(12),
          margin:  const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:        AppColors.normaleLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.normale),
              const SizedBox(width: 8),
              Text(state.success!, style: AppTextStyles.body.copyWith(
                color: AppColors.normale,
              )),
            ],
          ),
        ),

      ProfilInfoCard(
        title: 'Informations personnelles',
        items: [
          ProfilInfoItem(
            icon:  Icons.person_outline,
            label: 'Nom complet',
            value: user.nomComplet.isNotEmpty ? user.nomComplet : user.username,
          ),
          ProfilInfoItem(icon: Icons.email_outlined,   label: 'Email',      value: user.email),
          ProfilInfoItem(icon: Icons.phone_outlined,   label: 'Téléphone',  value: user.phoneNumber),
        ],
        onEdit: () => _modifierProfilPatient(context, state, user.id),
      ),

      ProfilInfoCard(
        title: 'Informations médicales',
        items: [
          ProfilInfoItem(icon: Icons.wc_outlined,        label: 'Genre',              value: state.profil?.gender),
          ProfilInfoItem(icon: Icons.cake_outlined,       label: 'Date de naissance',  value: state.profil?.birthDate),
          ProfilInfoItem(icon: Icons.bloodtype_outlined,  label: 'Groupe sanguin',     value: state.profil?.bloodGroup),
          ProfilInfoItem(icon: Icons.location_on_outlined,label: 'Adresse',            value: state.profil?.address),
          ProfilInfoItem(icon: Icons.emergency_outlined,  label: 'Contact d\'urgence', value: state.profil?.emergencyContact),
        ],
        onEdit: () => _modifierProfilPatient(context, state, user.id),
      ),

      ProfilInfoCard(
        title: 'Médecin référent',
        items: [
          ProfilInfoItem(
            icon:  Icons.medical_services_outlined,
            label: 'Médecin',
            value: state.profil?.medecinNomComplet ??
                (state.profil?.medecinId != null ? 'Médecin assigné' : 'Aucun médecin assigné'),
          ),
        ],
        onEdit: () => _choisirMedecin(context, user.id),
      ),

      if (state.profil?.medecinId == null)
        SizedBox(
          width:  double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _choisirMedecin(context, user.id),
            icon:  const Icon(Icons.person_add_outlined, color: AppColors.primary),
            label: Text('Choisir mon médecin',
                style: AppTextStyles.body.copyWith(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side:  const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
    ];
  }

  // ── MÉDECIN ───────────────────────────────────────────────────────────────

  List<Widget> _corpsMedecin(BuildContext context, user) {
    final medecinState = ref.watch(medecinProvider);

    return [
      ProfilInfoCard(
        title: 'Informations personnelles',
        items: [
          ProfilInfoItem(
            icon:  Icons.person_outline,
            label: 'Nom complet',
            value: user.nomComplet.isNotEmpty
                ? 'Dr. ${user.nomComplet}'
                : 'Dr. ${user.username}',
          ),
          ProfilInfoItem(icon: Icons.email_outlined, label: 'Email',     value: user.email),
          ProfilInfoItem(icon: Icons.phone_outlined, label: 'Téléphone', value: user.phoneNumber),
        ],
      ),

      ProfilInfoCard(
        title: 'Activité',
        items: [
          ProfilInfoItem(
            icon:  Icons.people_outline,
            label: 'Patients suivis',
            value: '${medecinState.nombrePatients} patient(s)',
          ),
          ProfilInfoItem(
            icon:  Icons.notifications_active_outlined,
            label: 'Alertes critiques',
            value: medecinState.nombreCritiques > 0
                ? '${medecinState.nombreCritiques} alerte(s) en cours'
                : 'Aucune alerte critique',
          ),
          ProfilInfoItem(
            icon:  Icons.visibility_outlined,
            label: 'À surveiller',
            value: medecinState.nombreASurveiller > 0
                ? '${medecinState.nombreASurveiller} patient(s)'
                : 'Aucun',
          ),
        ],
      ),

      if (user.organisationId != null)
        ProfilInfoCard(
          title: 'Organisation',
          items: [
            ProfilInfoItem(
              icon:  Icons.local_hospital_outlined,
              label: 'ID Organisation',
              value: 'Org. #${user.organisationId}',
            ),
          ],
        ),

      // Liste des patients suivis
      if (medecinState.patients.isNotEmpty) ...[
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Patients suivis (${medecinState.patients.length})',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...medecinState.patients.map(
                (p) => ListTile(
                  dense:   true,
                  leading: CircleAvatar(
                    radius:          18,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      _initiales(p.nomComplet),
                      style: AppTextStyles.caption.copyWith(
                        color:      AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    p.nomComplet,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: p.telephone != null
                      ? Text(p.telephone!, style: AppTextStyles.caption)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  // ── ADMIN / SUPER ADMIN ───────────────────────────────────────────────────

  List<Widget> _corpsAdmin(BuildContext context, user) {
    return [
      ProfilInfoCard(
        title: 'Informations personnelles',
        items: [
          ProfilInfoItem(
            icon:  Icons.person_outline,
            label: 'Nom complet',
            value: user.nomComplet.isNotEmpty ? user.nomComplet : user.username,
          ),
          ProfilInfoItem(icon: Icons.email_outlined, label: 'Email',     value: user.email),
          ProfilInfoItem(icon: Icons.phone_outlined, label: 'Téléphone', value: user.phoneNumber),
        ],
      ),

      ProfilInfoCard(
        title: 'Accès & permissions',
        items: [
          ProfilInfoItem(
            icon:  Icons.shield_outlined,
            label: 'Rôle',
            value: user.roles.map((r) => r.toUpperCase()).join(', '),
          ),
          if (user.organisationId != null)
            ProfilInfoItem(
              icon:  Icons.local_hospital_outlined,
              label: 'Organisation',
              value: 'Org. #${user.organisationId}',
            ),
          ProfilInfoItem(
            icon:  Icons.admin_panel_settings_outlined,
            label: 'Gestion utilisateurs',
            value: user.canGererUtilisateurs ? 'Autorisé' : 'Non autorisé',
          ),
          ProfilInfoItem(
            icon:  Icons.business_outlined,
            label: 'Gestion organisations',
            value: user.canGererOrganisations ? 'Autorisé' : 'Non autorisé',
          ),
          ProfilInfoItem(
            icon:  Icons.policy_outlined,
            label: 'Gestion des rôles',
            value: user.canGererRoles ? 'Autorisé' : 'Non autorisé',
          ),
        ],
      ),

      SizedBox(
        width:  double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => context.go('/admin'),
          icon:  const Icon(Icons.settings, color: Colors.white),
          label: Text('Espace administrateur',
              style: AppTextStyles.body.copyWith(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ];
  }

  // ── ACTIONS COMMUNES ──────────────────────────────────────────────────────

  Widget _boutonDeconnexion(BuildContext context) => SizedBox(
        width:  double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => _deconnecter(context),
          icon:  const Icon(Icons.logout, color: AppColors.critique),
          label: Text('Se déconnecter',
              style: AppTextStyles.body.copyWith(color: AppColors.critique)),
          style: OutlinedButton.styleFrom(
            side:  const BorderSide(color: AppColors.critique),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  void _choisirMedecin(BuildContext context, int patientId) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => ChoisirMedecinSheet(patientId: patientId),
    );
  }

  void _modifierProfilPatient(BuildContext context, ProfilState state, int patientId) {
    final genderCtrl  = TextEditingController(text: state.profil?.gender);
    final addressCtrl = TextEditingController(text: state.profil?.address);
    final urgenceCtrl = TextEditingController(text: state.profil?.emergencyContact);

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          left:   24,
          right:  24,
          top:    24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier le profil', style: AppTextStyles.heading3),
            const SizedBox(height: 24),
            _editField('Genre',             genderCtrl,  Icons.wc_outlined),
            const SizedBox(height: 12),
            _editField('Adresse',           addressCtrl, Icons.location_on_outlined),
            const SizedBox(height: 12),
            _editField('Contact d\'urgence', urgenceCtrl, Icons.emergency_outlined),
            const Spacer(),
            SizedBox(
              width:  double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final ok = await ref.read(profilProvider.notifier).mettreAJour(
                    patientId:        patientId,
                    gender:           genderCtrl.text,
                    address:          addressCtrl.text,
                    emergencyContact: urgenceCtrl.text,
                  );
                  if (ok && context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Enregistrer',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSecondary),
              filled:     true,
              fillColor:  AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      );

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'P';
  }

  Future<void> _deconnecter(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:   const Text('Se déconnecter'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critique),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}
