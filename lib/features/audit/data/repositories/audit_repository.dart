import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/audit_event_model.dart';

/// Repository placeholder for immutable audit event reads.
class AuditRepository {
  /// Creates an audit repository.
  const AuditRepository();

  /// Placeholder contract for loading audit events.
  Future<Result<List<AuditEventModel>>> getAuditEvents() async {
    return const Failure(
      AppFailure(message: 'Audit logic is not implemented yet.'),
    );
  }
}
