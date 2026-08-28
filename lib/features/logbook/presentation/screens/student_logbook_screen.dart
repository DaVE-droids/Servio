import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/enums/logbook_status.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../data/models/logbook_entry_model.dart';
import '../controllers/logbook_state.dart';
import '../providers/logbook_providers.dart';

/// Student screen for today's logbook entry and recent history.
class StudentLogbookScreen extends ConsumerWidget {
  /// Creates the student logbook screen.
  const StudentLogbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipValue = ref.watch(internshipControllerProvider);
    final logbookValue = ref.watch(logbookControllerProvider);

    ref.listen(logbookControllerProvider, (previous, next) {
      final state = switch (next) {
        AsyncData(:final value) => value,
        _ => null,
      };
      final message = state?.errorMessage ?? state?.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return internshipValue.when(
      loading: () => const AppLoading(message: 'Loading logbook...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load your internship. Please try again.',
        onRetry: () => ref.read(internshipControllerProvider.notifier).refresh(),
      ),
      data: (internshipState) {
        final internship = internshipState.currentInternship;
        if (internship == null || internship.status != InternshipStatus.active) {
          return const AppEmptyState(
            title: 'Logbook Unavailable',
            message:
                'Your digital logbook will be available once your internship is active.',
          );
        }

        return logbookValue.when(
          loading: () => const AppLoading(message: 'Loading logbook...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Unable to load your logbook. Please try again.',
            onRetry: () =>
                ref.read(logbookControllerProvider.notifier).refresh(),
          ),
          data: (state) => _LogbookBody(state: state),
        );
      },
    );
  }
}

class _LogbookBody extends ConsumerStatefulWidget {
  const _LogbookBody({required this.state});

  final LogbookState state;

  @override
  ConsumerState<_LogbookBody> createState() => _LogbookBodyState();
}

class _LogbookBodyState extends ConsumerState<_LogbookBody> {
  final _activitiesController = TextEditingController();
  final _skillsController = TextEditingController();
  final _challengesController = TextEditingController();
  final _solutionsController = TextEditingController();
  final _hoursController = TextEditingController();
  final Map<String, String?> _errors = {};
  String? _prefilledForEntryId;

  @override
  void initState() {
    super.initState();
    _prefillIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LogbookBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prefillIfNeeded();
  }

  void _prefillIfNeeded() {
    final today = widget.state.today;
    if (today == null || today.status == LogbookStatus.approved) {
      return;
    }
    if (_prefilledForEntryId == today.entryId) {
      return;
    }
    _prefilledForEntryId = today.entryId;
    _activitiesController.text = today.activities;
    _skillsController.text = today.skillsLearned;
    _challengesController.text = today.challenges;
    _solutionsController.text = today.solutionsApplied;
    _hoursController.text = today.hoursWorked.toString();
  }

  @override
  void dispose() {
    _activitiesController.dispose();
    _skillsController.dispose();
    _challengesController.dispose();
    _solutionsController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.state.today;
    final isLocked = today?.status == LogbookStatus.approved;

    return RefreshIndicator(
      onRefresh: () => ref.read(logbookControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text("Today's Entry", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          if (isLocked)
            _ApprovedEntryCard(entry: today!)
          else
            _EntryForm(
              entry: today,
              activitiesController: _activitiesController,
              skillsController: _skillsController,
              challengesController: _challengesController,
              solutionsController: _solutionsController,
              hoursController: _hoursController,
              errors: _errors,
              isSubmitting: widget.state.isSubmitting,
              onSubmit: _submit,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recent Entries', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (widget.state.history.isEmpty)
            const AppEmptyState(
              title: 'No Entries Yet',
              message: 'Your submitted logbook entries will appear here.',
            )
          else
            for (final entry in widget.state.history) ...[
              _HistoryCard(entry: entry),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  void _submit() {
    final hours = num.tryParse(_hoursController.text.trim());
    final errors = {
      'activities': _requiredText(_activitiesController.text, 'Activities'),
      'skillsLearned': _requiredText(_skillsController.text, 'Skills learned'),
      'challenges': _requiredText(_challengesController.text, 'Challenges'),
      'solutionsApplied': _requiredText(
        _solutionsController.text,
        'Solutions applied',
      ),
      'hoursWorked': hours == null || hours <= 0
          ? 'Enter a valid number of hours.'
          : null,
    };
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.values.any((message) => message != null)) {
      return;
    }

    ref
        .read(logbookControllerProvider.notifier)
        .submit(
          activities: _activitiesController.text.trim(),
          skillsLearned: _skillsController.text.trim(),
          challenges: _challengesController.text.trim(),
          solutionsApplied: _solutionsController.text.trim(),
          hoursWorked: hours!,
        );
  }

  String? _requiredText(String value, String label) {
    return value.trim().isEmpty ? '$label is required.' : null;
  }
}

class _EntryForm extends StatelessWidget {
  const _EntryForm({
    required this.entry,
    required this.activitiesController,
    required this.skillsController,
    required this.challengesController,
    required this.solutionsController,
    required this.hoursController,
    required this.errors,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final LogbookEntryModel? entry;
  final TextEditingController activitiesController;
  final TextEditingController skillsController;
  final TextEditingController challengesController;
  final TextEditingController solutionsController;
  final TextEditingController hoursController;
  final Map<String, String?> errors;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isResubmission = entry?.status == LogbookStatus.changesRequested;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isResubmission && entry?.lecturerComments?.isNotEmpty == true) ...[
            const AppStatusChip(
              label: 'Changes Requested',
              type: AppStatusChipType.warning,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Lecturer comments: ${entry!.lecturerComments}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppTextField(
            label: 'Activities Performed',
            controller: activitiesController,
            maxLines: 3,
            enabled: !isSubmitting,
            errorText: errors['activities'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Skills Learned',
            controller: skillsController,
            maxLines: 2,
            enabled: !isSubmitting,
            errorText: errors['skillsLearned'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Challenges Encountered',
            controller: challengesController,
            maxLines: 2,
            enabled: !isSubmitting,
            errorText: errors['challenges'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Solutions Applied',
            controller: solutionsController,
            maxLines: 2,
            enabled: !isSubmitting,
            errorText: errors['solutionsApplied'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Hours Worked',
            controller: hoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !isSubmitting,
            errorText: errors['hoursWorked'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: entry == null ? 'Submit Entry' : 'Update Entry',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ApprovedEntryCard extends StatelessWidget {
  const _ApprovedEntryCard({required this.entry});

  final LogbookEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppStatusChip(label: 'Approved', type: AppStatusChipType.success),
          const SizedBox(height: AppSpacing.xs),
          Text('Activities: ${entry.activities}', style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text('Hours worked: ${entry.hoursWorked}', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final LogbookEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_formatDate(entry.date), style: textTheme.titleMedium),
              ),
              AppStatusChip(
                label: entry.status.label,
                type: switch (entry.status) {
                  LogbookStatus.approved => AppStatusChipType.success,
                  LogbookStatus.pending => AppStatusChipType.info,
                  LogbookStatus.changesRequested => AppStatusChipType.warning,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(entry.activities, style: textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
