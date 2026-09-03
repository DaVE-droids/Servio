import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/supervision_validator.dart';
import '../../data/models/supervision_report_request.dart';
import '../providers/supervision_providers.dart';

/// Lecturer screen for submitting a supervision visit report (FR-SUP-004).
class LecturerVisitReportScreen extends ConsumerStatefulWidget {
  /// Creates the lecturer visit report screen.
  const LecturerVisitReportScreen({
    required this.internship,
    required this.student,
    super.key,
  });

  /// The internship being visited.
  final InternshipModel internship;

  /// The student being visited.
  final UserModel student;

  @override
  ConsumerState<LecturerVisitReportScreen> createState() =>
      _LecturerVisitReportScreenState();
}

class _LecturerVisitReportScreenState
    extends ConsumerState<LecturerVisitReportScreen> {
  final _observationController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final Map<String, String?> _errors = {};
  DateTime? _visitDate;
  TimeOfDay? _visitTime;
  bool _studentPresent = true;
  bool _companyRepresentativePresent = true;
  int? _rating;

  @override
  void dispose() {
    _observationController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(supervisionControllerProvider);

    ref.listen(supervisionControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Visit Report')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Visit Report for ${widget.student.firstName} ${widget.student.lastName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            widget.internship.companyName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DatePickerField(
                  label: 'Visit Date',
                  value: _visitDate,
                  errorText: _errors['visitDate'],
                  onTap: _selectDate,
                ),
                const SizedBox(height: AppSpacing.sm),
                _TimePickerField(
                  label: 'Visit Time',
                  value: _visitTime,
                  onTap: _selectTime,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Student Present'),
                  value: _studentPresent,
                  onChanged: (value) =>
                      setState(() => _studentPresent = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Company Representative Present'),
                  value: _companyRepresentativePresent,
                  onChanged: (value) =>
                      setState(() => _companyRepresentativePresent = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'General Observation',
                  controller: _observationController,
                  maxLines: 4,
                  errorText: _errors['observation'],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Recommendations',
                  controller: _recommendationsController,
                  maxLines: 4,
                  errorText: _errors['recommendations'],
                ),
                const SizedBox(height: AppSpacing.sm),
                _RatingSelector(
                  value: _rating,
                  errorText: _errors['rating'],
                  onChanged: (value) => setState(() => _rating = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Submit Report',
            isLoading: formState.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDate: _visitDate ?? now,
    );
    if (selected != null) {
      setState(() => _visitDate = selected);
    }
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _visitTime ?? TimeOfDay.now(),
    );
    if (selected != null) {
      setState(() => _visitTime = selected);
    }
  }

  Future<void> _submit() async {
    final visitDateTime = _combinedVisitDateTime();
    final errors = {
      'visitDate': SupervisionValidator.visitDate(visitDateTime),
      'observation': SupervisionValidator.requiredText(
        _observationController.text,
        'General observation',
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

    final report = await ref
        .read(supervisionControllerProvider.notifier)
        .submit(
          internship: widget.internship,
          studentName: '${widget.student.firstName} ${widget.student.lastName}',
          studentMatricNumber: widget.student.matricNumber ?? '',
          request: SupervisionReportRequest(
            internshipId: widget.internship.internshipId,
            visitDate: visitDateTime!,
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

  DateTime? _combinedVisitDateTime() {
    if (_visitDate == null) {
      return null;
    }
    final time = _visitTime ?? TimeOfDay.now();
    return DateTime(
      _visitDate!.year,
      _visitDate!.month,
      _visitDate!.day,
      time.hour,
      time.minute,
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: errorText),
        child: Text(value == null ? 'Select date' : _formatDate(value!)),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value == null ? 'Select time' : value!.format(context)),
      ),
    );
  }
}

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Overall Rating',
        errorText: errorText,
      ),
      child: Row(
        children: List.generate(5, (index) {
          final rating = index + 1;
          return Expanded(
            child: IconButton(
              onPressed: () => onChanged(rating),
              icon: Icon(
                value != null && rating <= value!
                    ? Icons.star
                    : Icons.star_border,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
