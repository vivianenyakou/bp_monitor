import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ProfilInfoCard extends StatelessWidget {
  final String title;
  final List<ProfilInfoItem> items;
  final VoidCallback? onEdit;

  const ProfilInfoCard({
    super.key,
    required this.title,
    required this.items,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color:      AppColors.primary,
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items
          ...items.map((item) => ListTile(
                leading: Icon(item.icon, color: AppColors.textSecondary),
                title:   Text(item.label, style: AppTextStyles.caption),
                subtitle: Text(
                  item.value?.isNotEmpty == true ? item.value! : '—',
                  style: AppTextStyles.body.copyWith(
                    color: item.value?.isNotEmpty == true
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class ProfilInfoItem {
  final IconData icon;
  final String   label;
  final String?  value;

  const ProfilInfoItem({
    required this.icon,
    required this.label,
    this.value,
  });
}