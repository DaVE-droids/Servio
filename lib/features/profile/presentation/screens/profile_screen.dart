import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/profile_photo_upload_request.dart';
import '../../data/models/profile_update_request.dart';
import '../../data/models/user_model.dart';
import '../../domain/profile_validator.dart';
import '../providers/profile_providers.dart';

/// Screen for viewing and editing the signed-in user's profile.
class ProfileScreen extends ConsumerStatefulWidget {
  /// Creates a profile screen.
  const ProfileScreen({this.showScaffold = true, super.key});

  /// Whether the screen should provide its own scaffold and app bar.
  final bool showScaffold;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facultyController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Map<String, String?> _errors = {};
  String? _loadedUid;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileValue = ref.watch(profileControllerProvider);

    ref.listen(profileControllerProvider, (previous, next) {
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

    final content = profileValue.when(
      loading: () => const AppLoading(message: 'Loading profile...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load your profile. Please try again.',
        onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
      ),
      data: (profileState) {
        final user = profileState.user;
        if (user == null) {
          return AppEmptyState(
            title: 'Profile unavailable',
            message:
                profileState.errorMessage ??
                'Your profile could not be loaded.',
            actionLabel: 'Retry',
            onActionPressed: () =>
                ref.read(profileControllerProvider.notifier).refresh(),
          );
        }

        _syncControllers(user);
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ProfileHeader(
                user: user,
                isUploadingPhoto: profileState.isUploadingPhoto,
                onUploadPhoto: _uploadPhoto,
                onRemovePhoto: _removePhoto,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(child: _buildEditableFields(profileState.isSaving)),
              const SizedBox(height: AppSpacing.md),
              AppCard(child: _buildReadOnlyFields(user)),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Save Changes',
                isLoading: profileState.isSaving,
                onPressed: () => _save(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
    if (!widget.showScaffold) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: content,
    );
  }

  Widget _buildEditableFields(bool isSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Editable Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'First Name',
          controller: _firstNameController,
          enabled: !isSaving,
          errorText: _errors['firstName'],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Last Name',
          controller: _lastNameController,
          enabled: !isSaving,
          errorText: _errors['lastName'],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Phone Number',
          controller: _phoneController,
          enabled: !isSaving,
          keyboardType: TextInputType.phone,
          errorText: _errors['phoneNumber'],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Faculty',
          controller: _facultyController,
          enabled: !isSaving,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Profile Photo URL',
          controller: _photoUrlController,
          enabled: !isSaving,
          keyboardType: TextInputType.url,
          errorText: _errors['profilePhotoUrl'],
        ),
      ],
    );
  }

  Widget _buildReadOnlyFields(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Account Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _ReadOnlyProfileField(label: 'Email', value: user.email),
        const SizedBox(height: AppSpacing.sm),
        _ReadOnlyProfileField(label: 'Role', value: user.role.name),
        const SizedBox(height: AppSpacing.sm),
        _ReadOnlyProfileField(label: 'Department', value: user.department),
        if (user.matricNumber != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ReadOnlyProfileField(
            label: 'Matric Number',
            value: user.matricNumber!,
          ),
        ],
        if (user.staffId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ReadOnlyProfileField(label: 'Staff ID', value: user.staffId!),
        ],
        const SizedBox(height: AppSpacing.sm),
        _ReadOnlyProfileField(
          label: 'Account Status',
          value: user.isActive ? 'Active' : 'Inactive',
        ),
      ],
    );
  }

  void _syncControllers(UserModel user) {
    if (_loadedUid == user.uid) {
      return;
    }
    _loadedUid = user.uid;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phoneNumber ?? '';
    _facultyController.text = user.faculty ?? '';
    _photoUrlController.text = user.profilePhotoUrl ?? '';
  }

  Future<void> _save() async {
    final errors = {
      'firstName': ProfileValidator.name(
        _firstNameController.text,
        'First name',
      ),
      'lastName': ProfileValidator.name(_lastNameController.text, 'Last name'),
      'phoneNumber': ProfileValidator.phoneNumber(_phoneController.text),
      'profilePhotoUrl': ProfileValidator.profilePhotoUrl(
        _photoUrlController.text,
      ),
    };
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.values.any((message) => message != null)) {
      return;
    }

    final saved = await ref
        .read(profileControllerProvider.notifier)
        .save(
          ProfileUpdateRequest(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            phoneNumber: _phoneController.text,
            faculty: _facultyController.text,
            profilePhotoUrl: _photoUrlController.text,
          ),
        );
    if (saved) {
      setState(_errors.clear);
    }
  }

  Future<void> _uploadPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final contentType = image.mimeType ?? _guessContentType(image.name);
    await ref
        .read(profileControllerProvider.notifier)
        .uploadProfilePhoto(
          ProfilePhotoUploadRequest(bytes: bytes, contentType: contentType),
        );
  }

  Future<void> _removePhoto() async {
    _photoUrlController.clear();
    await _save();
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  const _ReadOnlyProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isUploadingPhoto,
    required this.onUploadPhoto,
    required this.onRemovePhoto,
  });

  final UserModel user;
  final bool isUploadingPhoto;
  final VoidCallback onUploadPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.profilePhotoUrl;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: photoUrl == null || photoUrl.isEmpty
                ? null
                : NetworkImage(photoUrl),
            child: photoUrl == null || photoUrl.isEmpty
                ? Text(user.firstName.characters.first.toUpperCase())
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    SizedBox(
                      width: 160,
                      child: AppButton(
                        label: 'Upload Photo',
                        variant: AppButtonVariant.secondary,
                        isLoading: isUploadingPhoto,
                        onPressed: onUploadPhoto,
                      ),
                    ),
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      SizedBox(
                        width: 160,
                        child: AppButton(
                          label: 'Remove Photo',
                          variant: AppButtonVariant.text,
                          onPressed: onRemovePhoto,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _guessContentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}
