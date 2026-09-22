import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit History'),
        actions: [
          auditValue.maybeWhen(
            data: (state) => IconButton(
              tooltip: 'Filter',
              onPressed: () => _openFilters(context, ref, state),
              icon: Icon(
                state.filter.isActive
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: auditValue.when(
        loading: () => const AppLoading(message: 'Loading audit history...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load audit history. Please try again.',
          onRetry: () => ref.read(auditControllerProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.errorMessage != null) {
            return AppErrorState(
              message: state.errorMessage!,
              onRetry: () =>
                  ref.read(auditControllerProvider.notifier).refresh(),
            );
          }
          if (state.events.isEmpty) {
            return const AppEmptyState(
              title: 'No Activity Yet',
              message:
                  'Placement approvals, lecturer assignments, logbook '
                  'reviews, and supervision visits will be recorded here.',
            );
          }

          final visible = state.visibleEvents;
          if (visible.isEmpty) {
            return AppEmptyState(
              title: 'No Matching Events',
              message:
                  'No audit events match the current filters. '
                  '${state.events.length} events are loaded.',
              actionLabel: 'Clear filters',
              onActionPressed: () =>
                  ref.read(auditControllerProvider.notifier).clearFilters(),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(auditControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (state.filter.isActive)
                  _FilterSummary(
                    shown: visible.length,
                    total: state.events.length,
                    onClear: () =>
                        ref.read(auditControllerProvider.notifier).clearFilters(),
                  ),
                ..._buildGroupedRows(context, visible),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Flattens the events into day headings followed by their rows, which
  /// is what turns a raw audit list into the readable timeline the SRS
  /// describes.
  List<Widget> _buildGroupedRows(
    BuildContext context,
    List<AuditEventModel> events,
  ) {
    final rows = <Widget>[];
    String? currentDay;

    for (final event in events) {
      final day = _dayLabel(event.createdAt.toLocal());
      if (day != currentDay) {
        currentDay = day;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              day,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      rows.add(_AuditRow(event: event));
    }
    return rows;
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

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({
    required this.shown,
    required this.total,
    required this.onClear,
  });

  final int shown;
  final int total;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $shown of $total events',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('Clear filters')),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.event});

  final AuditEventModel event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              _timeLabel(event.createdAt.toLocal()),
              style: textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.description, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${event.actorName} · ${event.actorRole}',
                  style: textTheme.bodySmall,
                ),
              ],
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
              'Filter Audit History',
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
                    onPressed: () =>
                        setState(() => _filter = _filter.copyWith(clearDates: true)),
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
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

String _timeLabel(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
