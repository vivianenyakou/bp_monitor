import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class Alerte {
  final int id;
  final int patientId;
  final int? medecinId;
  final int systolique;
  final int diastolique;
  final String niveau;
  final String statut;
  final String message;
  final DateTime declencheeLE;
  final DateTime? acquitteeLE;
  final String? acquitteePar;

  const Alerte({
    required this.id,
    required this.patientId,
    this.medecinId,
    required this.systolique,
    required this.diastolique,
    required this.niveau,
    required this.statut,
    required this.message,
    required this.declencheeLE,
    this.acquitteeLE,
    this.acquitteePar,
  });

  factory Alerte.fromJson(Map<String, dynamic> json) => Alerte(
        id:           json['id'],
        patientId:    json['patient_id'],
        medecinId:    json['medecin_id'],
        systolique:   json['systolique'],
        diastolique:  json['diastolique'],
        niveau:       json['niveau'],
        statut:       json['statut'],
        message:      json['message'],
        declencheeLE: DateTime.parse(json['declenchee_le']),
        acquitteeLE:  json['acquittee_le'] != null
            ? DateTime.parse(json['acquittee_le'])
            : null,
        acquitteePar: json['acquittee_par'],
      );

  bool get estCritique     => niveau == 'critique';
  bool get estAvertissement => niveau == 'avertissement';
  bool get estAquittee     => statut == 'acquittee';
  bool get estEnAttente    => statut == 'en_attente';
}

class AlertesState {
  final bool isLoading;
  final String? error;
  final List<Alerte> alertes;

  const AlertesState({
    this.isLoading = false,
    this.error,
    this.alertes   = const [],
  });

  AlertesState copyWith({
    bool? isLoading,
    String? error,
    List<Alerte>? alertes,
  }) =>
      AlertesState(
        isLoading: isLoading ?? this.isLoading,
        error:     error,
        alertes:   alertes   ?? this.alertes,
      );

  List<Alerte> get critiques =>
      alertes.where((a) => a.estCritique && !a.estAquittee).toList();

  List<Alerte> get enAttente =>
      alertes.where((a) => a.estEnAttente).toList();
}

class AlertesNotifier extends StateNotifier<AlertesState> {
  final ApiClient _api;

  AlertesNotifier(this._api) : super(const AlertesState());

  Future<void> charger() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get(ApiEndpoints.alertes);
      final alertes = (response.data as List)
          .map((a) => Alerte.fromJson(a))
          .toList();
      state = state.copyWith(isLoading: false, alertes: alertes);
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
}

final alertesProvider =
    StateNotifierProvider<AlertesNotifier, AlertesState>((ref) {
  return AlertesNotifier(ref.watch(apiClientProvider));
});