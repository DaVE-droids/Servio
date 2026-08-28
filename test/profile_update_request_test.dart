import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/profile/data/models/profile_update_request.dart';

void main() {
  test('serializes only user-editable profile fields', () {
    const request = ProfileUpdateRequest(
      firstName: ' Ada ',
      lastName: ' Lovelace ',
      phoneNumber: ' +234 801 234 5678 ',
      faculty: ' Engineering ',
      profilePhotoUrl: ' https://cdn.example.com/avatar.jpg ',
    );

    final json = request.toEditableJson();

    expect(json, {
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'phoneNumber': '+234 801 234 5678',
      'faculty': 'Engineering',
      'profilePhotoUrl': 'https://cdn.example.com/avatar.jpg',
    });
    expect(json.keys, isNot(contains('role')));
    expect(json.keys, isNot(contains('isActive')));
    expect(json.keys, isNot(contains('department')));
    expect(json.keys, isNot(contains('matricNumber')));
    expect(json.keys, isNot(contains('staffId')));
  });

  test('normalizes blank optional fields to null', () {
    const request = ProfileUpdateRequest(
      firstName: 'Ada',
      lastName: 'Lovelace',
      phoneNumber: ' ',
      faculty: '',
      profilePhotoUrl: '   ',
    );

    expect(request.toEditableJson(), {
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'phoneNumber': null,
      'faculty': null,
      'profilePhotoUrl': null,
    });
  });
}
