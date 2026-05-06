import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/auth_model.dart';

// State
class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        user: user ?? this.user,
      );
}

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<bool> login(String identifiant, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: {'identifiant': identifiant, 'password': password},
      );
      final token = TokenModel.fromJson(response.data);
      await _api.saveTokens(token.accessToken, token.refreshToken);
      await _chargerProfil();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? organisationCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (organisationCode != null)
            'organisation_code': organisationCode,
        },
      );
      final token = TokenModel.fromJson(response.data);
      await _api.saveTokens(token.accessToken, token.refreshToken);
      await _chargerProfil();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<void> _chargerProfil() async {
    final response = await _api.get(ApiEndpoints.me);
    final user = UserModel.fromJson(response.data);
    state = state.copyWith(isLoading: false, user: user);
  }

  Future<void> logout() async {
    await _api.clearTokens();
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('401')) return 'Identifiants incorrects.';
    if (e.toString().contains('409')) return 'Email déjà utilisé.';
    if (e.toString().contains('404')) return 'Organisation introuvable.';
    return 'Une erreur est survenue.';
  }
}

// Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  client.init();
  return client;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});