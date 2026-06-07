import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/models/auth_model.dart';   // adaptez le chemin (UserModel)

/// Redirige l'utilisateur vers sa destination selon son rôle.
void redirigerSelonRole(BuildContext context, UserModel? user) {
  if (user?.isSuperAdmin == true || user?.isAdmin == true) {
    context.go('/admin');
  } else if (user?.isMedecin == true) {
    context.go('/medecin/dashboard');
  } else if (user?.isPatient == true) {
    context.go(user!.doitFaireSetup ? '/setup-profil' : '/home');
  } else {
    context.go('/home');
  }
}