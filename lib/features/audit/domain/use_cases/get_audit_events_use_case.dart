import '../../../../core/result/result.dart';
import '../../data/models/audit_event_model.dart';
import '../../data/repositories/audit_repository.dart';

/// Loads the audit history a coordinator reviews (FR-AUDIT-004).
class GetAuditEventsUseCase {
  /// Creates a get audit events use case.
  const GetAuditEventsUseCase(this._repository);

  final AuditRepository _repository;

  /// Executes the audit history load.
  Future<Result<List<AuditEventModel>>> call({int limit = 300}) =>
      _repository.getAuditEvents(limit: limit);
}
