import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilPatient {
  final int id;
  final int userId;
  final String? gender;
  final String? birthDate;
  final String? address;
  final String? emergencyContact;
  final String? bloodGroup;
  final int? medecinId;
  final String? medecinNomComplet;

  const ProfilPatient({
    required this.id,
    required this.userId,
    this.gender,
    this.birthDate,
    this.address,
    this.emergencyContact,
    this.bloodGroup,
    this.medecinId,
    this.medecinNomComplet,
  });

  factory ProfilPatient.fromJson(Map<String, dynamic> json) => ProfilPatient(
        id:               json['id'],
        userId:           json['user_id'],
        gender:           json['gender'],
        birthDate:        json['birth_date'],
        address:          json['address'],
        emergencyContact: json['emergency_contact'],
        bloodGroup:       json['blood_group'],
        medecinId:        json['medecin_id'],
        medecinNomComplet: json['medecin_nom_complet'],
      );
}

class Medecin {
  final int id;
  final String nomComplet;
  final String email;
  final String? telephone;
  final String? specialite;

  const Medecin({
    required this.id,
    required this.nomComplet,
    required this.email,
    this.telephone,
    this.specialite,
  });

  factory Medecin.fromJson(Map<String, dynamic> json) => Medecin(
        id:         json['id'],
        nomComplet: json['nom_complet'],
        email:      json['email'],
        telephone:  json['telephone'],
        specialite: json['specialite'],
      );
}

class ProfilState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? success;
  final ProfilPatient? profil;
  final List<Medecin> medecins;
  final int? patientId;

  const ProfilState({
    this.isLoading = false,
    this.isSaving  = false,
    this.error,
    this.success,
    this.profil,
    this.medecins  = const [],
    this.patientId,
  });

  ProfilState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? success,
    ProfilPatient? profil,
    List<Medecin>? medecins,
    int? patientId,
  }) =>
      ProfilState(
        isLoading:  isLoading  ?? this.isLoading,
        isSaving:   isSaving   ?? this.isSaving,
        error:      error,
        success:    success,
        profil:     profil     ?? this.profil,
        medecins:   medecins   ?? this.medecins,
        patientId:  patientId  ?? this.patientId,
      );
}

class ProfilNotifier extends StateNotifier<ProfilState> {
  final ApiClient _api;

  ProfilNotifier(this._api) : super(const ProfilState());

  Future<void> charger(int patientId) async {
    state = state.copyWith(isLoading: true, patientId: patientId);
    try {
      final response = await _api.get(ApiEndpoints.patient(patientId));
      final profil   = ProfilPatient.fromJson(response.data);
      state = state.copyWith(isLoading: false, profil: profil);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> chargerMedecins() async {
    try {
      final response = await _api.get(ApiEndpoints.medecins);
      final medecins = (response.data as List)
          .map((m) => Medecin.fromJson(m))
          .toList();
      state = state.copyWith(medecins: medecins);
    } catch (e) {
      state = state.copyWith(error: 'Impossible de charger les médecins.');
    }
  }

  Future<bool> mettreAJour({
    required int patientId,
    String? gender,
    String? birthDate,
    String? address,
    String? emergencyContact,
    String? bloodGroup,
    int? seuilSystoliqueEleve,
    int? seuilDiastoliqueEleve,
    int? seuilSystoliqueHypertension,
    int? seuilDiastoliqueHypertension,
    int? seuilSystoliqueCritique,
    int? seuilDiastoliqueCritique,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final data = <String, dynamic>{};
      if (gender != null)                      data['gender']                          = gender;
      if (birthDate != null)                   data['birth_date']                      = birthDate;
      if (address != null)                     data['address']                         = address;
      if (emergencyContact != null)            data['emergency_contact']               = emergencyContact;
      if (bloodGroup != null)                  data['blood_group']                     = bloodGroup;
      if (seuilSystoliqueEleve != null)        data['seuil_systolique_eleve']          = seuilSystoliqueEleve;
      if (seuilDiastoliqueEleve != null)       data['seuil_diastolique_eleve']         = seuilDiastoliqueEleve;
      if (seuilSystoliqueHypertension != null) data['seuil_systolique_hypertension']   = seuilSystoliqueHypertension;
      if (seuilDiastoliqueHypertension != null)data['seuil_diastolique_hypertension']  = seuilDiastoliqueHypertension;
      if (seuilSystoliqueCritique != null)     data['seuil_systolique_critique']       = seuilSystoliqueCritique;
      if (seuilDiastoliqueCritique != null)    data['seuil_diastolique_critique']      = seuilDiastoliqueCritique;

      await _api.patch(ApiEndpoints.patient(patientId), data: data);
      await charger(patientId);
      state = state.copyWith(isSaving: false, success: 'Profil mis à jour !');
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error:    'Erreur lors de la mise à jour.',
      );
      return false;
    }
  }

  Future<bool> choisirMedecin({
    required int patientId,
    required int medecinId,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await _api.post(
        ApiEndpoints.choisirMedecin(patientId),
        data: {'medecin_id': medecinId},
      );
      await charger(patientId);
      state = state.copyWith(
        isSaving: false,
        success:  'Médecin assigné avec succès !',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error:    'Erreur lors de l\'assignation.',
      );
      return false;
    }
  }

  Future<bool> accepterInvitation({
    required int patientId,
    required String code,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await _api.post(
        ApiEndpoints.accepterInvitation(patientId),
        data: {'code': code.toUpperCase()},
      );
      await charger(patientId);
      state = state.copyWith(
        isSaving: false,
        success:  'Invitation acceptée !',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error:    'Code invalide ou expiré.',
      );
      return false;
    }
  }
}

final profilProvider =
    StateNotifierProvider<ProfilNotifier, ProfilState>((ref) {
  return ProfilNotifier(ref.watch(apiClientProvider));
});