abstract final class EmailAddressValidator {
  static String normalize(String value) => value.trim().toLowerCase();

  static String? validateChange(String? value, {required String currentEmail}) {
    final email = normalize(value ?? '');
    if (email.isEmpty) return 'New email is required';
    if (email.length > 254) return 'Email address is too long';

    final at = email.lastIndexOf('@');
    if (at <= 0 || at != email.indexOf('@')) {
      return 'Enter a valid email address';
    }
    final local = email.substring(0, at);
    final domain = email.substring(at + 1);
    if (local.length > 64 ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..') ||
        !RegExp(r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+$").hasMatch(local) ||
        !_isValidDomain(domain)) {
      return 'Enter a valid email address';
    }
    if (email == normalize(currentEmail)) {
      return 'Use an email different from your current one';
    }
    return null;
  }

  static bool _isValidDomain(String domain) {
    if (domain.isEmpty || domain.length > 253 || !domain.contains('.')) {
      return false;
    }
    final labels = domain.split('.');
    return labels.every(
      (label) =>
          label.isNotEmpty &&
          label.length <= 63 &&
          !label.startsWith('-') &&
          !label.endsWith('-') &&
          RegExp(r'^[a-z0-9-]+$').hasMatch(label),
    );
  }
}
