import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorRequired;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return AppStrings.errorEmailInvalid;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorRequired;
    if (value.length < 8) return AppStrings.errorPasswordShort;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AppStrings.errorRequired;
    if (value != original) return AppStrings.errorPasswordMatch;
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.errorRequired;
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorRequired;
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return AppStrings.errorAmountInvalid;
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorRequired;
    final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final urlRegex = RegExp(
        r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');
    if (!urlRegex.hasMatch(value)) return 'الرابط غير صحيح';
    return null;
  }
}
