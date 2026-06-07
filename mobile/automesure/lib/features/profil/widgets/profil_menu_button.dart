import 'dart:ui';
import 'package:automesure/features/mesure/providers/mesure_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilMenuButton extends ConsumerStatefulWidget {
  const ProfilMenuButton({super.key});

  @override
  ConsumerState<ProfilMenuButton> createState() => _ProfilMenuButtonState();
}

class _ProfilMenuButtonState extends ConsumerState<ProfilMenuButton>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggle() => _overlayEntry == null ? _open() : _close();

  void _open() {
    final user = ref.read(authProvider).user;
    _overlayEntry = _buildOverlay(user);
    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward();
  }

  void _close() {
    _animCtrl.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _buildOverlay(dynamic user) {
    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            const Positioned.fill(child: SizedBox()),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-172, 54),
              child: GestureDetector(
                onTap: () {},
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Material(
                      color: Colors.transparent,
                      child: _DropdownCard(
                        user: user,
                        onProfil: () {
                          _close();
                          Future.delayed(const Duration(milliseconds: 220), () {
                            if (mounted) context.go('/profil');
                          });
                        },
                        onLogout: () async {
                          _close();
                          await ref.read(authProvider.notifier).logout();
                          if (mounted) context.go('/login');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final initials =
        '${user?.firstName?[0] ?? ''}${user?.lastName?[0] ?? ''}'.toUpperCase();

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: _AvatarRing(initials: initials),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Avatar button — anneau dégradé + glow
// ─────────────────────────────────────────────
class _AvatarRing extends StatelessWidget {
  final String initials;
  const _AvatarRing({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF69F0AE), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dropdown glassmorphism card
// ─────────────────────────────────────────────
class _DropdownCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onProfil;
  final VoidCallback onLogout;

  const _DropdownCard({
    required this.user,
    required this.onProfil,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        '${user?.firstName?[0] ?? ''}${user?.lastName?[0] ?? ''}'.toUpperCase();
    final name =
        '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final email = user?.email ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 224,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête utilisateur
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F5ED), Color(0xFFF5FAF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Utilisateur' : name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
              _MenuItem(
                icon: Icons.manage_accounts_outlined,
                label: 'Mon profil',
                color: AppColors.primary,
                onTap: onProfil,
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.border.withValues(alpha: 0.4),
              ),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Déconnexion',
                color: AppColors.hypertension,
                onTap: onLogout,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Item de menu avec hover animé
// ─────────────────────────────────────────────
class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _pressed ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDestructive
                    ? widget.color
                    : AppColors.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: widget.color.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}
