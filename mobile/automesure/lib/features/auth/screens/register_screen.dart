import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_endpoints.dart';
import '../providers/auth_provider.dart';

class _Organisation {
  final int    id;
  final String nom;
  final String code;
  const _Organisation({required this.id, required this.nom, required this.code});
}

class RegisterScreen extends ConsumerStatefulWidget {
  final String? qrToken;

  const RegisterScreen({super.key, this.qrToken});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  bool _obscure       = true;
  DateTime? _dateNaissance;

  List<_Organisation> _organisations = [];
  _Organisation?      _orgSelectionnee;
  bool                _loadingOrgs = true;
  String? _organisationNom;
  String? _medecinNom;
  bool    _qrValide = false;

  @override
  void initState() {
    super.initState();
    _chargerOrganisations();

    if (widget.qrToken != null) {
      _chargerInfoQR(widget.qrToken!);
    }
  }

  Future<void> _chargerOrganisations() async {
    try {
      final api      = ref.read(apiClientProvider);
      final response = await api.get(ApiEndpoints.organisationsPubliques);
      final list     = (response.data as List).map((o) => _Organisation(
        id:   o['id'],
        nom:  o['nom'],
        code: o['code'],
      )).toList();
      setState(() { _organisations = list; _loadingOrgs = false; });
    } catch (_) {
      setState(() => _loadingOrgs = false);
    }
  }
  Future<void> _chargerInfoQR(String token) async {
      try {
        final api      = ref.read(apiClientProvider);
        final response = await api.get(ApiEndpoints.validerQRCode(token));
        final data     = response.data;

        if (data['est_valide'] == true) {
          setState(() {
            _organisationNom = data['organisation_nom'];
            _medecinNom      = data['medecin_nom'];
            _qrValide        = true;

            // Désélectionner l'organisation manuelle
            // car le QR gère tout automatiquement
            _orgSelectionnee = null;
          });
        }
      } catch (e) {
        print('[QR] Erreur validation : $e');
      }
    }
  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDateNaissance() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 1),
      helpText: 'Date de naissance',
      locale: const Locale('fr'),
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  int? get _ageCalcule {
    if (_dateNaissance == null) return null;
    final today = DateTime.now();
    int age = today.year - _dateNaissance!.year;
    if (today.month < _dateNaissance!.month ||
        (today.month == _dateNaissance!.month &&
            today.day < _dateNaissance!.day)) {
      age--;
    }
    return age;
  }

Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
      username:         _usernameCtrl.text.trim(),
      email:            _emailCtrl.text.trim(),
      password:         _passCtrl.text,
      firstName:        _firstCtrl.text.trim(),
      lastName:         _lastCtrl.text.trim(),
      phoneNumber:      _phoneCtrl.text.trim(),
      birthDate:        _dateNaissance,
      organisationCode: _orgSelectionnee?.code,
      qrToken:          widget.qrToken,
    );
    if (ok && mounted) {
      final user = ref.read(authProvider).user;
      context.go((user?.doitFaireSetup ?? false) ? '/setup-profil' : '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créer un compte', style: AppTextStyles.heading1),
                const SizedBox(height: 8),
                Text('Rejoignez Auto-Mésure santé', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 16),
                // ── Bannière QR code ─────────────────────────────────
                if (widget.qrToken != null)
                  Container(
                    margin:  const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        _qrValide
                          ? AppColors.primarySurface
                          : AppColors.eleveeLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _qrValide
                            ? AppColors.primary
                            : AppColors.elevee,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _qrValide ? '✅' : '⏳',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _qrValide
                                    ? 'QR code validé !'
                                    : 'Validation en cours...',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _qrValide
                                      ? AppColors.primary
                                      : AppColors.elevee,
                                ),
                              ),
                              if (_qrValide && _organisationNom != null)
                                Text(
                                  '🏥 $_organisationNom',
                                  style: AppTextStyles.caption,
                                ),
                              if (_qrValide && _medecinNom != null)
                                Text(
                                  '👨‍⚕️ $_medecinNom',
                                  style: AppTextStyles.caption,
                                ),
                              if (_qrValide)
                                Text(
                                  'Organisation et médecin assignés automatiquement',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Prénom + Nom
                Row(
                  children: [
                    Expanded(child: _buildField(
                      label: 'Prénom', controller: _firstCtrl,
                      hint: 'Ama', icon: Icons.person_outline,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(
                      label: 'Nom', controller: _lastCtrl,
                      hint: 'Koffi', icon: Icons.person_outline, required: false,
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                _buildField(
                  label: 'Nom d\'utilisateur', controller: _usernameCtrl,
                  hint: 'ama.koffi', icon: Icons.alternate_email,
                ),
                const SizedBox(height: 16),

                _buildField(
                  label: 'Email', controller: _emailCtrl,
                  hint: 'ama@email.com', icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildField(
                  label: 'Téléphone', controller: _phoneCtrl,
                  hint: '90 00 00 00', icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone, required: false,
                  prefixText: '${AppConstants.phoneCountryCode} ',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  ],
                ),
                const SizedBox(height: 16),

                // Date de naissance
                _buildLabel('Date de naissance (optionnel)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _choisirDateNaissance,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: _dateNaissance != null
                          ? Border.all(
                              color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateNaissance == null
                              ? Text('Sélectionner la date',
                                  style: AppTextStyles.bodySecondary)
                              : Text(
                                  '${_dateNaissance!.day.toString().padLeft(2, '0')}/'
                                  '${_dateNaissance!.month.toString().padLeft(2, '0')}/'
                                  '${_dateNaissance!.year}',
                                  style: AppTextStyles.body,
                                ),
                        ),
                        if (_ageCalcule != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_ageCalcule ans',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (_dateNaissance != null)
                          IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18,
                                color: AppColors.textSecondary),
                            onPressed: () =>
                                setState(() => _dateNaissance = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                _buildLabel('Mot de passe'),
                const SizedBox(height: 8),
                TextFormField(
                  controller:  _passCtrl,
                  obscureText: _obscure,
                  decoration:  _inputDecoration(hint: '••••••••', icon: Icons.lock_outline)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Dropdown organisation (caché si QR validé) ──────────
                if (!_qrValide) ...[
                  _buildLabel('Structure médicale (optionnel)'),
                  const SizedBox(height: 8),
                  _loadingOrgs
                      ? const SizedBox(
                          height: 52,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      : Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: _orgSelectionnee != null
                                ? Border.all(
                                    color: AppColors.primary, width: 2)
                                : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<_Organisation>(
                              value: _orgSelectionnee,
                              isExpanded: true,
                              hint: Text(
                                _organisations.isEmpty
                                    ? 'Aucune organisation disponible'
                                    : 'Sélectionner votre clinique / hôpital',
                                style: AppTextStyles.bodySecondary,
                              ),
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: AppColors.primary),
                              items: [
                                const DropdownMenuItem<_Organisation>(
                                  value: null,
                                  child: Text('Aucune'),
                                ),
                                ..._organisations.map((o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(o.nom),
                                    )),
                              ],
                              onChanged: (val) =>
                                  setState(() => _orgSelectionnee = val),
                            ),
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    'Sélectionnez votre clinique ou hôpital si applicable.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 24),
                ],

                // Erreur
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin:  const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color:        AppColors.critiqueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.critique, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(state.error!,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.critique)),
                        ),
                      ],
                    ),
                  ),

                // Bouton register
                SizedBox(
                  width:  double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Créer mon compte',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                  ),
                ),
                const SizedBox(height: 24),

                // Lien login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Déjà un compte ? ', style: AppTextStyles.bodySecondary),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Se connecter',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Powered by
                const Center(
                  child: Text(
                    'Powered by G-Medic',
                    style: TextStyle(
                      fontSize: 11, color: Color(0xFFAAAAAA), letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool required = true,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller:  controller,
            keyboardType: keyboard,
            inputFormatters: inputFormatters,
            decoration:  _inputDecoration(
              hint: hint,
              icon: icon,
              prefixText: prefixText,
            ),
            validator:   required
                ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
                : null,
          ),
        ],
      );

  Widget _buildLabel(String label) =>
      Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600));

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefixText,
  }) =>
      InputDecoration(
        hintText:    hint,
        hintStyle:   AppTextStyles.bodySecondary,
        prefixIcon:  Icon(icon, color: AppColors.textSecondary),
        prefixText:  prefixText,
        prefixStyle: AppTextStyles.body.copyWith(
          color:      AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        filled:      true,
        fillColor:   AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
