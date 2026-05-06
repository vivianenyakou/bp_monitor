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
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final List<String> roles;
  final List<String> permissions;
  final int? organisationId;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
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

  bool get isMedecin => roles.contains('medecin');
  bool get isPatient => roles.contains('patient');
  bool get isAdmin   => roles.contains('admin');

  String get nomComplet =>
      '${firstName ?? ''} ${lastName ?? ''}'.trim();
}