import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/bp_bottom_nav.dart';
import '../providers/mesure_provider.dart';
import '../widgets/bp_input_field.dart';
import '../widgets/analyse_result_card.dart';

class SaisieMesureScreen extends ConsumerStatefulWidget {
  const SaisieMesureScreen({super.key});

  @override
  ConsumerState<SaisieMesureScreen> createState() =>
      _SaisieMesureScreenState();
}

class _SaisieMesureScreenState extends ConsumerState<SaisieMesureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(mesureProvider.notifier).chargerSession(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mesureProvider);
    final notifier = ref.read(mesureProvider.notifier);
    final user = ref.read(authProvider).user;

    final String subtitle;
    if (state.sessionLoading) {
      subtitle = 'Chargement...';
    } else if (state.protocoleTermine) {
      subtitle = 'Protocole terminé';
    } else if (state.estHorsCreneaux) {
      subtitle = 'Hors créneau';
    } else if (state.creneauTermine) {
      subtitle = 'Créneau terminé';
    } else {
      final creneau = state.creneauActuel == 'matin' ? 'Matin' : 'Soir';
      subtitle =
          '$creneau · Jour ${state.jourActuel}/3 · Mesure ${state.numeroMesureActuel}/3';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: AppTextStyles.caption),
            Text(
              'Nouvelle mesure',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: state.sessionLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SessionProgressCard(state: state),
                  const SizedBox(height: 16),
                  if (state.protocoleTermine)
                    _buildProtocoleTermine(context)
                  else if (state.estHorsCreneaux)
                    _buildHorsCreneaux(state)
                  else if (state.creneauTermine)
                    _buildCreneauTermine(state)
                  else ...[
                    _buildIndicateurAnalyse(),
                    const SizedBox(height: 16),
                    BPInputField(
                      label: 'SYSTOLIQUE',
                      sublabel: 'Pression maximale',
                      value: state.systolique,
                      min: 60,
                      max: 250,
                      unit: 'mmHg',
                      unitColor: AppColors.hypertension,
                      onChanged: notifier.mettreAJourSystolique,
                    ),
                    const SizedBox(height: 12),
                    BPInputField(
                      label: 'DIASTOLIQUE',
                      sublabel: 'Pression minimale',
                      value: state.diastolique,
                      min: 40,
                      max: 150,
                      unit: 'mmHg',
                      unitColor: AppColors.primary,
                      onChanged: notifier.mettreAJourDiastolique,
                    ),
                    const SizedBox(height: 12),
                    BPInputField(
                      label: 'POULS',
                      sublabel: 'Fréquence cardiaque',
                      value: state.pouls ?? 70,
                      min: 30,
                      max: 220,
                      unit: 'bpm',
                      unitColor: Colors.pink,
                      onChanged: notifier.mettreAJourPouls,
                    ),
                    const SizedBox(height: 16),
                    AnalyseResultCard(
                      categorie: state.categorieActuelle,
                      systolique: state.systolique,
                      diastolique: state.diastolique,
                    ),
                    const SizedBox(height: 16),
                    if (state.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.critiqueLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.error!,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.critique),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => _onEnregistrer(context, notifier, user?.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'Enregistrer la mesure',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: const BPBottomNav(currentIndex: 1),
    );
  }

  Future<void> _onEnregistrer(
    BuildContext context,
    MesureNotifier notifier,
    int? patientId,
  ) async {
    if (patientId == null) return;
    final ok = await notifier.enregistrer(patientId);
    if (!ok || !context.mounted) return;

    final s = ref.read(mesureProvider);

    if (s.messageFin != null) {
      _showMessageFin(context, s.messageFin!);
      return;
    }

    if (s.popupMedicament) {
      _showPopupMedicament(context, notifier);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mesure enregistrée — ${s.mesuresRestantes} restante(s) ce créneau'),
        backgroundColor: AppColors.normale,
      ),
    );
  }

  void _showPopupMedicament(BuildContext context, MesureNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Médicaments'),
        content: const Text(
          'Avez-vous pris vos médicaments antihypertenseurs aujourd\'hui ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.repondreMedicament(false);
            },
            child: const Text('Non'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.repondreMedicament(true);
            },
            child: const Text('Oui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMessageFin(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Protocole terminé !'),
        content: Text(message),
        actions: [
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child:
                const Text('Retour accueil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicateurAnalyse() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.normale,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Entrez vos valeurs — analyse en temps réel',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHorsCreneaux(MesureState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.access_time, color: Colors.orange, size: 40),
          const SizedBox(height: 12),
          Text(
            'Hors créneau de mesure',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.messageCreneauHors ??
                'Les mesures se prennent le matin entre (00h–09h GMT) et le soir entre (18h–22h GMT).',
            style:
                AppTextStyles.caption.copyWith(color: Colors.orange.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

Widget _buildCreneauTermine(MesureState state) {
    final creneau = state.creneauActuel == 'matin' ? 'matin' : 'soir';

    final String prochain;
    if (state.creneauActuel == 'matin') {
      prochain = state.heureSoir != null
          ? 'Revenez à ${state.heureSoir}h pour la prise du soir.'
          : 'Revenez ce soir pour continuer le suivi.';
    } else {
      prochain = 'Revenez demain matin pour continuer le suivi.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.normaleLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.normale.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.normale, size: 40),
          const SizedBox(height: 12),
          Text(
            'Créneau du $creneau terminé',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.normale,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prochain,
            style: AppTextStyles.caption.copyWith(color: AppColors.normale),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProtocoleTermine(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          Text(
            'Protocole 3 jours terminé !',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez complété les 18 mesures. Consultez votre résumé.',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => context.go('/home'),
            child: const Text(
              'Retour accueil',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionProgressCard extends StatelessWidget {
  final MesureState state;

  const _SessionProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Protocole 3 jours',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!state.estHorsCreneaux && !state.protocoleTermine)
                _CreneauBadge(creneau: state.creneauActuel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DayIndicator(
                label: 'Jour 1',
                complete: state.jour1Complete,
                active: state.jourActuel == 1 && !state.protocoleTermine,
              ),
              _DayConnector(done: state.jour1Complete),
              _DayIndicator(
                label: 'Jour 2',
                complete: state.jour2Complete,
                active: state.jourActuel == 2 && !state.protocoleTermine,
              ),
              _DayConnector(done: state.jour2Complete),
              _DayIndicator(
                label: 'Jour 3',
                complete: state.jour3Complete,
                active: state.jourActuel == 3 && !state.protocoleTermine,
              ),
            ],
          ),
          if (!state.estHorsCreneaux &&
              !state.protocoleTermine &&
              state.mesuresRestantes > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Mesures restantes ce créneau : ',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '${state.mesuresRestantes}/3',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final String label;
  final bool complete;
  final bool active;

  const _DayIndicator({
    required this.label,
    required this.complete,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? AppColors.normale
        : active
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.4);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: complete
                  ? AppColors.normaleLight
                  : active
                      ? AppColors.primarySurface
                      : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: complete
                  ? const Icon(Icons.check, size: 16, color: AppColors.normale)
                  : Text(
                      label.split(' ').last,
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _DayConnector extends StatelessWidget {
  final bool done;
  const _DayConnector({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: done ? AppColors.normale : AppColors.background,
      ),
    );
  }
}

class _CreneauBadge extends StatelessWidget {
  final String creneau;
  const _CreneauBadge({required this.creneau});

  @override
  Widget build(BuildContext context) {
    final isMatin = creneau == 'matin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isMatin ? Colors.amber.shade50 : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMatin ? Colors.amber.shade300 : Colors.indigo.shade200,
        ),
      ),
      child: Text(
        isMatin ? '🌅 Matin' : '🌙 Soir',
        style: AppTextStyles.caption.copyWith(
          color: isMatin ? Colors.amber.shade800 : Colors.indigo.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
