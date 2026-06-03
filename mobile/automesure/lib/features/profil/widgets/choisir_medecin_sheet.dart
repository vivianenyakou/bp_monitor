import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/profil_provider.dart';

class ChoisirMedecinSheet extends ConsumerStatefulWidget {
  final int patientId;

  const ChoisirMedecinSheet({super.key, required this.patientId});

  @override
  ConsumerState<ChoisirMedecinSheet> createState() =>
      _ChoisirMedecinSheetState();
}

class _ChoisirMedecinSheetState extends ConsumerState<ChoisirMedecinSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeCtrl = TextEditingController();
  int? _medecinSelectionne;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    ref.read(profilProvider.notifier).chargerMedecins();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profilProvider);

    return Container(
      height:       MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width:  40,
            height: 4,
            decoration: BoxDecoration(
              color:        AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          Text(
            'Choisir un médecin',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller:       _tabController,
            labelColor:       AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor:   AppColors.primary,
            tabs: const [
              Tab(text: 'Liste des médecins'),
              Tab(text: 'Code invitation'),
            ],
          ),

          // Contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1 — Liste
                _buildListeMedecins(state),

                // Tab 2 — Code invitation
                _buildCodeInvitation(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeMedecins(ProfilState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.medecins.isEmpty) {
      return Center(
        child: Text(
          'Aucun médecin disponible',
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding:     const EdgeInsets.all(16),
            itemCount:   state.medecins.length,
            itemBuilder: (context, i) {
              final medecin  = state.medecins[i];
              final selected = _medecinSelectionne == medecin.id;

              return GestureDetector(
                onTap: () => setState(
                  () => _medecinSelectionne = medecin.id,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primarySurface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:  selected
                          ? AppColors.primary
                          : AppColors.border,
                      width:  selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width:  48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            medecin.nomComplet
                                .split(' ')
                                .map((w) => w[0])
                                .take(2)
                                .join()
                                .toUpperCase(),
                            style: AppTextStyles.body.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medecin.nomComplet,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (medecin.specialite != null)
                              Text(
                                medecin.specialite!,
                                style: AppTextStyles.caption,
                              ),
                            if (medecin.email != null)
                              Text(
                                medecin.email!,
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ),
                      ),

                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bouton confirmer
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width:  double.infinity,
            height: 52,
            child:  ElevatedButton(
              onPressed: _medecinSelectionne == null || state.isSaving
                  ? null
                  : () => _confirmerChoix(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Confirmer le choix',
                      style: AppTextStyles.body.copyWith(
                        color:      Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInvitation(ProfilState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Demandez le code d\'invitation à votre médecin.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Code d\'invitation', style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),

          TextField(
            controller:      _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText:    'Ex: ABC12345',
              hintStyle:   AppTextStyles.bodySecondary,
              prefixIcon:  const Icon(
                Icons.vpn_key_outlined,
                color: AppColors.primary,
              ),
              filled:      true,
              fillColor:   AppColors.background,
              border:      OutlineInputBorder(
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

          if (state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColors.critiqueLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.error!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.critique,
                ),
              ),
            ),
          ],

          const Spacer(),

          SizedBox(
            width:  double.infinity,
            height: 52,
            child:  ElevatedButton(
              onPressed: state.isSaving ||
                      _codeCtrl.text.isEmpty
                  ? null
                  : () => _validerCode(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Valider le code',
                      style: AppTextStyles.body.copyWith(
                        color:      Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerChoix() async {
    if (_medecinSelectionne == null) return;
    final ok = await ref.read(profilProvider.notifier).choisirMedecin(
          patientId: widget.patientId,
          medecinId: _medecinSelectionne!,
        );
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _validerCode() async {
    if (_codeCtrl.text.isEmpty) return;
    final ok = await ref.read(profilProvider.notifier).accepterInvitation(
          patientId: widget.patientId,
          code:      _codeCtrl.text,
        );
    if (ok && mounted) Navigator.pop(context);
  }
}
