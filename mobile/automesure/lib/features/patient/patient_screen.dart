import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../home/widgets/bp_bottom_nav.dart';
import '../medecin/providers/medecin_provider.dart';

class PatientScreen extends ConsumerStatefulWidget {
  const PatientScreen({super.key});

  @override
  ConsumerState<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends ConsumerState<PatientScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medecinProvider.notifier).charger();
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(medecinProvider);
    final patients = state.patients.where((p) {
      if (_query.isEmpty) return true;
      return p.nomComplet.toLowerCase().contains(_query) ||
          (p.telephone ?? '').contains(_query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/medecin/dashboard'),
        ),
        title: Text(
          'Mes patients',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.patients.length} patient(s)',
                  style: AppTextStyles.caption.copyWith(
                    color:      AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  'Rechercher un patient...',
                hintStyle: AppTextStyles.bodySecondary,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon:      const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled:     true,
                fillColor:  AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical:   12,
                ),
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
                    onRefresh: () =>
                        ref.read(medecinProvider.notifier).charger(),
                    color: AppColors.primary,
                    child: patients.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: patients.length,
                            itemBuilder: (context, i) =>
                                _buildPatientCard(patients[i]),
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BPBottomNav(currentIndex: 1),
    );
  }

  Widget _buildEmpty() {
    if (_query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Aucun résultat pour "$_query"',
                style: AppTextStyles.heading3),
            Text('Essayez un autre nom ou numéro.',
                style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('Aucun patient assigné', style: AppTextStyles.heading3),
          Text(
            'Invitez des patients depuis le tableau de bord.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/medecin/dashboard'),
            icon:  const Icon(Icons.arrow_back, color: AppColors.primary),
            label: Text('Tableau de bord',
                style: AppTextStyles.body.copyWith(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side:  const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientMedecin patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        children: [
          // Header patient
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius:          24,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    _initiales(patient.nomComplet),
                    style: AppTextStyles.body.copyWith(
                      color:      AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize:   16,
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
                        patient.nomComplet,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (patient.telephone != null)
                        Text(patient.telephone!,
                            style: AppTextStyles.caption),
                    ],
                  ),
                ),

                // Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (patient.bloodGroup != null)
                      _badge(patient.bloodGroup!, AppColors.hypertension),
                    if (patient.gender != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _badge(
                          patient.gender == 'M' ? '♂ Homme' : '♀ Femme',
                          AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Infos supplémentaires
          if (patient.birthDate != null || patient.telephone != null)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (patient.birthDate != null) ...[
                    const Icon(Icons.cake_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(patient.birthDate!),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Spacer(),
                  if (patient.telephone != null)
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: () => _appeler(patient.telephone!),
                        icon: const Icon(Icons.phone,
                            size: 14, color: AppColors.primary),
                        label: Text(
                          'Appeler',
                          style: AppTextStyles.body.copyWith(
                            color:    AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color:      color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'P';
  }

  String _formatDate(String iso) {
    // iso format: "1990-05-15"
    final parts = iso.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return iso;
  }

  Future<void> _appeler(String tel) async {
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
