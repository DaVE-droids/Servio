import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/enums/logbook_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/responsive_columns.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../data/models/logbook_entry_model.dart';
import '../controllers/logbook_state.dart';
import '../providers/logbook_providers.dart';

/// Student logbook: today's entry (editable until reviewed) and the recent
/// entries with how each was reviewed.
class StudentLogbookScreen extends ConsumerWidget {
  /// Creates the student logbook screen.
  const StudentLogbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipValue = ref.watch(internshipControllerProvider);
    final logbookValue = ref.watch(logbookControllerProvider);

    ref.listen(logbookControllerProvider, (previous, next) {
      final state = next.value;
      final message = state?.errorMessage ?? state?.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return internshipValue.when(
      loading: () => const AppLoading(layout: AppLoadingLayout.detail),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Your placement couldn’t be loaded. Check your connection '
            'and try again.',
        onRetry: () =>
            ref.read(internshipControllerProvider.notifier).refresh(),
      ),
      data: (internshipState) {
        final internship = internshipState.currentInternship;
        if (internship?.status == InternshipStatus.completed) {
          return const AppEmptyState(
            icon: Icons.verified_outlined,
            tone: AppTone.success,
            title: 'Internship completed',
            message:
                'Your logbook is closed to new entries now that your '
                'internship is over. Your entries are kept.',
          );
        }
        if (internship == null ||
            internship.status != InternshipStatus.active) {
          return const AppEmptyState(
            icon: Icons.menu_book_outlined,
            tone: AppTone.blush,
            title: 'Your logbook opens when your internship starts',
            message:
                'You’ll write one entry for each working day, and your '
                'lecturer reviews them here.',
          );
        }

        return logbookValue.when(
          loading: () => const AppLoading(layout: AppLoadingLayout.detail),
          error: (error, stackTrace) => AppErrorState(
            message:
                'Your logbook couldn’t be loaded. Check your connection '
                'and try again.',
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

  /// Loads today's saved entry into the form once, so edits in progress
  /// aren't overwritten when the screen rebuilds.
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
    final history = widget.state.history
        .where((entry) => entry.entryId != today?.entryId)
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(logbookControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ResponsiveColumns(
            breakpoint: 980,
            primaryFlex: 7,
            secondaryFlex: 5,
            primary: [
              FadeSlideIn(
                child: isLocked
                    ? _EntryDetailCard(entry: today!, title: 'Today’s entry')
                    : _EntryForm(
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
              ),
            ],
            secondary: [
              FadeSlideIn(
                index: 1,
                child: SectionCard(
                  title: 'Earlier entries',
                  child: history.isEmpty
                      ? const AppEmptyState(
                          compact: true,
                          icon: Icons.auto_stories_outlined,
                          tone: AppTone.blush,
                          title: 'No earlier entries',
                          message:
                              'Entries from previous days, and how they were '
                              'reviewed, appear here.',
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < history.length; i++) ...[
                              if (i > 0) const Divider(),
                              _HistoryTile(entry: history[i]),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _submit() {
    final hours = num.tryParse(_hoursController.text.trim());
    String? required(TextEditingController controller, String message) =>
        controller.text.trim().isEmpty ? message : null;
    final errors = {
      'activities': required(
        _activitiesController,
        'Describe what you worked on today.',
      ),
      'skillsLearned': required(_skillsController, 'Add what you learned.'),
      'challenges': required(
        _challengesController,
        'Add any challenges, or write “None”.',
      ),
      'solutionsApplied': required(
        _solutionsController,
        'Add how you handled them, or write “None”.',
      ),
      'hoursWorked': hours == null || hours <= 0 || hours > 24
          ? 'Enter the hours you worked today, between 0.5 and 24.'
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

    FocusScope.of(context).unfocus();
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
    final textTheme = Theme.of(context).textTheme;
    final changesRequested = entry?.status == LogbookStatus.changesRequested;
    final comments = entry?.lecturerComments;

    return SectionCard(
      title: entry == null ? 'Today’s entry' : 'Edit today’s entry',
      subtitle: Formatters.day(Formatters.todayUtc()),
      trailing: entry == null
          ? null
          : AppStatusChip(
              label: changesRequested
                  ? 'Changes requested'
                  : 'Waiting for review',
              tone: changesRequested ? AppTone.warning : AppTone.blush,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (changesRequested && comments != null && comments.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry!.lecturerName.isEmpty ? 'Your lecturer' : entry!.lecturerName} asked for changes',
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(comments, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            label: 'What did you work on today?',
            controller: activitiesController,
            maxLines: 5,
            minLines: 3,
            enabled: !isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            errorText: errors['activities'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'What did you learn?',
            controller: skillsController,
            maxLines: 4,
            minLines: 2,
            enabled: !isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            errorText: errors['skillsLearned'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Any challenges?',
            controller: challengesController,
            maxLines: 4,
            minLines: 2,
            enabled: !isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            errorText: errors['challenges'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'How did you handle them?',
            controller: solutionsController,
            maxLines: 4,
            minLines: 2,
            enabled: !isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            errorText: errors['solutionsApplied'],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 200,
            child: AppTextField(
              label: 'Hours worked',
              controller: hoursController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !isSubmitting,
              prefixIcon: Icons.schedule_outlined,
              errorText: errors['hoursWorked'],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: entry == null ? 'Submit entry' : 'Save changes',
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
          if (entry == null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You can edit this entry until your lecturer reviews it.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// A read-only entry, shown once it's approved and can't change.
class _EntryDetailCard extends StatelessWidget {
  const _EntryDetailCard({required this.entry, required this.title});

  final LogbookEntryModel entry;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: Formatters.day(entry.date),
      trailing: const AppStatusChip(
        label: 'Approved',
        type: AppStatusChipType.success,
      ),
      child: _EntryFields(entry: entry),
    );
  }
}

class _EntryFields extends StatelessWidget {
  const _EntryFields({required this.entry});

  final LogbookEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget field(String label, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(text.trim().isEmpty ? '—' : text, style: textTheme.bodyMedium),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field('Activities', entry.activities),
        field('Learned', entry.skillsLearned),
        field('Challenges', entry.challenges),
        field('Handled by', entry.solutionsApplied),
        field('Hours', '${entry.hoursWorked}'),
        if ((entry.lecturerComments ?? '').isNotEmpty)
          field('Lecturer’s note', entry.lecturerComments!),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final LogbookEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, tone) = switch (entry.status) {
      LogbookStatus.approved => ('Approved', AppTone.success),
      LogbookStatus.pending => ('Waiting', AppTone.blush),
      LogbookStatus.changesRequested => ('Changes requested', AppTone.warning),
    };
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        title: Text(Formatters.day(entry.date), style: textTheme.titleSmall),
        subtitle: Text(
          entry.activities,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
        trailing: AppStatusChip(label: label, tone: tone),
        children: [_EntryFields(entry: entry)],
      ),
    );
  }
}
