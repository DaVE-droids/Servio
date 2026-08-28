import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/internship_model.dart';
import '../../data/models/internship_submission_request.dart';
import '../../domain/internship_validator.dart';
import '../providers/internship_providers.dart';

/// Student screen for viewing or submitting internship placement details.
class StudentInternshipScreen extends ConsumerStatefulWidget {
  /// Creates the student internship screen.
  const StudentInternshipScreen({super.key});

  @override
  ConsumerState<StudentInternshipScreen> createState() =>
      _StudentInternshipScreenState();
}

class _StudentInternshipScreenState
    extends ConsumerState<StudentInternshipScreen> {
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _supervisorNameController = TextEditingController();
  final _supervisorPhoneController = TextEditingController();
  final _stateController = TextEditingController();
  final Map<String, String?> _errors = {};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isReviewing = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _supervisorNameController.dispose();
    _supervisorPhoneController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final internshipValue = ref.watch(internshipControllerProvider);

    ref.listen(internshipControllerProvider, (previous, next) {
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
      loading: () => const AppLoading(message: 'Loading placement...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load your internship placement. Please try again.',
        onRetry: () =>
            ref.read(internshipControllerProvider.notifier).refresh(),
      ),
      data: (internshipState) {
        final internship = internshipState.currentInternship;
        if (internship != null) {
          return _SubmittedInternshipView(internship: internship);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              _isReviewing ? 'Review Placement' : 'Submit Placement',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              _isReviewing
                  ? 'Confirm the details below before submitting for coordinator review.'
                  : 'Enter the company and internship details for your field placement.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isReviewing)
              _buildReview(internshipState.isSubmitting)
            else
              _buildForm(internshipState.isSubmitting),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  Widget _buildForm(bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Company Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Company Name',
                controller: _companyNameController,
                enabled: !isSubmitting,
                errorText: _errors['companyName'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Company Address',
                controller: _companyAddressController,
                enabled: !isSubmitting,
                maxLines: 3,
                errorText: _errors['companyAddress'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'State',
                controller: _stateController,
                enabled: !isSubmitting,
                errorText: _errors['state'],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      controller: _latitudeController,
                      enabled: !isSubmitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      errorText: _errors['latitude'],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      controller: _longitudeController,
                      enabled: !isSubmitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      errorText: _errors['longitude'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Internship Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Company Supervisor Name',
                controller: _supervisorNameController,
                enabled: !isSubmitting,
                errorText: _errors['supervisorName'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Company Supervisor Phone',
                controller: _supervisorPhoneController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.phone,
                errorText: _errors['supervisorPhone'],
              ),
              const SizedBox(height: AppSpacing.sm),
              _DatePickerField(
                label: 'Start Date',
                value: _startDate,
                errorText: _errors['dates'],
                enabled: !isSubmitting,
                onTap: () => _selectDate(isStartDate: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DatePickerField(
                label: 'End Date',
                value: _endDate,
                enabled: !isSubmitting,
                onTap: () => _selectDate(isStartDate: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Review Placement', onPressed: _review),
      ],
    );
  }

  Widget _buildReview(bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              _ReviewRow(label: 'Company', value: _companyNameController.text),
              _ReviewRow(
                label: 'Address',
                value: _companyAddressController.text,
              ),
              _ReviewRow(label: 'State', value: _stateController.text),
              _ReviewRow(
                label: 'Coordinates',
                value:
                    '${_latitudeController.text.trim()}, ${_longitudeController.text.trim()}',
              ),
              _ReviewRow(
                label: 'Supervisor',
                value: _supervisorNameController.text,
              ),
              _ReviewRow(
                label: 'Supervisor Phone',
                value: _supervisorPhoneController.text,
              ),
              _ReviewRow(label: 'Start Date', value: _formatDate(_startDate)),
              _ReviewRow(label: 'End Date', value: _formatDate(_endDate)),
              const _ReviewRow(
                label: 'Initial Status',
                value: 'Pending Review',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Submit Placement',
          isLoading: isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Edit Details',
          variant: AppButtonVariant.secondary,
          onPressed: isSubmitting
              ? null
              : () => setState(() => _isReviewing = false),
        ),
      ],
    );
  }

  void _review() {
    if (!_validate()) {
      return;
    }
    setState(() => _isReviewing = true);
  }

  Future<void> _submit() async {
    if (!_validate()) {
      setState(() => _isReviewing = false);
      return;
    }

    final submitted = await ref
        .read(internshipControllerProvider.notifier)
        .submit(
          InternshipSubmissionRequest(
            companyName: _companyNameController.text,
            companyAddress: _companyAddressController.text,
            companyLatitude: double.parse(_latitudeController.text.trim()),
            companyLongitude: double.parse(_longitudeController.text.trim()),
            companySupervisorName: _supervisorNameController.text,
            companySupervisorPhone: _supervisorPhoneController.text,
            state: _stateController.text,
            startDate: _startDate!,
            endDate: _endDate!,
          ),
        );
    if (submitted && mounted) {
      context.go(AppRoutes.studentDashboard);
    }
  }

  bool _validate() {
    final errors = {
      'companyName': InternshipValidator.requiredText(
        _companyNameController.text,
        'Company name',
      ),
      'companyAddress': InternshipValidator.requiredText(
        _companyAddressController.text,
        'Company address',
      ),
      'state': InternshipValidator.requiredText(_stateController.text, 'State'),
      'latitude': InternshipValidator.latitude(_latitudeController.text),
      'longitude': InternshipValidator.longitude(_longitudeController.text),
      'supervisorName': InternshipValidator.requiredText(
        _supervisorNameController.text,
        'Company supervisor name',
      ),
      'supervisorPhone': InternshipValidator.phoneNumber(
        _supervisorPhoneController.text,
      ),
      'dates': InternshipValidator.dates(
        startDate: _startDate,
        endDate: _endDate,
      ),
    };
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    return !errors.values.any((message) => message != null);
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: isStartDate
          ? _startDate ?? now
          : _endDate ?? _startDate ?? now,
    );
    if (selected == null) {
      return;
    }
    setState(() {
      if (isStartDate) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }
    });
  }
}

class _SubmittedInternshipView extends StatelessWidget {
  const _SubmittedInternshipView({required this.internship});

  final InternshipModel internship;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Current Internship',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                internship.companyName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(internship.companyAddress),
              const SizedBox(height: AppSpacing.sm),
              _ReviewRow(label: 'Status', value: internship.status.label),
              _ReviewRow(label: 'State', value: internship.state),
              _ReviewRow(
                label: 'Supervisor',
                value: internship.companySupervisorName,
              ),
              _ReviewRow(
                label: 'Start Date',
                value: _formatDate(internship.startDate),
              ),
              _ReviewRow(
                label: 'End Date',
                value: _formatDate(internship.endDate),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: errorText),
        child: Text(value == null ? 'Select date' : _formatDate(value)),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 136,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return 'Not selected';
  }
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
