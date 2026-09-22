import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/services/audit_service.dart';
import '../../domain/use_cases/get_audit_events_use_case.dart';
import '../controllers/audit_controller.dart';
import '../controllers/audit_state.dart';

/// Provides the audit Firestore service.
final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(ref.watch(firebaseFirestoreProvider));
});

/// Provides the audit repository.
final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(auditServiceProvider));
});

/// Provides the get audit events use case.
final getAuditEventsUseCaseProvider = Provider<GetAuditEventsUseCase>((ref) {
  return GetAuditEventsUseCase(ref.watch(auditRepositoryProvider));
});

/// Provides the audit history controller.
final auditControllerProvider =
    AsyncNotifierProvider<AuditController, AuditState>(AuditController.new);
