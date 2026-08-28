import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/profile/domain/profile_validator.dart';

void main() {
  group('ProfileValidator.name', () {
    test('requires a non-empty value', () {
      expect(
        ProfileValidator.name(' ', 'First name'),
        'First name is required.',
      );
    });

    test('requires at least two characters', () {
      expect(
        ProfileValidator.name('A', 'First name'),
        'First name must contain at least 2 characters.',
      );
    });

    test('accepts valid names with surrounding spaces', () {
      expect(ProfileValidator.name(' Ada ', 'First name'), isNull);
    });
  });

  group('ProfileValidator.phoneNumber', () {
    test('allows empty optional phone numbers', () {
      expect(ProfileValidator.phoneNumber(' '), isNull);
    });

    test('accepts simple international phone numbers', () {
      expect(ProfileValidator.phoneNumber('+234 801 234 5678'), isNull);
    });

    test('rejects letters and punctuation outside the accepted format', () {
      expect(
        ProfileValidator.phoneNumber('+234-801-abc'),
        'Please enter a valid phone number.',
      );
    });
  });

  group('ProfileValidator.profilePhotoUrl', () {
    test('allows empty optional photo URLs', () {
      expect(ProfileValidator.profilePhotoUrl(' '), isNull);
    });

    test('accepts http and https URLs', () {
      expect(
        ProfileValidator.profilePhotoUrl('https://cdn.example.com/avatar.jpg'),
        isNull,
      );
      expect(
        ProfileValidator.profilePhotoUrl('http://cdn.example.com/avatar.jpg'),
        isNull,
      );
    });

    test('rejects non-web or hostless URLs', () {
      expect(
        ProfileValidator.profilePhotoUrl('file:///tmp/avatar.jpg'),
        'Please enter a valid image URL.',
      );
      expect(
        ProfileValidator.profilePhotoUrl('https:///avatar.jpg'),
        'Please enter a valid image URL.',
      );
    });
  });
}
