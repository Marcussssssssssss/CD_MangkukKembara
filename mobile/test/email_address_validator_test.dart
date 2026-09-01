import 'package:flutter_test/flutter_test.dart';
import 'package:mangkuk_kembara/core/email_address_validator.dart';

void main() {
  group('EmailAddressValidator.validateChange', () {
    const current = 'traveller@example.com';

    test('accepts and normalizes a realistic new address', () {
      expect(
        EmailAddressValidator.validateChange(
          '  New.Traveller+alerts@Example.COM  ',
          currentEmail: current,
        ),
        isNull,
      );
      expect(
        EmailAddressValidator.normalize(' New@Example.COM '),
        'new@example.com',
      );
    });

    test('rejects the current address without case sensitivity', () {
      expect(
        EmailAddressValidator.validateChange(
          'TRAVELLER@EXAMPLE.COM',
          currentEmail: current,
        ),
        contains('different'),
      );
    });

    test('rejects malformed addresses', () {
      for (final value in [
        '',
        'missing-at.example.com',
        '.leading@example.com',
        'double..dot@example.com',
        'person@-example.com',
        'person@example',
      ]) {
        expect(
          EmailAddressValidator.validateChange(value, currentEmail: current),
          isNotNull,
          reason: value,
        );
      }
    });
  });
}
