import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../alerte/providers/alertes_provider.dart';
import '../../auth/providers/auth_provider.dart';

class PatientMedecin {
  final int id;
  final int userId;
  final String nomComplet;
  final String? telephone;
  final String? gender;
  final String? birthDate;
  final String? bloodGroup;
  final int? medecinId;

  const PatientMedecin({
    required this.id,
    required this.userId,
    required this.nomComplet,
    this.telephone,
    this.gender,
    this.birthDate,
    this.bloodGroup,
    this.medecinId,
  });

  factory PatientMedecin.fromJson(Map<String, dynamic> json) => PatientMedecin(
        id:         json['id'],
        userId:     json['user_id'],
        nomComplet: json['nom_complet'] ?? '',
        telephone:  json['telephone'],
        gender:     json['gender'],
        birthDate:  json['birth_date'],
        bloodGroup: json['blood_group'],
        medecinId:  json['medecin_id'],
      );
}

class MedecinState {
  final bool isLoading;
  final String? error;
  final List<PatientMedecin> patients;
  final List<Alerte> alertesCritiques;
  final List<Alerte> alertesASurveiller;
  final String? codeInvitation;
  final DateTime? invitationExpireLE;

  const MedecinState({
    this.isLoading          = false,
    this.error,
    this.patients           = const [],
    this.alertesCritiques   = const [],
    this.alertesASurveiller = const [],
    this.codeInvitation,
    this.invitationExpireLE,
  });

  bool get aCodeActif =>
      codeInvitation != null &&
      invitationExpireLE != null &&
      invitationExpireLE!.isAfter(DateTime.now());

  MedecinState copyWith({
    bool? isLoading,
    String? error,
    List<PatientMedecin>? patients,
    List<Alerte>? alertesCritiques,
    List<Alerte>? alertesASurveiller,
    String? codeInvitation,
    DateTime? invitationExpireLE,
  }) =>
      MedecinState(
        isLoading:          isLoading          ?? this.isLoading,
        error:              error,
        patients:           patients           ?? this.patients,
        alertesCritiques:   alertesCritiques   ?? this.alertesCritiques,
        alertesASurveiller: alertesASurveiller ?? this.alertesASurveiller,
        codeInvitation:     codeInvitation     ?? this.codeInvitation,
        invitationExpireLE: invitationExpireLE ?? this.invitationExpireLE,
      );

  int get nombrePatients       => patients.length;
  int get nombreCritiques      => alertesCritiques.length;
  int get nombreASurveiller    => alertesASurveiller.length;
}

class MedecinNotifier extends StateNotifier<MedecinState> {
  final ApiClient _api;
  final int? _userId;

  MedecinNotifier(this._api, this._userId) : super(const MedecinState());

  Future<void> charger() async {
    state = state.copyWith(isLoading: true);
    try {
      // Charger les alertes
      final alertesResp = await _api.get(ApiEndpoints.alertes);
      final alertes = (alertesResp.data as List)
          .map((a) => Alerte.fromJson(a))
          .toList();

      final critiques = alertes
          .where((a) => a.estCritique && !a.estAquittee)
          .toList();

      final aSurveiller = alertes
          .where((a) => a.estAvertissement && !a.estAquittee)
          .toList();

      // Charger les patients (filtrés par médecin côté mobile)
      final patientsResp = await _api.get(ApiEndpoints.patientsList);
      final tousPatients = (patientsResp.data as List)
          .map((p) => PatientMedecin.fromJson(p))
          .toList();
      final mesPatients = _userId != null
          ? tousPatients.where((p) => p.medecinId == _userId).toList()
          : tousPatients;

      state = state.copyWith(
        isLoading:          false,
        alertesCritiques:   critiques,
        alertesASurveiller: aSurveiller,
        patients:           mesPatients,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> acquitter(int alerteId, String par) async {
    try {
      await _api.patch(
        ApiEndpoints.acquitterAlerte(alerteId),
        data: {'acquittee_par': par},
      );
      await charger();
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'acquittement.');
    }
  }

  Future<void> genererInvitation() async {
    final response = await _api.post(ApiEndpoints.genererInvitation);
    final data = response.data as Map<String, dynamic>;
    state = state.copyWith(
      codeInvitation:     data['code'],
      invitationExpireLE: DateTime.parse(data['expire_le']),
    );
  }
}

final medecinProvider =
    StateNotifierProvider<MedecinNotifier, MedecinState>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  return MedecinNotifier(ref.watch(apiClientProvider), userId);
});
