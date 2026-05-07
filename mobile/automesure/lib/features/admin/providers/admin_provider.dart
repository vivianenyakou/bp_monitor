import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────

class Organisation {
  final int id;
  final String nom;
  final String code;
  final String? adresse;
  final String? telephone;
  final String? email;
  final bool estActif;

  const Organisation({
    required this.id,
    required this.nom,
    required this.code,
    this.adresse,
    this.telephone,
    this.email,
    required this.estActif,
  });

  factory Organisation.fromJson(Map<String, dynamic> json) => Organisation(
        id:        json['id'],
        nom:       json['nom'],
        code:      json['code'],
        adresse:   json['adresse'],
        telephone: json['telephone'],
        email:     json['email'],
        estActif:  json['est_actif'] ?? true,
      );
}

class UtilisateurAdmin {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final bool isActive;
  final List<String> roles;
  final int? organisationId;

  const UtilisateurAdmin({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.isActive,
    required this.roles,
    this.organisationId,
  });

  factory UtilisateurAdmin.fromJson(Map<String, dynamic> json) =>
      UtilisateurAdmin(
        id:             json['id'],
        username:       json['username'],
        email:          json['email'],
        firstName:      json['first_name'],
        lastName:       json['last_name'],
        phoneNumber:    json['phone_number'],
        isActive:       json['is_active'] ?? true,
        roles:          List<String>.from(json['roles'] ?? []),
        organisationId: json['organisation_id'],
      );

  String get nomComplet =>
      '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

class Role {
  final String name;
  final String? description;

  const Role({required this.name, this.description});

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        name:        json['name'],
        description: json['description'],
      );
}

// ── State ─────────────────────────────────────────────────────────

class AdminState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? success;
  final List<Organisation> organisations;
  final List<UtilisateurAdmin> utilisateurs;

  const AdminState({
    this.isLoading     = false,
    this.isSaving      = false,
    this.error,
    this.success,
    this.organisations = const [],
    this.utilisateurs  = const [],
  });

  AdminState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? success,
    List<Organisation>? organisations,
    List<UtilisateurAdmin>? utilisateurs,
  }) =>
      AdminState(
        isLoading:     isLoading     ?? this.isLoading,
        isSaving:      isSaving      ?? this.isSaving,
        error:         error,
        success:       success,
        organisations: organisations ?? this.organisations,
        utilisateurs:  utilisateurs  ?? this.utilisateurs,
      );
}

// ── Notifier ──────────────────────────────────────────────────────

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiClient _api;

  AdminNotifier(this._api) : super(const AdminState());

  // Organisations
  Future<void> chargerOrganisations() async {
    state = state.copyWith(isLoading: true);
    try {
      final response    = await _api.get(ApiEndpoints.organisations);
      final organisations = (response.data as List)
          .map((o) => Organisation.fromJson(o))
          .toList();
      state = state.copyWith(isLoading: false, organisations: organisations);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> creerOrganisation({
    required String nom,
    required String code,
    String? adresse,
    String? telephone,
    String? email,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _api.post(
        ApiEndpoints.organisations,
        data: {
          'nom':       nom,
          'code':      code.toUpperCase(),
          if (adresse   != null) 'adresse':   adresse,
          if (telephone != null) 'telephone': telephone,
          if (email     != null) 'email':     email,
        },
      );
      await chargerOrganisations();
      state = state.copyWith(
        isSaving: false,
        success:  'Organisation créée avec succès !',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error:    'Erreur lors de la création.',
      );
      return false;
    }
  }

  // Utilisateurs
  Future<void> chargerUtilisateurs() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get(ApiEndpoints.utilisateurs);
      final utilisateurs = (response.data as List)
          .map((u) => UtilisateurAdmin.fromJson(u))
          .toList();
      state = state.copyWith(isLoading: false, utilisateurs: utilisateurs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> creerUtilisateur({
    required String username,
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    int? organisationId,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _api.post(
        ApiEndpoints.creerUtilisateur,
        data: {
          'username':     username,
          'email':        email,
          'password':     password,
          'role':         role,
          if (firstName      != null) 'first_name':      firstName,
          if (lastName       != null) 'last_name':       lastName,
          if (phoneNumber    != null) 'phone_number':    phoneNumber,
          if (organisationId != null) 'organisation_id': organisationId,
        },
      );
      await chargerUtilisateurs();
      state = state.copyWith(
        isSaving: false,
        success:  'Utilisateur créé avec succès !',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error:    'Erreur lors de la création.',
      );
      return false;
    }
  }
}

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref.watch(apiClientProvider));
});