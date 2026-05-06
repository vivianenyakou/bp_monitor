import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _orgCtrl     = TextEditingController();
  bool _obscure      = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          firstName: _firstCtrl.text.trim(),
          lastName: _lastCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          organisationCode: _orgCtrl.text.trim().isEmpty
              ? null
              : _orgCtrl.text.trim().toUpperCase(),
        );
    if (ok && mounted) context.go('/home');
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
                Text(
                  'Rejoignez BP Monitor',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 32),

                // Prénom + Nom
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Prénom',
                        controller: _firstCtrl,
                        hint: 'Ama',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Nom',
                        controller: _lastCtrl,
                        hint: 'Koffi',
                        icon: Icons.person_outline,
                        required: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Username
                _buildField(
                  label: 'Nom d\'utilisateur',
                  controller: _usernameCtrl,
                  hint: 'ama.koffi',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 16),

                // Email
                _buildField(
                  label: 'Email',
                  controller: _emailCtrl,
                  hint: 'ama@email.com',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Téléphone
                _buildField(
                  label: 'Téléphone',
                  controller: _phoneCtrl,
                  hint: '+228 90 00 00 00',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  required: false,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                _buildLabel('Mot de passe'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                  ).copyWith(
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

                // Code organisation
                _buildField(
                  label: 'Code organisation (optionnel)',
                  controller: _orgCtrl,
                  hint: 'Ex: HOPITAL_LOME',
                  icon: Icons.business_outlined,
                  required: false,
                ),
                const SizedBox(height: 8),
                Text(
                  'Demandez ce code à votre clinique ou hôpital.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 24),

                // Erreur
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.critiqueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.critique, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.critique,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bouton register
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Créer mon compte',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Lien login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: AppTextStyles.bodySecondary,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Se connecter',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            decoration: _inputDecoration(hint: hint, icon: icon),
            validator: required
                ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
                : null,
          ),
        ],
      );

  Widget _buildLabel(String label) => Text(
        label,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySecondary,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );
}