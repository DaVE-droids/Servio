import '../../../../core/result/result.dart';
import '../../data/models/audit_event_model.dart';
import '../../data/repositories/audit_repository.dart';

/// Use case placeholder for loading audit events.
class GetAuditEventsUseCase {
  /// Creates a get audit events use case.
  const GetAuditEventsUseCase(this._repository);

  final AuditRepository _repository;

  /// Executes the placeholder audit load workflow.
  Future<Result<List<AuditEventModel>>> call() => _repository.getAuditEvents();
}
