import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/admin_provider.dart';

class AdminUtilisateursScreen extends ConsumerStatefulWidget {
  const AdminUtilisateursScreen({super.key});

  @override
  ConsumerState<AdminUtilisateursScreen> createState() =>
      _AdminUtilisateursScreenState();
}

class _AdminUtilisateursScreenState
    extends ConsumerState<AdminUtilisateursScreen> {
  String _filtre = 'tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).chargerUtilisateurs();
    });
  }

  List<UtilisateurAdmin> get _utilisateursFiltres {
    final tous = ref.read(adminProvider).utilisateurs;
    if (_filtre == 'tous') return tous;
    return tous.where((u) => u.roles.contains(_filtre)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/medecin/dashboard'),
        ),
        title: Text('Utilisateurs', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon:      const Icon(Icons.person_add_outlined,
                color: AppColors.primary),
            onPressed: () => _creerUtilisateur(context),
          ),
        ],
      ),
      body: Column(
        children: [

          // Filtres
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltreChip('tous',    'Tous'),
                  _buildFiltreChip('patient', 'Patients'),
                  _buildFiltreChip('medecin', 'Médecins'),
                  _buildFiltreChip('admin',   'Admins'),
                ],
              ),
            ),
          ),

          // Liste
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(adminProvider.notifier)
                        .chargerUtilisateurs(),
                    color: AppColors.primary,
                    child: _utilisateursFiltres.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun utilisateur',
                              style: AppTextStyles.bodySecondary,
                            ),
                          )
                        : ListView.builder(
                            padding:     const EdgeInsets.all(16),
                            itemCount:   _utilisateursFiltres.length,
                            itemBuilder: (context, i) {
                              final user = _utilisateursFiltres[i];
                              return _UtilisateurCard(utilisateur: user);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltreChip(String value, String label) {
    final selected = _filtre == value;
    return GestureDetector(
      onTap: () => setState(() => _filtre = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color:      selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _creerUtilisateur(BuildContext context) {
    final usernameCtrl = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passCtrl     = TextEditingController();
    final firstCtrl    = TextEditingController();
    final lastCtrl     = TextEditingController();
    final phoneCtrl    = TextEditingController();
    String roleSelectionne = 'patient';

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color:        AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Nouvel utilisateur', style: AppTextStyles.heading3),
                const SizedBox(height: 24),

                // Rôle
                Text('Rôle *', style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 8),
                Row(
                  children: ['patient', 'medecin', 'admin'].map((role) {
                    final selected = roleSelectionne == role;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(
                          () => roleSelectionne = role,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Champs
                Row(
                  children: [
                    Expanded(child: _buildField(
                      'Prénom', firstCtrl, Icons.person_outline,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _buildField(
                      'Nom', lastCtrl, Icons.person_outline,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField('Username *', usernameCtrl,
                    Icons.alternate_email),
                const SizedBox(height: 12),
                _buildField('Email *', emailCtrl,
                    Icons.email_outlined,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildField('Téléphone', phoneCtrl,
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _buildField('Mot de passe *', passCtrl,
                    Icons.lock_outline, obscure: true),
                const SizedBox(height: 24),

                // Erreur
                Consumer(builder: (_, ref, __) {
                  final error = ref.watch(adminProvider).error;
                  if (error == null) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin:  const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:        AppColors.critiqueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(error, style: AppTextStyles.body.copyWith(
                      color: AppColors.critique,
                    )),
                  );
                }),

                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: Consumer(builder: (_, ref, __) {
                    final isSaving = ref.watch(adminProvider).isSaving;
                    return ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (usernameCtrl.text.isEmpty ||
                            emailCtrl.text.isEmpty   ||
                            passCtrl.text.isEmpty) return;
                        final ok = await ref
                            .read(adminProvider.notifier)
                            .creerUtilisateur(
                              username:    usernameCtrl.text,
                              email:       emailCtrl.text,
                              password:    passCtrl.text,
                              role:        roleSelectionne,
                              firstName:   firstCtrl.text,
                              lastName:    lastCtrl.text,
                              phoneNumber: phoneCtrl.text,
                            );
                        if (ok && context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Créer l\'utilisateur',
                              style: AppTextStyles.body.copyWith(
                                color:      Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 6),
          TextField(
            controller:     ctrl,
            keyboardType:   keyboard,
            obscureText:    obscure,
            decoration: InputDecoration(
              hintText:   hint,
              prefixIcon: Icon(icon, color: AppColors.textSecondary),
              filled:     true,
              fillColor:  AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary, width: 2,
                ),
              ),
            ),
          ),
        ],
      );
}

class _UtilisateurCard extends StatelessWidget {
  final UtilisateurAdmin utilisateur;

  const _UtilisateurCard({required this.utilisateur});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width:  46,
            height: 46,
            decoration: BoxDecoration(
              color: utilisateur.isActive
                  ? AppColors.primarySurface
                  : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                utilisateur.nomComplet.isNotEmpty
                    ? utilisateur.nomComplet
                        .split(' ')
                        .map((w) => w[0])
                        .take(2)
                        .join()
                        .toUpperCase()
                    : utilisateur.username.substring(0, 2).toUpperCase(),
                style: AppTextStyles.body.copyWith(
                  color:      AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  utilisateur.nomComplet.isNotEmpty
                      ? utilisateur.nomComplet
                      : utilisateur.username,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  utilisateur.email,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: utilisateur.roles.map((role) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:        _roleColor(role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color:      _roleColor(role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),

          // Statut
          Container(
            width:  10,
            height: 10,
            decoration: BoxDecoration(
              color: utilisateur.isActive
                  ? AppColors.normale
                  : AppColors.border,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return AppColors.elevee;
      case 'medecin':    return AppColors.primary;
      case 'super_admin': return AppColors.critique;
      default:           return AppColors.textSecondary;
    }
  }
}