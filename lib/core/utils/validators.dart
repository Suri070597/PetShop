abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui long nhap $label';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'email');
    if (requiredError != null) {
      return requiredError;
    }
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Email khong hop le';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, 'mat khau');
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.length < 6) {
      return 'Mat khau toi thieu 6 ky tu';
    }
    return null;
  }
}
