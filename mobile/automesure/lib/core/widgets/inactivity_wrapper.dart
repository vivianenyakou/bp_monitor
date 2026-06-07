import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';   // adaptez le chemin

class InactivityWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const InactivityWrapper({super.key, required this.child});

  @override
  ConsumerState<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends ConsumerState<InactivityWrapper> {
  Timer? _timer;
  static const _delai = Duration(minutes: 10);

  void _relancer() {
    _timer?.cancel();
    if (ref.read(authProvider).user == null) return;   // seulement si connecté
    _timer = Timer(_delai, _deconnecter);
  }

  Future<void> _deconnecter() async {
    if (ref.read(authProvider).user == null) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _relancer(),
      onPointerMove: (_) => _relancer(),
      child: widget.child,
    );
  }
}