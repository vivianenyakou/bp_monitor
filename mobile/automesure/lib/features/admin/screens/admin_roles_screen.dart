import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AdminRolesScreen extends StatelessWidget {
  const AdminRolesScreen({super.key});

  static const _roles = [
    {
      'nom':         'super_admin',
      'label':       'Super Admin',
      'emoji':       '👑',
      'description': 'Accès complet — gère toutes les organisations et tous les rôles',
      'color':       AppColors.critique,
      'bg':          AppColors.critiqueLight,
      'permissions': [
        'Toutes les permissions',
        'Gérer les organisations',
        'Gérer les rôles',
        'Gérer les utilisateurs',
        'Voir le tableau de bord admin',
        'Configurer le système',
      ],
    },
    {
      'nom':         'admin',
      'label':       'Admin',
      'emoji':       '⚙️',
      'description': 'Gère une organisation — utilisateurs et configurations',
      'color':       AppColors.elevee,
      'bg':          AppColors.eleveeLight,
      'permissions': [
        'Gérer les utilisateurs',
        'Voir le tableau de bord admin',
        'Configurer les alertes',
        'Lister les patients',
        'Voir les profils patients',
      ],
    },
    {
      'nom':         'medecin',
      'label':       'Médecin',
      'emoji':       '🩺',
      'description': 'Consulte les patients et reçoit les alertes critiques',
      'color':       AppColors.primary,
      'bg':          AppColors.primarySurface,
      'permissions': [
        'Voir les mesures patients',
        'Recevoir les alertes',
        'Acquitter les alertes',
        'Configurer les alertes',
        'Lister les patients',
        'Créer ses propres mesures',
      ],
    },
    {
      'nom':         'patient',
      'label':       'Patient',
      'emoji':       '👤',
      'description': 'Saisit ses mesures et consulte son historique',
      'color':       AppColors.normale,
      'bg':          AppColors.normaleLight,
      'permissions': [
        'Créer une mesure',
        'Voir ses mesures',
        'Voir son profil',
        'Modifier son profil',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/admin'),
        ),
        title: Text('Rôles & Permissions', style: AppTextStyles.heading3),
      ),
      body: ListView.builder(
        padding:     const EdgeInsets.all(16),
        itemCount:   _roles.length,
        itemBuilder: (context, i) {
          final role = _roles[i];
          return _RoleCard(role: role);
        },
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final Map<String, dynamic> role;

  const _RoleCard({required this.role});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final role  = widget.role;
    final color = role['color'] as Color;
    final bg    = role['bg'] as Color;
    final perms = role['permissions'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        bg,
                borderRadius: BorderRadius.only(
                  topLeft:  const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: _expanded
                      ? Radius.zero
                      : const Radius.circular(16),
                  bottomRight: _expanded
                      ? Radius.zero
                      : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    role['emoji'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role['label'] as String,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color:      color,
                          ),
                        ),
                        Text(
                          role['description'] as String,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: color,
                  ),
                ],
              ),
            ),
          ),

          // Permissions expandable
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissions (${perms.length})',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...perms.map((perm) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: color, size: 16),
                        const SizedBox(width: 8),
                        Text(perm, style: AppTextStyles.body),
                      ],
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}