import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/audit_repository.dart';
import '../../data/services/audit_service.dart';
import '../../domain/use_cases/get_audit_events_use_case.dart';
import '../controllers/audit_controller.dart';

/// Provides the audit service placeholder.
final auditServiceProvider = Provider<AuditService>((ref) {
  return const AuditService();
});

/// Provides the audit repository placeholder.
final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return const AuditRepository();
});

/// Provides the get audit events use case placeholder.
final getAuditEventsUseCaseProvider = Provider<GetAuditEventsUseCase>((ref) {
  return GetAuditEventsUseCase(ref.watch(auditRepositoryProvider));
});

/// Provides the audit controller placeholder.
final auditControllerProvider = AsyncNotifierProvider<AuditController, void>(
  AuditController.new,
);
