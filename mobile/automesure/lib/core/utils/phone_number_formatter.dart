import '../constants/app_constants.dart';

String? formatTogoPhoneNumber(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;

  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;

  const countryDigits = AppConstants.phoneCountryCodeDigits;
  if (digits.startsWith('00$countryDigits')) {
    digits = digits.substring(countryDigits.length + 2);
  } else if (digits.startsWith(countryDigits) && digits.length > 8) {
    digits = digits.substring(countryDigits.length);
  } else if (digits.startsWith('0') && digits.length > 8) {
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
  }

  if (digits.isEmpty) return null;
  return '${AppConstants.phoneCountryCode}$digits';
}
