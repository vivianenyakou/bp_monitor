import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class MesureHistorique {
  final int id;
  final int systolique;
  final int diastolique;
  final int? pouls;
  final String categorie;
  final String periode;
  final int jour;
  final String sessionId;
  final DateTime priseLE;

  const MesureHistorique({
    required this.id,
    required this.systolique,
    required this.diastolique,
    this.pouls,
    required this.categorie,
    required this.periode,
    required this.jour,
    required this.sessionId,
    required this.priseLE,
  });

  factory MesureHistorique.fromJson(Map<String, dynamic> json) =>
      MesureHistorique(
        id:          json['id'],
        systolique:  json['systolique'],
        diastolique: json['diastolique'],
        pouls:       json['pouls'],
        categorie:   json['categorie'],
        periode:     json['periode'],
        jour:        json['jour'],
        sessionId:   json['session_id'],
        priseLE:     DateTime.parse(json['prise_le']),
      );
}

class SessionResume {
  final String sessionId;
  final DateTime date;
  final int nombreMesures;
  final double moyenneSys;
  final double moyenneDia;
  final double? moyennePouls;
  final String categorie;

  const SessionResume({
    required this.sessionId,
    required this.date,
    required this.nombreMesures,
    required this.moyenneSys,
    required this.moyenneDia,
    this.moyennePouls,
    required this.categorie,
  });
}

class HistoriqueState {
  final bool isLoading;
  final String? error;
  final List<MesureHistorique> mesures;
  final List<SessionResume> sessions;
  final double moyenneSys;
  final double moyenneDia;
  final double? moyennePouls;

  const HistoriqueState({
    this.isLoading    = false,
    this.error,
    this.mesures      = const [],
    this.sessions     = const [],
    this.moyenneSys   = 0,
    this.moyenneDia   = 0,
    this.moyennePouls,
  });

  HistoriqueState copyWith({
    bool? isLoading,
    String? error,
    List<MesureHistorique>? mesures,
    List<SessionResume>? sessions,
    double? moyenneSys,
    double? moyenneDia,
    double? moyennePouls,
  }) =>
      HistoriqueState(
        isLoading:     isLoading     ?? this.isLoading,
        error:         error,
        mesures:       mesures       ?? this.mesures,
        sessions:      sessions      ?? this.sessions,
        moyenneSys:    moyenneSys    ?? this.moyenneSys,
        moyenneDia:    moyenneDia    ?? this.moyenneDia,
        moyennePouls:  moyennePouls  ?? this.moyennePouls,
      );
}

class HistoriqueNotifier extends StateNotifier<HistoriqueState> {
  final ApiClient _api;

  HistoriqueNotifier(this._api) : super(const HistoriqueState());

  Future<void> charger(int patientId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get(
        ApiEndpoints.mesuresPatient(patientId),
      );
      final mesures = (response.data as List)
          .map((m) => MesureHistorique.fromJson(m))
          .toList();

      // Calculer les moyennes globales
      final moyenneSys = mesures.isEmpty
          ? 0.0
          : mesures.map((m) => m.systolique).reduce((a, b) => a + b) /
              mesures.length;

      final moyenneDia = mesures.isEmpty
          ? 0.0
          : mesures.map((m) => m.diastolique).reduce((a, b) => a + b) /
              mesures.length;

      final mesuresAvecPouls =
          mesures.where((m) => m.pouls != null).toList();
      final moyennePouls = mesuresAvecPouls.isEmpty
          ? null
          : mesuresAvecPouls.map((m) => m.pouls!).reduce((a, b) => a + b) /
              mesuresAvecPouls.length;

      // Grouper par session
      final sessions = _grouperParSession(mesures);

      state = state.copyWith(
        isLoading:    false,
        mesures:      mesures,
        sessions:     sessions,
        moyenneSys:   moyenneSys,
        moyenneDia:   moyenneDia,
        moyennePouls: moyennePouls,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<SessionResume> _grouperParSession(List<MesureHistorique> mesures) {
    final Map<String, List<MesureHistorique>> groupes = {};
    for (final m in mesures) {
      groupes.putIfAbsent(m.sessionId, () => []).add(m);
    }

    return groupes.entries.map((entry) {
      final liste = entry.value;
      final sys = liste.map((m) => m.systolique).reduce((a, b) => a + b) /
          liste.length;
      final dia = liste.map((m) => m.diastolique).reduce((a, b) => a + b) /
          liste.length;

      final avecPouls = liste.where((m) => m.pouls != null).toList();
      final pouls = avecPouls.isEmpty
          ? null
          : avecPouls.map((m) => m.pouls!).reduce((a, b) => a + b) /
              avecPouls.length;

      return SessionResume(
        sessionId:      entry.key,
        date:           liste.first.priseLE,
        nombreMesures:  liste.length,
        moyenneSys:     sys,
        moyenneDia:     dia,
        moyennePouls:   pouls,
        categorie:      _determinerCategorie(sys, dia),
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _determinerCategorie(double sys, double dia) {
    if (sys >= 180 || dia >= 110) return 'critique';
    if (sys >= 140 || dia >= 90)  return 'hypertension';
    if (sys >= 130 || dia >= 85)  return 'elevee';
    return 'normale';
  }
}

final historiqueProvider =
    StateNotifierProvider<HistoriqueNotifier, HistoriqueState>((ref) {
  return HistoriqueNotifier(ref.watch(apiClientProvider));
});