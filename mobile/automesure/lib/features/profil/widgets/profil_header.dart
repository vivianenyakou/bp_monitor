import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/models/auth_model.dart';

class ProfilHeader extends StatelessWidget {
  final UserModel user;

  const ProfilHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // Avatar
          Container(
            width:  90,
            height: 90,
            decoration: BoxDecoration(
              color:  Colors.white24,
              shape:  BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: Text(
                _initiales(user),
                style: AppTextStyles.heading1.copyWith(
                  color:    AppColors.textPrimary,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nom
          Text(
            user.nomComplet.isNotEmpty
                ? user.nomComplet
                : user.username,
            style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          // Rôles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: user.roles.map((role) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4,
              ),
              decoration: BoxDecoration(
                color:        AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color:      AppColors.normaleLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  String _initiales(UserModel user) {
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName![0]}${user.lastName![0]}'.toUpperCase();
    }
    return user.username.substring(0, 2).toUpperCase();
  }
}