import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/authentication/domain/auth_validator.dart';

/// Tests the authentication form validation rules.
void main() {
  group('AuthValidator', () {
    test('requires a valid email address', () {
      expect(AuthValidator.email(''), 'Email is required.');
      expect(
        AuthValidator.email('invalid'),
        'Please enter a valid email address.',
      );
      expect(AuthValidator.email('student@example.com'), isNull);
    });

    test('requires a strong enough password', () {
      expect(AuthValidator.password(''), 'Password is required.');
      expect(
        AuthValidator.password('short'),
        'Password must contain at least 8 characters.',
      );
      expect(AuthValidator.password('password123'), isNull);
    });

    test('requires non-empty text fields', () {
      expect(
        AuthValidator.required('', 'First name'),
        'First name is required.',
      );
      expect(AuthValidator.required('David', 'First name'), isNull);
    });
  });
}
