import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/audit_event_model.dart';
import '../controllers/audit_state.dart';
import '../providers/audit_providers.dart';

/// Coordinator-facing audit history (FR-AUDIT-004/005).
///
/// Renders the same `audit_events` documents the SRS calls the activity
/// log — chronological, grouped by day, in each event's own words —
/// while the filter sheet provides the accountability view.
class CoordinatorAuditScreen extends ConsumerWidget {
  /// Creates the audit history screen.
  const CoordinatorAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditValue = ref.watch(auditControllerProvider);

    return auditValue.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'The audit history couldn’t be loaded. Check your '
            'connection and try again.',
        onRetry: () => ref.read(auditControllerProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.errorMessage != null) {
          return AppErrorState(
            message: state.errorMessage!,
            onRetry: () => ref.read(auditControllerProvider.notifier).refresh(),
          );
        }
        if (state.events.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_rounded,
            title: 'No activity yet',
            message:
                'Placement decisions, lecturer assignments, logbook reviews, '
                'and supervision visits are recorded here as they happen.',
          );
        }

        final visible = state.visibleEvents;
        final groups = <String, List<AuditEventModel>>{};
        for (final event in visible) {
          groups
              .putIfAbsent(_dayLabel(event.createdAt.toLocal()), () => [])
              .add(event);
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(auditControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.filter.isActive
                          ? 'Showing ${visible.length} of ${state.events.length} events'
                          : 'Latest ${state.events.length} events. Records '
                                'can’t be edited or deleted.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (state.filter.isActive)
                    TextButton(
                      onPressed: () => ref
                          .read(auditControllerProvider.notifier)
                          .clearFilters(),
                      child: const Text('Clear'),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: () => _openFilters(context, ref, state),
                    icon: Icon(
                      state.filter.isActive
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                      size: 18,
                    ),
                    label: const Text('Filter'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (visible.isEmpty)
                AppEmptyState(
                  compact: true,
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No matching events',
                  message:
                      'Nothing in the loaded history matches these filters.',
                  actionLabel: 'Clear filters',
                  onActionPressed: () =>
                      ref.read(auditControllerProvider.notifier).clearFilters(),
                ),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    4,
                    AppSpacing.md,
                    4,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < entry.value.length; i++)
                        _AuditRow(
                          event: entry.value[i],
                          isLast: i == entry.value.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    WidgetRef ref,
    AuditState state,
  ) async {
    final updated = await showModalBottomSheet<AuditFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(state: state),
    );
    if (updated != null) {
      ref.read(auditControllerProvider.notifier).applyFilter(updated);
    }
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.event, required this.isLast});

  final AuditEventModel event;
  final bool isLast;

  /// The module an event belongs to, in Servio's module colours.
  static AppTone _toneFor(String entityType) => switch (entityType) {
    'attendance' => AppTone.sky,
    'logbook_entry' => AppTone.blush,
    'user' => AppTone.neutral,
    _ => AppTone.ink,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tone = _toneFor(event.entityType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                _timeLabel(event.createdAt.toLocal()),
                style: textTheme.labelMedium,
              ),
            ),
          ),
          // A thin timeline: a dot per event, joined within the day.
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm + 3),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tone.fill,
                    shape: BoxShape.circle,
                    border: Border.all(color: tone.foreground, width: 1.5),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 1.5, color: AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.description, style: textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${event.actorName} · ${humanizeAction(event.actorRole)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.state});

  final AuditState state;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late AuditFilter _filter = widget.state.filter;

  @override
  Widget build(BuildContext context) {
    final actors = widget.state.actors;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter the history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _Dropdown(
              label: 'User',
              value: _filter.actorId,
              options: {
                for (final entry in actors.entries) entry.key: entry.value,
              },
              onChanged: (value) => setState(() {
                _filter = value == null
                    ? _filter.copyWith(clearActorId: true)
                    : _filter.copyWith(actorId: value);
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Dropdown(
              label: 'Action',
              value: _filter.action,
              options: {
                for (final action in widget.state.actions)
                  action: humanizeAction(action),
              },
              onChanged: (value) => setState(() {
                _filter = value == null
                    ? _filter.copyWith(clearAction: true)
                    : _filter.copyWith(action: value);
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Dropdown(
              label: 'Entity',
              value: _filter.entityType,
              options: {
                for (final entity in widget.state.entityTypes)
                  entity: humanizeAction(entity),
              },
              onChanged: (value) => setState(() {
                _filter = value == null
                    ? _filter.copyWith(clearEntityType: true)
                    : _filter.copyWith(entityType: value);
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDateRange,
                    child: Text(
                      _filter.from == null || _filter.to == null
                          ? 'Any date'
                          : '${_dayLabel(_filter.from!)} — '
                                '${_dayLabel(_filter.to!)}',
                    ),
                  ),
                ),
                if (_filter.from != null)
                  IconButton(
                    tooltip: 'Clear dates',
                    onPressed: () => setState(
                      () => _filter = _filter.copyWith(clearDates: true),
                    ),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const AuditFilter()),
                  child: const Text('Clear all'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_filter),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filter.from != null && _filter.to != null
          ? DateTimeRange(start: _filter.from!, end: _filter.to!)
          : null,
    );
    if (range != null) {
      setState(
        () => _filter = _filter.copyWith(from: range.start, to: range.end),
      );
    }
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      // isExpanded stops a long name overflowing the row — the same
      // RenderFlex fix the coordinator assignment dropdown needed.
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(child: Text('Any')),
        for (final entry in options.entries)
          DropdownMenuItem<String?>(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Turns a stored snake_case action or entity type into something a
/// coordinator can read: `approved_placement` -> `Approved placement`.
String humanizeAction(String value) {
  if (value.isEmpty) {
    return value;
  }
  final words = value.split('_');
  final first = words.first;
  return [
    first[0].toUpperCase() + first.substring(1),
    ...words.skip(1),
  ].join(' ');
}

String _dayLabel(DateTime value) {
  final now = DateTime.now();
  final day = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  return Formatters.day(DateTime.utc(day.year, day.month, day.day));
}

String _timeLabel(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
