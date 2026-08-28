import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/internship/domain/internship_validator.dart';

void main() {
  group('InternshipValidator.requiredText', () {
    test('requires non-empty text', () {
      expect(
        InternshipValidator.requiredText(' ', 'Company name'),
        'Company name is required.',
      );
    });

    test('accepts trimmed text', () {
      expect(
        InternshipValidator.requiredText(' MTN Nigeria ', 'Company name'),
        isNull,
      );
    });
  });

  group('InternshipValidator.phoneNumber', () {
    test('requires supervisor phone number', () {
      expect(
        InternshipValidator.phoneNumber(' '),
        'Supervisor phone number is required.',
      );
    });

    test('rejects invalid phone number format', () {
      expect(
        InternshipValidator.phoneNumber('080-abc'),
        'Please enter a valid supervisor phone number.',
      );
    });

    test('accepts valid phone numbers', () {
      expect(InternshipValidator.phoneNumber('+234 801 234 5678'), isNull);
    });
  });

  group('InternshipValidator.dates', () {
    test('requires start and end dates', () {
      expect(
        InternshipValidator.dates(startDate: null, endDate: DateTime.utc(2026)),
        'Start date is required.',
      );
      expect(
        InternshipValidator.dates(startDate: DateTime.utc(2026), endDate: null),
        'End date is required.',
      );
    });

    test('rejects end date before start date', () {
      expect(
        InternshipValidator.dates(
          startDate: DateTime.utc(2026, 8, 2),
          endDate: DateTime.utc(2026, 8, 1),
        ),
        'End date cannot be before start date.',
      );
    });

    test('accepts same-day or later end date', () {
      expect(
        InternshipValidator.dates(
          startDate: DateTime.utc(2026, 8),
          endDate: DateTime.utc(2026, 8),
        ),
        isNull,
      );
    });
  });
}
