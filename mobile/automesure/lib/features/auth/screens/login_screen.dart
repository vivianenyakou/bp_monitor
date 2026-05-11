import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _identCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;

  @override
  void dispose() {
    _identCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
      _identCtrl.text.trim(),
      _passCtrl.text,
    );
    if (!ok || !mounted) return;

    final user = ref.read(authProvider).user;

    if (user?.isSuperAdmin == true || user?.isAdmin == true) {
      context.go('/admin');
    } else if (user?.isMedecin == true) {
      context.go('/medecin/dashboard');
    } else if (user?.isPatient == true) {
      final prefs = await SharedPreferences.getInstance();
      final done  = prefs.getBool('setup_done_${user!.id}') ?? false;
      if (mounted) context.go(done ? '/home' : '/setup-profil');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🩺', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Titre
                Text('Connexion', style: AppTextStyles.heading1),
                const SizedBox(height: 8),
                Text(
                  'Email, téléphone ou nom d\'utilisateur',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 32),

                // Identifiant
                _buildLabel('Identifiant'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _identCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'email, téléphone ou username',
                    icon: Icons.person_outline,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 20),

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
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),

                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Erreur
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 24),

                // Bouton login
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Se connecter',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Lien register
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style: AppTextStyles.bodySecondary,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          'S\'inscrire',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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