import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';

// Seuils HTA — colonne "À domicile" (automesure)
const _htaSeuilSystoliqueEleve          = 120;
const _htaSeuilDiastoliqueEleve         = 70;
const _htaSeuilSystoliqueHypertension   = 135;
const _htaSeuilDiastoliqueHypertension  = 85;
const _htaSeuilSystoliqueCritique       = 180;
const _htaSeuilDiastoliqueCritique      = 110;

class SetupProfilScreen extends ConsumerStatefulWidget {
  const SetupProfilScreen({super.key});

  @override
  ConsumerState<SetupProfilScreen> createState() => _SetupProfilScreenState();
}

class _SetupProfilScreenState extends ConsumerState<SetupProfilScreen> {
  bool? _estHypertendu;
  int?  _medecinSelectionne;
  bool  _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profilProvider.notifier).chargerMedecins();
    });
  }

  Future<void> _valider() async {
    if (_estHypertendu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Veuillez répondre à la question sur l\'hypertension.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Les appels API sont best-effort : une erreur réseau ne bloque pas le setup.
    if (_estHypertendu == true) {
      try {
        await ref.read(profilProvider.notifier).mettreAJour(
          patientId:                    user.id,
          seuilSystoliqueEleve:         _htaSeuilSystoliqueEleve,
          seuilDiastoliqueEleve:        _htaSeuilDiastoliqueEleve,
          seuilSystoliqueHypertension:  _htaSeuilSystoliqueHypertension,
          seuilDiastoliqueHypertension: _htaSeuilDiastoliqueHypertension,
          seuilSystoliqueCritique:      _htaSeuilSystoliqueCritique,
          seuilDiastoliqueCritique:     _htaSeuilDiastoliqueCritique,
        );
      } catch (_) {}
    }

    if (_medecinSelectionne != null) {
      try {
        await ref.read(profilProvider.notifier).choisirMedecin(
          patientId: user.id,
          medecinId: _medecinSelectionne!,
        );
      } catch (_) {}
    }

    // Toujours marquer le setup comme terminé, même si les API ont échoué.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_done_${user.id}', true);

    if (mounted) context.go('/home');
  }

  Future<void> _passer() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_done_${user.id}', true);
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final medecins = ref.watch(profilProvider).medecins;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Titre
              Text('Bienvenue !', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                'Quelques informations pour personnaliser votre suivi.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 40),

              // ── Question hypertension ─────────────────────────────────
              _sectionLabel('Avez-vous de l\'hypertension artérielle ?'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _choixCard(
                    label:    'Oui',
                    emoji:    '🩺',
                    selected: _estHypertendu == true,
                    onTap:    () => setState(() => _estHypertendu = true),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _choixCard(
                    label:    'Non',
                    emoji:    '✅',
                    selected: _estHypertendu == false,
                    onTap:    () => setState(() => _estHypertendu = false),
                  )),
                ],
              ),

              // Info seuils si hypertendu
              if (_estHypertendu == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ℹ️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vos seuils d\'alerte seront adaptés à l\'automesure : '
                          'élevé ≥ 120/70, hypertension ≥ 135/85, critique ≥ 180/110 mmHg.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Sélection médecin ─────────────────────────────────────
              _sectionLabel('Sélectionner votre médecin référent'),
              const SizedBox(height: 4),
              Text(
                'Optionnel — vous pouvez le choisir plus tard dans votre profil.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),

              if (medecins.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:        AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Aucun médecin disponible pour le moment.',
                    style: AppTextStyles.bodySecondary,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color:        AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(
                      color: _medecinSelectionne != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: _medecinSelectionne != null ? 2 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value:        _medecinSelectionne,
                      isExpanded:   true,
                      hint:         Text('Choisir un médecin', style: AppTextStyles.bodySecondary),
                      icon:         const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text('Aucun pour l\'instant', style: AppTextStyles.bodySecondary),
                        ),
                        ...medecins.map((m) => DropdownMenuItem<int>(
                          value: m.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(m.nomComplet, style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                              if (m.specialite != null)
                                Text(m.specialite!, style: AppTextStyles.caption),
                            ],
                          ),
                        )),
                      ],
                      onChanged: (val) => setState(() => _medecinSelectionne = val),
                    ),
                  ),
                ),

              const SizedBox(height: 48),

              // ── Bouton valider ────────────────────────────────────────
              SizedBox(
                width:  double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _valider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Continuer', style: AppTextStyles.body.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                        )),
                ),
              ),
              const SizedBox(height: 12),

              // Passer
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : _passer,
                  child: Text(
                    'Passer cette étape',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _poweredBy(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
      );

  Widget _choixCard({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color:        selected ? AppColors.primarySurface : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              )),
            ],
          ),
        ),
      );
}

Widget _poweredBy() => const Center(
      child: Text(
        'Powered by G-Medic',
        style: TextStyle(
          fontSize: 11,
          color:    Color(0xFFAAAAAA),
          letterSpacing: 0.5,
        ),
      ),
    );
