import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

enum BPCategorie { normale, elevee, hypertension, critique }

class MesureState {
  final bool isLoading;
  final bool sessionLoading;
  final String? error;
  final int systolique;
  final int diastolique;
  final int? pouls;

  // Session (GET /sessions/patient/{id})
  final String creneauActuel; // 'matin' | 'soir' | 'hors_creneau'
  final String? messageCreneauHors;
  final int jourActuel;
  final int mesuresRestantes;
  final String? sessionId;
  final bool protocoleTermine;
  final bool jour1Complete;
  final bool jour2Complete;
  final bool jour3Complete;

  // Résultat après enregistrement
  final bool popupMedicament;
  final String? messageFin;
  final String? categorieApresEnvoi;

  const MesureState({
    this.isLoading = false,
    this.sessionLoading = true,
    this.error,
    this.systolique = 120,
    this.diastolique = 80,
    this.pouls,
    this.creneauActuel = 'matin',
    this.messageCreneauHors,
    this.jourActuel = 1,
    this.mesuresRestantes = 3,
    this.sessionId,
    this.protocoleTermine = false,
    this.jour1Complete = false,
    this.jour2Complete = false,
    this.jour3Complete = false,
    this.popupMedicament = false,
    this.messageFin,
    this.categorieApresEnvoi,
  });

  bool get estHorsCreneaux => creneauActuel == 'hors_creneau';
  bool get creneauTermine => !estHorsCreneaux && mesuresRestantes == 0;
  bool get peutSaisir =>
      !estHorsCreneaux && !protocoleTermine && mesuresRestantes > 0;

  // Numéro de la prochaine mesure à saisir dans le créneau (1, 2 ou 3)
  int get numeroMesureActuel => 4 - mesuresRestantes;

  BPCategorie get categorieActuelle {
    if (systolique >= AppConstants.systoliqueCritique ||
        diastolique >= AppConstants.diastolicCritique) {
      return BPCategorie.critique;
    }
    if (systolique >= AppConstants.systoliqueHigh ||
        diastolique >= AppConstants.diastolicHigh) {
      return BPCategorie.hypertension;
    }
    if (systolique >= AppConstants.systoliqueNormal ||
        diastolique >= AppConstants.diastolicNormal) {
      return BPCategorie.elevee;
    }
    return BPCategorie.normale;
  }

  MesureState copyWith({
    bool? isLoading,
    bool? sessionLoading,
    String? error,
    int? systolique,
    int? diastolique,
    int? pouls,
    String? creneauActuel,
    String? messageCreneauHors,
    int? jourActuel,
    int? mesuresRestantes,
    String? sessionId,
    bool? protocoleTermine,
    bool? jour1Complete,
    bool? jour2Complete,
    bool? jour3Complete,
    bool? popupMedicament,
    String? messageFin,
    String? categorieApresEnvoi,
  }) =>
      MesureState(
        isLoading: isLoading ?? this.isLoading,
        sessionLoading: sessionLoading ?? this.sessionLoading,
        error: error, // toujours écrasé — null efface l'erreur
        systolique: systolique ?? this.systolique,
        diastolique: diastolique ?? this.diastolique,
        pouls: pouls ?? this.pouls,
        creneauActuel: creneauActuel ?? this.creneauActuel,
        messageCreneauHors: messageCreneauHors ?? this.messageCreneauHors,
        jourActuel: jourActuel ?? this.jourActuel,
        mesuresRestantes: mesuresRestantes ?? this.mesuresRestantes,
        sessionId: sessionId ?? this.sessionId,
        protocoleTermine: protocoleTermine ?? this.protocoleTermine,
        jour1Complete: jour1Complete ?? this.jour1Complete,
        jour2Complete: jour2Complete ?? this.jour2Complete,
        jour3Complete: jour3Complete ?? this.jour3Complete,
        popupMedicament: popupMedicament ?? this.popupMedicament,
        messageFin: messageFin ?? this.messageFin,
        categorieApresEnvoi: categorieApresEnvoi ?? this.categorieApresEnvoi,
      );
}

class MesureNotifier extends StateNotifier<MesureState> {
  final ApiClient _api;

  MesureNotifier(this._api) : super(const MesureState());

  void mettreAJourSystolique(int v) => state = state.copyWith(systolique: v);
  void mettreAJourDiastolique(int v) => state = state.copyWith(diastolique: v);
  void mettreAJourPouls(int v) => state = state.copyWith(pouls: v);

  Future<void> chargerSession(int patientId) async {
    state = state.copyWith(sessionLoading: true);
    try {
      final resp = await _api.get(ApiEndpoints.sessionPatient(patientId));
      final data = resp.data as Map<String, dynamic>;
      final msg = data['message_creneau'] as String?;
      state = state.copyWith(
        sessionLoading: false,
        creneauActuel: (data['creneau_actuel'] as String?) ?? 'hors_creneau',
        messageCreneauHors: (msg != null && msg.isNotEmpty) ? msg : null,
        jourActuel: (data['jour_actuel'] as int?) ?? 1,
        mesuresRestantes: (data['mesures_restantes'] as int?) ?? 0,
        sessionId: data['session_id'] as String?,
        protocoleTermine: (data['protocole_termine'] as bool?) ?? false,
        jour1Complete: (data['jour1_complete'] as bool?) ?? false,
        jour2Complete: (data['jour2_complete'] as bool?) ?? false,
        jour3Complete: (data['jour3_complete'] as bool?) ?? false,
      );
    } catch (_) {
      state = state.copyWith(
        sessionLoading: false,
        error: 'Impossible de charger la session.',
      );
    }
  }

  Future<bool> enregistrer(int patientId) async {
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _api.post(
        ApiEndpoints.sessionMesure,
        data: {
          'patient_id': patientId,
          'systolique': state.systolique,
          'diastolique': state.diastolique,
          if (state.pouls != null) 'pouls': state.pouls,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        popupMedicament: (data['popup_medicament'] as bool?) ?? false,
        messageFin: data['message_fin'] as String?,
        categorieApresEnvoi: data['categorie'] as String?,
        systolique: 120,
        diastolique: 80,
      );
      // Rechargement silencieux pour synchroniser l'état de session
      _rechargerSession(patientId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extraireErreur(e));
      return false;
    }
  }

  void dismissPopupMedicament() =>
      state = state.copyWith(popupMedicament: false);

  void _rechargerSession(int patientId) {
    _api.get(ApiEndpoints.sessionPatient(patientId)).then((resp) {
      if (!mounted) return;
      final data = resp.data as Map<String, dynamic>;
      final msg = data['message_creneau'] as String?;
      state = state.copyWith(
        creneauActuel: (data['creneau_actuel'] as String?) ?? state.creneauActuel,
        messageCreneauHors: (msg != null && msg.isNotEmpty) ? msg : null,
        jourActuel: (data['jour_actuel'] as int?) ?? state.jourActuel,
        mesuresRestantes: (data['mesures_restantes'] as int?) ?? state.mesuresRestantes,
        sessionId: (data['session_id'] as String?) ?? state.sessionId,
        protocoleTermine: (data['protocole_termine'] as bool?) ?? state.protocoleTermine,
        jour1Complete: (data['jour1_complete'] as bool?) ?? state.jour1Complete,
        jour2Complete: (data['jour2_complete'] as bool?) ?? state.jour2Complete,
        jour3Complete: (data['jour3_complete'] as bool?) ?? state.jour3Complete,
      );
    }).catchError((_) {});
  }

  String _extraireErreur(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('hors_creneau') || msg.contains('creneau')) {
      return 'Vous êtes hors créneau. Réessayez au prochain créneau.';
    }
    if (msg.contains('jour') || msg.contains('complet')) {
      return 'Terminez les mesures du jour précédent d\'abord.';
    }
    if (msg.contains('maximum') || msg.contains('3 mesure')) {
      return 'Vous avez déjà effectué 3 mesures pour ce créneau.';
    }
    return 'Erreur lors de l\'enregistrement. Vérifiez votre connexion.';
  }
}

final mesureProvider =
    StateNotifierProvider<MesureNotifier, MesureState>((ref) {
  return MesureNotifier(ref.watch(apiClientProvider));
});
