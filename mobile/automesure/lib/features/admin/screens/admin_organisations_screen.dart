import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/admin_provider.dart';

class AdminOrganisationsScreen extends ConsumerStatefulWidget {
  const AdminOrganisationsScreen({super.key});

  @override
  ConsumerState<AdminOrganisationsScreen> createState() =>
      _AdminOrganisationsScreenState();
}

class _AdminOrganisationsScreenState
    extends ConsumerState<AdminOrganisationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).chargerOrganisations();
    });
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
          onPressed: () => context.go('/admin'),
        ),
        title: Text('Organisations', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon:      const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _creerOrganisation(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminProvider.notifier).chargerOrganisations(),
              color: AppColors.primary,
              child: state.organisations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏥',
                              style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune organisation',
                            style: AppTextStyles.heading3,
                          ),
                          Text(
                            'Créez la première organisation',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:     const EdgeInsets.all(16),
                      itemCount:   state.organisations.length,
                      itemBuilder: (context, i) {
                        final org = state.organisations[i];
                        return _OrganisationCard(organisation: org);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:       () => _creerOrganisation(context),
        backgroundColor: AppColors.primary,
        icon:  const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nouvelle organisation',
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _creerOrganisation(BuildContext context) {
    final nomCtrl   = TextEditingController();
    final codeCtrl  = TextEditingController();
    final adresseCtrl  = TextEditingController();
    final telCtrl   = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                // Handle
                Center(
                  child: Container(
                    width:  40, height: 4,
                    decoration: BoxDecoration(
                      color:        AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Nouvelle organisation', style: AppTextStyles.heading3),
                const SizedBox(height: 24),

                _buildField('Nom *',     nomCtrl,    Icons.business_outlined),
                const SizedBox(height: 12),
                _buildField('Code *',    codeCtrl,   Icons.tag,
                    hint: 'Ex: HOPITAL_LOME'),
                const SizedBox(height: 12),
                _buildField('Adresse',   adresseCtrl, Icons.location_on_outlined),
                const SizedBox(height: 12),
                _buildField('Téléphone', telCtrl,    Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _buildField('Email',     emailCtrl,  Icons.email_outlined,
                    keyboard: TextInputType.emailAddress),
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
                    child: Text(
                      error,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.critique,
                      ),
                    ),
                  );
                }),

                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: Consumer(builder: (_, ref, __) {
                    final isSaving = ref.watch(adminProvider).isSaving;
                    return ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nomCtrl.text.isEmpty ||
                                  codeCtrl.text.isEmpty) return;
                              final ok = await ref
                                  .read(adminProvider.notifier)
                                  .creerOrganisation(
                                    nom:       nomCtrl.text,
                                    code:      codeCtrl.text,
                                    adresse:   adresseCtrl.text,
                                    telephone: telCtrl.text,
                                    email:     emailCtrl.text,
                                  );
                              if (ok && context.mounted) {
                                Navigator.pop(context);
                              }
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
                              'Créer l\'organisation',
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
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 6),
          TextField(
            controller:   ctrl,
            keyboardType: keyboard,
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

class _OrganisationCard extends StatelessWidget {
  final Organisation organisation;

  const _OrganisationCard({required this.organisation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Logo
          Container(
            width:  52,
            height: 52,
            decoration: BoxDecoration(
              color:        AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🏥', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organisation.nom,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:        AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        organisation.code,
                        style: AppTextStyles.caption.copyWith(
                          color:      AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: organisation.estActif
                            ? AppColors.normaleLight
                            : AppColors.critiqueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        organisation.estActif ? 'Active' : 'Inactive',
                        style: AppTextStyles.caption.copyWith(
                          color: organisation.estActif
                              ? AppColors.normale
                              : AppColors.critique,
                        ),
                      ),
                    ),
                  ],
                ),
                if (organisation.adresse != null)
                  Text(
                    organisation.adresse!,
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size:  16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}