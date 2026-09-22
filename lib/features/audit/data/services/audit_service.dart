import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service for audit event documents.
class AuditService {
  /// Creates an audit service.
  const AuditService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Creates a new audit event document ID.
  String createAuditEventId() {
    return _firestore.collection('audit_events').doc().id;
  }

  /// Returns the most recent audit events, newest first.
  ///
  /// Deliberately unfiltered: the `audit_events` list rule grants a
  /// coordinator every document unconditionally, so this query is
  /// provably safe without a `where` clause, and needs only the automatic
  /// single-field index on `createdAt`. The FR-AUDIT-005 filters (user,
  /// date, action, entity) are applied to this page client-side — at
  /// pilot scale that is one read instead of a composite index per filter
  /// combination. See docs/CHANGELOG.md for the limit's tradeoff.
  Future<QuerySnapshot<Map<String, dynamic>>> getRecentEvents({
    int limit = 300,
  }) {
    return _firestore
        .collection('audit_events')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
  }
}
