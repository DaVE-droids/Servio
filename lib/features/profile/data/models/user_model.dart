import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/user_role.dart';

/// Firestore model for documents in `users/{uid}`.
class UserModel {
  /// Creates a user model.
  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.department,
    required this.isEmailVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.faculty,
    this.matricNumber,
    this.staffId,
    this.profilePhotoUrl,
    this.institutionId,
  });

  /// Firebase Authentication UID.
  final String uid;

  /// User's first name.
  final String firstName;

  /// User's last name.
  final String lastName;

  /// Email address.
  final String email;

  /// Optional contact number.
  final String? phoneNumber;

  /// Application role.
  final UserRole role;

  /// Academic department.
  final String department;

  /// Optional faculty or school.
  final String? faculty;

  /// Student matric number.
  final String? matricNumber;

  /// Staff identifier for lecturers and coordinators.
  final String? staffId;

  /// Optional profile photo URL.
  final String? profilePhotoUrl;

  /// Cached Firebase email verification state.
  final bool isEmailVerified;

  /// Whether the account is active.
  final bool isActive;

  /// Future multi-institution identifier.
  final String? institutionId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Creates a placeholder user model from JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      department: json['department'] as String,
      isEmailVerified: json['isEmailVerified'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      phoneNumber: json['phoneNumber'] as String?,
      faculty: json['faculty'] as String?,
      matricNumber: json['matricNumber'] as String?,
      staffId: json['staffId'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      institutionId: json['institutionId'] as String?,
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'department': department,
      'faculty': faculty,
      'matricNumber': matricNumber,
      'staffId': staffId,
      'profilePhotoUrl': profilePhotoUrl,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'institutionId': institutionId,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
    };
  }

  /// Returns a copy with selected fields changed.
  UserModel copyWith({String? firstName, String? lastName}) {
    return UserModel(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      role: role,
      department: department,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      phoneNumber: phoneNumber,
      faculty: faculty,
      matricNumber: matricNumber,
      staffId: staffId,
      profilePhotoUrl: profilePhotoUrl,
      institutionId: institutionId,
    );
  }
}

DateTime _readDateTime(Object? value) {
  return switch (value) {
    Timestamp timestamp => timestamp.toDate().toUtc(),
    String text => DateTime.parse(text).toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  };
}
