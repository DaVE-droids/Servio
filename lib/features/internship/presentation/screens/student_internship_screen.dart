import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/place_directory.dart';
import '../../../../core/widgets/address_search_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/responsive_columns.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/internship_model.dart';
import '../../data/models/internship_submission_request.dart';
import '../../domain/internship_validator.dart';
import '../providers/internship_providers.dart';
import '../widgets/placement_journey_card.dart';

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

  List<GeoCountry> _countries = [];
  bool _countriesLoading = true;
  GeoCountry? _selectedCountry;

  List<String> _states = [];
  bool _statesLoading = false;
  String? _selectedState;

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
    final countries = await PlaceDirectory.countries();
    if (!mounted) {
      return;
    }
    GeoCountry? nigeria;
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
    final states = await PlaceDirectory.statesOf(countryIsoCode);
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
        if (internship != null) {
          return _SubmittedInternshipView(internship: internship);
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _StepHeader(isReviewing: _isReviewing),
                const SizedBox(height: AppSpacing.md),
                if (_isReviewing)
                  _buildReview(internshipState.isSubmitting)
                else
                  _buildForm(internshipState.isSubmitting),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Where you’ll work',
          subtitle:
              'Pick the address from the suggestions so your lecturer '
              'can find it on a map.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Company name',
                prefixIcon: Icons.apartment_outlined,
                textCapitalization: TextCapitalization.words,
                controller: _companyNameController,
                enabled: !isSubmitting,
                errorText: _errors['companyName'],
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<GeoCountry>(
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
              DropdownButtonFormField<String>(
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
                        child: Text(state, overflow: TextOverflow.ellipsis),
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
        SectionCard(
          title: 'Supervisor and dates',
          subtitle: 'The person at the company who oversees your work.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Supervisor’s name',
                prefixIcon: Icons.badge_outlined,
                textCapitalization: TextCapitalization.words,
                controller: _supervisorNameController,
                enabled: !isSubmitting,
                errorText: _errors['supervisorName'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Supervisor’s phone',
                prefixIcon: Icons.call_outlined,
                controller: _supervisorPhoneController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.phone,
                errorText: _errors['supervisorPhone'],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Start date',
                      value: _startDate,
                      errorText: _errors['dates'],
                      enabled: !isSubmitting,
                      onTap: () => _selectDate(isStartDate: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DatePickerField(
                      label: 'End date',
                      value: _endDate,
                      enabled: !isSubmitting,
                      onTap: () => _selectDate(isStartDate: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Review details',
          icon: Icons.arrow_forward_rounded,
          onPressed: _review,
        ),
      ],
    );
  }

  Widget _buildReview(bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Check everything is right',
          subtitle:
              'Your coordinator reviews these details before your '
              'internship can start.',
          child: InfoPanel(
            rows: [
              InfoRow(
                'Company',
                _companyNameController.text,
                icon: Icons.apartment_outlined,
              ),
              InfoRow(
                'Address',
                _companyAddressController.text,
                icon: Icons.place_outlined,
              ),
              InfoRow(
                'Location',
                [
                  _selectedState ?? '',
                  _selectedCountry?.name ?? '',
                ].where((part) => part.isNotEmpty).join(', '),
                icon: Icons.map_outlined,
              ),
              InfoRow(
                'Supervisor',
                _supervisorNameController.text,
                icon: Icons.badge_outlined,
              ),
              InfoRow(
                'Supervisor’s phone',
                _supervisorPhoneController.text,
                icon: Icons.call_outlined,
              ),
              InfoRow(
                'Dates',
                _startDate == null || _endDate == null
                    ? '—'
                    : Formatters.dateRange(
                        DateTime.utc(
                          _startDate!.year,
                          _startDate!.month,
                          _startDate!.day,
                        ),
                        DateTime.utc(
                          _endDate!.year,
                          _endDate!.month,
                          _endDate!.day,
                        ),
                      ),
                icon: Icons.date_range_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Submit for review',
          isLoading: isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Edit details',
          variant: AppButtonVariant.text,
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
            state: _selectedState!,
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
        ResponsiveColumns(
          primaryFlex: 7,
          secondaryFlex: 5,
          primary: [
            FadeSlideIn(child: PlacementJourneyCard(internship: internship)),
          ],
          secondary: [
            FadeSlideIn(
              index: 1,
              child: SectionCard(
                title: 'Placement details',
                child: InfoPanel(
                  rows: [
                    InfoRow(
                      'Address',
                      internship.companyAddress,
                      icon: Icons.place_outlined,
                    ),
                    InfoRow(
                      'Location',
                      [
                        internship.state,
                        internship.country,
                      ].where((part) => part.isNotEmpty).join(', '),
                      icon: Icons.map_outlined,
                    ),
                    InfoRow(
                      'Supervisor',
                      internship.companySupervisorName,
                      icon: Icons.badge_outlined,
                    ),
                    InfoRow(
                      'Supervisor’s phone',
                      internship.companySupervisorPhone,
                      icon: Icons.call_outlined,
                    ),
                    InfoRow(
                      'Lecturer',
                      internship.lecturerName ?? 'Not assigned yet',
                      icon: Icons.school_outlined,
                    ),
                    InfoRow(
                      'Submitted',
                      Formatters.date(internship.submittedAt),
                      icon: Icons.outbox_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// "Step 1 of 2" above the submission form, so students know how long it is.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.isReviewing});

  final bool isReviewing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STEP ${isReviewing ? 2 : 1} OF 2', style: textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          isReviewing ? 'Review your placement' : 'Submit your placement',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var step = 0; step < 2; step++) ...[
              if (step > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: step == 0 || isReviewing
                        ? AppColors.ink
                        : AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
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
    final picked = value;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          errorMaxLines: 2,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          picked == null
              ? 'Select'
              : Formatters.date(
                  DateTime.utc(picked.year, picked.month, picked.day),
                ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
