abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneRegex = RegExp(r'^(03|05|07|08|09)[0-9]{8}$');

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'email');
    if (requiredError != null) {
      return requiredError;
    }
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, 'mật khẩu');
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự';
    }
    return null;
  }

  static String? phone(String? value) {
    final requiredError = required(value, 'số điện thoại');
    if (requiredError != null) {
      return requiredError;
    }
    if (!_phoneRegex.hasMatch(value!.trim())) {
      return 'Số điện thoại phải có 10 chữ số và đầu số hợp lệ';
    }
    return null;
  }

  static String? differentFrom(
    String? value,
    String? otherValue,
    String message,
  ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (otherValue == null || otherValue.isEmpty) {
      return null;
    }
    if (value.trim() == otherValue.trim()) {
      return message;
    }
    return null;
  }
}
