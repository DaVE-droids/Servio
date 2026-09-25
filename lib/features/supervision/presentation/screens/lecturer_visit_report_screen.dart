import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../lecturer/presentation/widgets/assigned_internship_builder.dart';
import '../../data/models/supervision_report_request.dart';
import '../../domain/supervision_validator.dart';
import '../providers/supervision_providers.dart';

/// Lecturer form for recording a supervision visit (FR-SUP-004).
class LecturerVisitReportScreen extends ConsumerWidget {
  /// Creates the visit report screen.
  const LecturerVisitReportScreen({required this.internshipId, super.key});

  /// The placement being visited, from the URL.
  final String internshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AssignedInternshipBuilder(
      internshipId: internshipId,
      builder: (context, internship) =>
          _VisitReportForm(internship: internship),
    );
  }
}

class _VisitReportForm extends ConsumerStatefulWidget {
  const _VisitReportForm({required this.internship});

  final InternshipModel internship;

  @override
  ConsumerState<_VisitReportForm> createState() => _VisitReportFormState();
}

class _VisitReportFormState extends ConsumerState<_VisitReportForm> {
  final _observationController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final Map<String, String?> _errors = {};
  // Most reports are written during or straight after the visit, so "now"
  // is the right starting point; the lecturer can change either.
  DateTime _visitDate = DateTime.now();
  TimeOfDay _visitTime = TimeOfDay.now();
  bool _studentPresent = true;
  bool _companyRepresentativePresent = true;
  int? _rating;

  static const _ratingWords = [
    'Poor',
    'Needs improvement',
    'Satisfactory',
    'Good',
    'Excellent',
  ];

  @override
  void dispose() {
    _observationController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(supervisionControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final internship = widget.internship;

    ref.listen(supervisionControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              child: Row(
                children: [
                  AppAvatar(name: internship.studentName, size: 48),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          internship.studentName,
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          '${internship.companyName} · ${internship.state}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'When',
              child: Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      label: 'Date',
                      icon: Icons.calendar_today_outlined,
                      value: Formatters.date(
                        DateTime.utc(
                          _visitDate.year,
                          _visitDate.month,
                          _visitDate.day,
                        ),
                      ),
                      errorText: _errors['visitDate'],
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PickerField(
                      label: 'Time',
                      icon: Icons.schedule_outlined,
                      value: _visitTime.format(context),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Who was there',
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilterChip(
                    avatar: Icon(
                      _studentPresent
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      size: 18,
                    ),
                    label: const Text('Student'),
                    selected: _studentPresent,
                    onSelected: (value) =>
                        setState(() => _studentPresent = value),
                  ),
                  FilterChip(
                    avatar: Icon(
                      _companyRepresentativePresent
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      size: 18,
                    ),
                    label: const Text('Company representative'),
                    selected: _companyRepresentativePresent,
                    onSelected: (value) =>
                        setState(() => _companyRepresentativePresent = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Findings',
              child: Column(
                children: [
                  AppTextField(
                    label: 'What did you observe?',
                    hintText:
                        'The student’s tasks, conduct, working conditions…',
                    controller: _observationController,
                    maxLines: 5,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    errorText: _errors['observation'],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Recommendations',
                    hintText: 'What should the student or company do next?',
                    controller: _recommendationsController,
                    maxLines: 5,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    errorText: _errors['recommendations'],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Overall rating',
              trailing: _rating == null
                  ? null
                  : Text(
                      _ratingWords[_rating! - 1],
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var rating = 1; rating <= 5; rating++)
                        IconButton(
                          tooltip:
                              'Rate $rating out of 5, '
                              '${_ratingWords[rating - 1].toLowerCase()}',
                          iconSize: 34,
                          onPressed: () => setState(() => _rating = rating),
                          icon: Icon(
                            _rating != null && rating <= _rating!
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: _rating != null && rating <= _rating!
                                ? AppColors.warning
                                : AppColors.lineStrong,
                          ),
                        ),
                    ],
                  ),
                  if (_errors['rating'] != null)
                    Text(
                      _errors['rating']!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Submit report',
              isLoading: formState.isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reports can’t be edited after they’re submitted, so they stay '
              'a reliable record of the visit.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDate: _visitDate,
    );
    if (selected != null) {
      setState(() => _visitDate = selected);
    }
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _visitTime,
    );
    if (selected != null) {
      setState(() => _visitTime = selected);
    }
  }

  Future<void> _submit() async {
    final visitDateTime = DateTime(
      _visitDate.year,
      _visitDate.month,
      _visitDate.day,
      _visitTime.hour,
      _visitTime.minute,
    );
    final errors = {
      'visitDate': SupervisionValidator.visitDate(visitDateTime),
      'observation': SupervisionValidator.requiredText(
        _observationController.text,
        'Observation',
      ),
      'recommendations': SupervisionValidator.requiredText(
        _recommendationsController.text,
        'Recommendations',
      ),
      'rating': SupervisionValidator.rating(_rating),
    };
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.values.any((message) => message != null)) {
      return;
    }

    final internship = widget.internship;
    final report = await ref
        .read(supervisionControllerProvider.notifier)
        .submit(
          internship: internship,
          studentName: internship.studentName,
          studentMatricNumber: internship.studentMatricNumber,
          request: SupervisionReportRequest(
            internshipId: internship.internshipId,
            visitDate: visitDateTime,
            studentPresent: _studentPresent,
            companyRepresentativePresent: _companyRepresentativePresent,
            observation: _observationController.text,
            recommendations: _recommendationsController.text,
            rating: _rating!,
          ),
        );
    if (report != null && mounted) {
      context.pop();
    }
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: Icon(icon, size: 20),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
