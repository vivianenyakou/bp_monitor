import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

enum BPCategorie { normale, elevee, hypertension, critique }

class MesureState {
  final bool isLoading;
  final String? error;
  final String? success;
  final int systolique;
  final int diastolique;
  final int? pouls;
  final BPCategorie? categorie;
  final int jour;
  final int numeroMesure;
  final String periode;
  final String? sessionId;

  const MesureState({
    this.isLoading   = false,
    this.error,
    this.success,
    this.systolique  = 120,
    this.diastolique = 80,
    this.pouls,
    this.categorie,
    this.jour        = 1,
    this.numeroMesure = 1,
    this.periode     = 'matin',
    this.sessionId,
  });

  MesureState copyWith({
    bool? isLoading,
    String? error,
    String? success,
    int? systolique,
    int? diastolique,
    int? pouls,
    BPCategorie? categorie,
    int? jour,
    int? numeroMesure,
    String? periode,
    String? sessionId,
  }) =>
      MesureState(
        isLoading:    isLoading    ?? this.isLoading,
        error:        error,
        success:      success,
        systolique:   systolique   ?? this.systolique,
        diastolique:  diastolique  ?? this.diastolique,
        pouls:        pouls        ?? this.pouls,
        categorie:    categorie    ?? this.categorie,
        jour:         jour         ?? this.jour,
        numeroMesure: numeroMesure ?? this.numeroMesure,
        periode:      periode      ?? this.periode,
        sessionId:    sessionId    ?? this.sessionId,
      );

  // Analyse en temps réel
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
}

class MesureNotifier extends StateNotifier<MesureState> {
  final ApiClient _api;

  MesureNotifier(this._api) : super(const MesureState());

  void mettreAJourSystolique(int v) =>
      state = state.copyWith(systolique: v);

  void mettreAJourDiastolique(int v) =>
      state = state.copyWith(diastolique: v);

  void mettreAJourPouls(int v) =>
      state = state.copyWith(pouls: v);

  void mettreAJourJour(int v) =>
      state = state.copyWith(jour: v);

  void mettreAJourPeriode(String v) =>
      state = state.copyWith(periode: v);

  void mettreAJourNumeroMesure(int v) =>
      state = state.copyWith(numeroMesure: v);

  Future<bool> enregistrer(int patientId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        ApiEndpoints.mesures,
        data: {
          'patient_id':    patientId,
          'systolique':    state.systolique,
          'diastolique':   state.diastolique,
          'pouls':         state.pouls,
          'periode':       state.periode,
          'jour':          state.jour,
          'numero_mesure': state.numeroMesure,
          if (state.sessionId != null) 'session_id': state.sessionId,
        },
      );
      state = state.copyWith(
        isLoading: false,
        success: 'Mesure enregistrée avec succès !',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'enregistrement.',
      );
      return false;
    }
  }
}

final mesureProvider =
    StateNotifierProvider<MesureNotifier, MesureState>((ref) {
  return MesureNotifier(ref.watch(apiClientProvider));
});