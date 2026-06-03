class AppConstants {
  // API
  //static const baseUrl = 'http://10.250.90.28:8000/api/v1';
  static const baseUrl = 'https://api.g-autobp.tech/api/v1';

  // Telephone
  static const phoneCountryCode       = '+228';
  static const phoneCountryCodeDigits = '228';

  // Session BP
  static const totalMesuresSession = 18;
  static const mesuresParJour      = 6;  // 3 matin + 3 soir
  static const joursSession        = 3;

  // Seuils BP
  static const systoliqueNormal    = 130;
  static const diastolicNormal     = 85;
  static const systoliqueHigh      = 140;
  static const diastolicHigh       = 90;
  static const systoliqueCritique  = 180;
  static const diastolicCritique   = 110;
}
