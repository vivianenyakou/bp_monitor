import 'package:automesure/core/constants/app_role.dart';

class TokenModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
        accessToken: json['access_token'],
        refreshToken: json['refresh_token'],
        tokenType: json['token_type'] ?? 'bearer',
      );
}

class UserModel {
  final int id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final List<String> roles;
  final List<String> permissions;
  final int? organisationId;

  const UserModel({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.roles,
    required this.permissions,
    this.organisationId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        phoneNumber: json['phone_number'],
        roles: List<String>.from(json['roles'] ?? []),
        permissions: List<String>.from(json['permissions'] ?? []),
        organisationId: json['organisation_id'],
      );

  bool get isMedecin => roles.contains(AppRole.MEDECIN);
  bool get isPatient => roles.contains(AppRole.PATIENT);
  bool get isAdmin   => roles.contains(AppRole.ADMIN);
  bool get isSuperAdmin   => roles.contains(AppRole.SUPER_ADMIN);


  String get nomComplet =>
      '${firstName ?? ''} ${lastName ?? ''}'.trim();

  String get nomAffichage =>
      nomComplet.isNotEmpty
          ? nomComplet
          : username ?? phoneNumber ?? 'Utilisateur';

  String get initiales {
    final source = nomAffichage.trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
   // Peut accéder aux menus admin
  bool get hasAdminAccess =>
      isAdmin || isSuperAdmin;

  // Peut gérer les organisations
  bool get canGererOrganisations =>
      isAdmin || isSuperAdmin;

  // Peut gérer les utilisateurs
  bool get canGererUtilisateurs =>
      isAdmin || isSuperAdmin;

  // Peut gérer les rôles
  bool get canGererRoles => isSuperAdmin;
}
