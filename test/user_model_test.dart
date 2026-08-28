import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/enums/user_role.dart';
import 'package:servio/features/profile/data/models/user_model.dart';

void main() {
  test('parses profile documents with string timestamps', () {
    final user = UserModel.fromJson({
      'uid': 'uid-1',
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'email': 'ada@example.com',
      'role': 'student',
      'department': 'Computer Science',
      'isEmailVerified': true,
      'isActive': true,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-02T00:00:00.000Z',
      'phoneNumber': '+234 801 234 5678',
      'faculty': 'Engineering',
      'matricNumber': 'CSC/001',
      'staffId': null,
      'profilePhotoUrl': 'https://cdn.example.com/avatar.jpg',
      'institutionId': 'servio-demo',
    });

    expect(user.uid, 'uid-1');
    expect(user.role, UserRole.student);
    expect(user.createdAt, DateTime.utc(2026));
    expect(user.updatedAt, DateTime.utc(2026, 1, 2));
    expect(user.matricNumber, 'CSC/001');
  });
}
