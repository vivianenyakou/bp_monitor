class ApiEndpoints {
  // Auth
  static const login           = '/auth/login';
  static const register        = '/auth/register';
  static const me              = '/auth/me';

  // Mesures
  static const mesures         = '/mesures/';
  static String mesuresPatient(int id) => '/mesures/patient/$id';
  static String resumeSession(int id, String sessionId) =>
      '/mesures/resume/$id/$sessionId';

  // Alertes
  static const alertes         = '/alertes/';
  static String acquitterAlerte(int id) => '/alertes/$id/acquitter';

  // Patients
  static const patientsList    = '/patients/';
  static const medecins        = '/patients/medecins/liste';
  static String patient(int id) => '/patients/$id';
  static const genererInvitation = '/patients/invitation/generer';
  static String accepterInvitation(int id) =>
      '/patients/$id/invitation/accepter';
  static String choisirMedecin(int patientId) =>
      '/patients/$patientId/choisir-medecin';
  // Organisations
  static const organisations          = '/organisations/';
  static const organisationsPubliques = '/organisations/publiques';
  static const utilisateurs           = '/auth/utilisateurs';
  static const creerUtilisateur       = '/auth/utilisateurs';
  static String validerQRCode(String token) =>
    '/qrcodes/valider/$token';
}