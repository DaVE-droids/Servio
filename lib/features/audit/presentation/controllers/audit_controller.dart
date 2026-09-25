import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../providers/audit_providers.dart';
import 'audit_state.dart';

/// Controller for the coordinator's audit history (FR-AUDIT-004/005).
class AuditController extends AsyncNotifier<AuditState> {
  /// Loads the audit history.
  ///
  /// Watches the auth session for the same reason the notifications
  /// controller does: only a coordinator can read this collection, so
  /// switching accounts must re-run the query rather than serve a list
  /// loaded under someone else's permissions.
  @override
  Future<AuditState> build() async {
    final uid = switch (ref.watch(authSessionProvider)) {
      AsyncData(:final value) => value.firebaseUser?.uid,
      _ => null,
    };
    if (uid == null) {
      return const AuditState();
    }
    return _load(const AuditFilter());
  }

  /// Reloads the history, keeping the current filters applied.
  Future<void> refresh() async {
    final filter = switch (state) {
      AsyncData(:final value) => value.filter,
      _ => const AuditFilter(),
    };
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(filter));
  }

  /// Applies a new set of filters. Filtering happens over the already
  /// loaded page, so this never re-queries Firestore.
  void applyFilter(AuditFilter filter) {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const AuditState(),
    };
    state = AsyncData(previous.copyWith(filter: filter, clearMessages: true));
  }

  /// Clears every filter.
  void clearFilters() => applyFilter(const AuditFilter());

  Future<AuditState> _load(AuditFilter filter) async {
    final result = await ref.read(getAuditEventsUseCaseProvider).call();
    return switch (result) {
      Success(:final data) => AuditState(events: data, filter: filter),
      Failure(:final error) => AuditState(
        filter: filter,
        errorMessage: error.message,
      ),
    };
  }
}
