class Validators {
  const Validators._();

  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  static String? domain(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Domain is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(text)) {
      return 'Use a valid domain';
    }
    return null;
  }
}
