import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/audit_event_model.dart';
import '../services/audit_service.dart';

/// Repository for immutable audit event reads.
///
/// There is no write method here on purpose. Audit events are never
/// written on their own — each one is committed inside the same batch or
/// transaction as the action it records, by that action's own repository,
/// so an event can't outlive a rolled-back write (FR-AUDIT-001).
class AuditRepository {
  /// Creates an audit repository.
  const AuditRepository(this._service);

  final AuditService _service;

  /// Retrieves the most recent audit events in reverse chronological
  /// order (FR-AUDIT-004).
  Future<Result<List<AuditEventModel>>> getAuditEvents({int limit = 300}) async {
    try {
      final snapshot = await _service.getRecentEvents(limit: limit);
      final events = snapshot.docs
          .map((doc) => AuditEventModel.fromJson(doc.data()))
          .toList();
      return Success(events);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  AppFailure _mapFirebaseException(FirebaseException error) {
    final message = switch (error.code) {
      'permission-denied' => 'You do not have permission to view audit history.',
      'unavailable' =>
        'Unable to connect. Check your internet connection and try again.',
      _ => 'Unable to load audit history. Please try again.',
    };
    return AppFailure(
      message: message,
      type: error.code == 'unavailable'
          ? FailureType.network
          : FailureType.database,
      code: error.code,
      technicalDetails: error,
    );
  }

  AppFailure _unknownFailure(Object error) {
    return AppFailure(
      message: 'Something unexpected happened. Please try again.',
      technicalDetails: error,
    );
  }
}
