import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class DerniereMesure {
  final int systolique;
  final int diastolique;
  final int? pouls;
  final String categorie;
  final String sessionId;
  final String periode;
  final int jour;
  final int numeroMesure;
  final DateTime priseLE;

  const DerniereMesure({
    required this.systolique,
    required this.diastolique,
    this.pouls,
    required this.categorie,
    required this.sessionId,
    required this.periode,
    required this.jour,
    required this.numeroMesure,
    required this.priseLE,
  });

  factory DerniereMesure.fromJson(Map<String, dynamic> json) =>
      DerniereMesure(
        systolique: json['systolique'],
        diastolique: json['diastolique'],
        pouls: json['pouls'],
        categorie: json['categorie'],
        sessionId: json['session_id'],
        periode: json['periode'],
        jour: json['jour'],
        numeroMesure: json['numero_mesure'],
        priseLE: DateTime.parse(json['prise_le']),
      );
}

class HomeState {
  final bool isLoading;
  final String? error;
  final DerniereMesure? derniereMesure;
  final int nombreMesuresAujourdhui;
  final int patientId;

  const HomeState({
    this.isLoading = false,
    this.error,
    this.derniereMesure,
    this.nombreMesuresAujourdhui = 0,
    this.patientId = 0,
  });

  HomeState copyWith({
    bool? isLoading,
    String? error,
    DerniereMesure? derniereMesure,
    int? nombreMesuresAujourdhui,
    int? patientId,
  }) =>
      HomeState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        derniereMesure: derniereMesure ?? this.derniereMesure,
        nombreMesuresAujourdhui:
            nombreMesuresAujourdhui ?? this.nombreMesuresAujourdhui,
        patientId: patientId ?? this.patientId,
      );
}

class HomeNotifier extends StateNotifier<HomeState> {
  final ApiClient _api;

  HomeNotifier(this._api) : super(const HomeState());

  Future<void> charger(int patientId) async {
    state = state.copyWith(isLoading: true, patientId: patientId);
    try {
      final response = await _api.get(
        ApiEndpoints.mesuresPatient(patientId),
      );
      final mesures = (response.data as List)
          .map((m) => DerniereMesure.fromJson(m))
          .toList();

      // Compter les mesures d'aujourd'hui
      final today = DateTime.now();
      final mesuresAujourdhui = mesures.where((m) {
        return m.priseLE.year == today.year &&
            m.priseLE.month == today.month &&
            m.priseLE.day == today.day;
      }).length;

      state = state.copyWith(
        isLoading: false,
        derniereMesure: mesures.isNotEmpty ? mesures.first : null,
        nombreMesuresAujourdhui: mesuresAujourdhui,
        patientId: patientId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(apiClientProvider));
});