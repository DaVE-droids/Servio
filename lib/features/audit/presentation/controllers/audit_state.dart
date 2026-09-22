import '../../data/models/audit_event_model.dart';

/// The FR-AUDIT-005 filters, held as one value.
///
/// Grouping them means [AuditState.copyWith] replaces the whole filter
/// rather than each field individually — which sidesteps the "is null a
/// cleared filter or an omitted argument?" ambiguity that a per-field
/// `copyWith` would have. Clearing is `const AuditFilter()`.
class AuditFilter {
  /// Creates an audit filter. Every unset field matches everything.
  const AuditFilter({
    this.actorId,
    this.action,
    this.entityType,
    this.from,
    this.to,
  });

  /// Only events performed by this user.
  final String? actorId;

  /// Only events with this action type.
  final String? action;

  /// Only events affecting this kind of entity.
  final String? entityType;

  /// Only events on or after this day (local time).
  final DateTime? from;

  /// Only events on or before this day (local time).
  final DateTime? to;

  /// Whether any filter is currently narrowing the list.
  bool get isActive =>
      actorId != null ||
      action != null ||
      entityType != null ||
      from != null ||
      to != null;

  /// Whether [event] passes every active filter.
  bool matches(AuditEventModel event) {
    if (actorId != null && event.actorId != actorId) {
      return false;
    }
    if (action != null && event.action != action) {
      return false;
    }
    if (entityType != null && event.entityType != entityType) {
      return false;
    }
    final day = _dayOf(event.createdAt.toLocal());
    if (from != null && day.isBefore(_dayOf(from!))) {
      return false;
    }
    if (to != null && day.isAfter(_dayOf(to!))) {
      return false;
    }
    return true;
  }

  /// Returns a copy with one field replaced. Pass `clearX: true` to unset.
  AuditFilter copyWith({
    String? actorId,
    bool clearActorId = false,
    String? action,
    bool clearAction = false,
    String? entityType,
    bool clearEntityType = false,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
  }) {
    return AuditFilter(
      actorId: clearActorId ? null : (actorId ?? this.actorId),
      action: clearAction ? null : (action ?? this.action),
      entityType: clearEntityType ? null : (entityType ?? this.entityType),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
    );
  }
}

DateTime _dayOf(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// UI state for the coordinator's audit history.
class AuditState {
  /// Creates audit UI state.
  const AuditState({
    this.events = const [],
    this.filter = const AuditFilter(),
    this.errorMessage,
  });

  /// Every loaded event, newest first.
  final List<AuditEventModel> events;

  /// The filters currently applied to [events].
  final AuditFilter filter;

  /// Last user-facing error message.
  final String? errorMessage;

  /// The events actually shown, after filtering.
  List<AuditEventModel> get visibleEvents =>
      events.where(filter.matches).toList();

  /// Every distinct actor in the loaded events, as id -> display name,
  /// for the "User" filter's options.
  Map<String, String> get actors {
    final result = <String, String>{};
    for (final event in events) {
      result[event.actorId] = event.actorName;
    }
    return result;
  }

  /// Every distinct action in the loaded events, sorted.
  List<String> get actions =>
      (events.map((event) => event.action).toSet().toList())..sort();

  /// Every distinct entity type in the loaded events, sorted.
  List<String> get entityTypes =>
      (events.map((event) => event.entityType).toSet().toList())..sort();

  /// Returns a copy with selected fields changed.
  AuditState copyWith({
    List<AuditEventModel>? events,
    AuditFilter? filter,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return AuditState(
      events: events ?? this.events,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
    );
  }
}
