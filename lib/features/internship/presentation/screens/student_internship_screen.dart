import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/widgets/address_search_field.dart';
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
  final _supervisorNameController = TextEditingController();
  final _supervisorPhoneController = TextEditingController();
  final Map<String, String?> _errors = {};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isReviewing = false;

  List<csc.Country> _countries = [];
  bool _countriesLoading = true;
  csc.Country? _selectedCountry;

  List<csc.State> _states = [];
  bool _statesLoading = false;
  csc.State? _selectedState;

  AddressSuggestion? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _supervisorNameController.dispose();
    _supervisorPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final countries = await csc.getAllCountries();
    if (!mounted) {
      return;
    }
    csc.Country? nigeria;
    for (final country in countries) {
      if (country.isoCode == 'NG') {
        nigeria = country;
        break;
      }
    }
    setState(() {
      _countries = countries;
      _countriesLoading = false;
      _selectedCountry = nigeria;
    });
    if (nigeria != null) {
      _loadStates(nigeria.isoCode);
    }
  }

  Future<void> _loadStates(String countryIsoCode) async {
    setState(() {
      _statesLoading = true;
      _states = [];
      _selectedState = null;
    });
    final states = await csc.getStatesOfCountry(countryIsoCode);
    if (!mounted) {
      return;
    }
    setState(() {
      _states = states;
      _statesLoading = false;
    });
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
              DropdownButtonFormField<csc.Country>(
                initialValue: _selectedCountry,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Country',
                  errorText: _errors['country'],
                ),
                items: _countries
                    .map(
                      (country) => DropdownMenuItem(
                        value: country,
                        child: Text(
                          country.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isSubmitting || _countriesLoading
                    ? null
                    : (country) {
                        setState(() {
                          _selectedCountry = country;
                          _selectedAddress = null;
                        });
                        if (country != null) {
                          _loadStates(country.isoCode);
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<csc.State>(
                initialValue: _selectedState,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'State',
                  errorText: _errors['state'],
                  hintText: _statesLoading ? 'Loading states...' : null,
                ),
                items: _states
                    .map(
                      (state) => DropdownMenuItem(
                        value: state,
                        child: Text(state.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: isSubmitting || _statesLoading
                    ? null
                    : (state) => setState(() => _selectedState = state),
              ),
              const SizedBox(height: AppSpacing.sm),
              AddressSearchField(
                controller: _companyAddressController,
                enabled: !isSubmitting,
                errorText: _errors['companyAddress'],
                countryCode: _selectedCountry?.isoCode,
                onTextEdited: () => setState(() => _selectedAddress = null),
                onSelected: (suggestion) =>
                    setState(() => _selectedAddress = suggestion),
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
              _ReviewRow(
                label: 'Country',
                value: _selectedCountry?.name ?? '',
              ),
              _ReviewRow(label: 'State', value: _selectedState?.name ?? ''),
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

    final selectedAddress = _selectedAddress!;
    final submitted = await ref
        .read(internshipControllerProvider.notifier)
        .submit(
          InternshipSubmissionRequest(
            companyName: _companyNameController.text,
            companyAddress: _companyAddressController.text,
            companyLatitude: selectedAddress.latitude,
            companyLongitude: selectedAddress.longitude,
            companySupervisorName: _supervisorNameController.text,
            companySupervisorPhone: _supervisorPhoneController.text,
            country: _selectedCountry!.name,
            state: _selectedState!.name,
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
      'companyAddress': _selectedAddress == null
          ? 'Please select an address from the suggestions.'
          : null,
      'country': _selectedCountry == null ? 'Country is required.' : null,
      'state': _selectedState == null ? 'State is required.' : null,
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
              _ReviewRow(label: 'Country', value: internship.country),
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
