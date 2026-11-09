import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/responsive_columns.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../authentication/presentation/widgets/delete_account_dialog.dart';
import '../../data/models/profile_photo_upload_request.dart';
import '../../data/models/profile_update_request.dart';
import '../../data/models/user_model.dart';
import '../../domain/profile_validator.dart';
import '../providers/profile_providers.dart';

/// The signed-in user's profile: photo, editable details, account facts,
/// legal links, and account actions (sign out, delete account).
class ProfileScreen extends ConsumerStatefulWidget {
  /// Creates a profile screen.
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facultyController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Map<String, String?> _errors = {};
  String? _loadedUid;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileValue = ref.watch(profileControllerProvider);
    final isSigningOut = ref.watch(authenticationControllerProvider).isLoading;

    ref.listen(profileControllerProvider, (previous, next) {
      final state = next.value;
      final message = state?.errorMessage ?? state?.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return profileValue.when(
      loading: () => const AppLoading(layout: AppLoadingLayout.detail),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Your profile couldn’t be loaded. Check your connection and '
            'try again.',
        onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
      ),
      data: (profileState) {
        final user = profileState.user;
        if (user == null) {
          return AppEmptyState(
            icon: Icons.person_off_outlined,
            title: 'Profile unavailable',
            message:
                profileState.errorMessage ??
                'Your profile could not be loaded.',
            actionLabel: 'Try again',
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
              ResponsiveColumns(
                primary: [
                  _IdentityCard(
                    user: user,
                    isUploadingPhoto: profileState.isUploadingPhoto,
                    onChangePhoto: () => _showPhotoOptions(user),
                  ),
                  SectionCard(
                    title: 'Account',
                    child: InfoPanel(
                      rows: [
                        InfoRow('Email', user.email, icon: Icons.mail_outline),
                        InfoRow(
                          'Department',
                          user.department,
                          icon: Icons.account_balance_outlined,
                        ),
                        if (user.matricNumber != null)
                          InfoRow(
                            'Matric number',
                            user.matricNumber!,
                            icon: Icons.tag_rounded,
                          ),
                        if (user.staffId != null)
                          InfoRow(
                            'Staff ID',
                            user.staffId!,
                            icon: Icons.tag_rounded,
                          ),
                        InfoRow(
                          'Member since',
                          Formatters.date(user.createdAt),
                          icon: Icons.event_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
                secondary: [
                  SectionCard(
                    title: 'Your details',
                    subtitle:
                        'Coordinators and lecturers see these, so keep them '
                        'current.',
                    child: _buildEditableFields(user, profileState.isSaving),
                  ),
                  SectionCard(
                    title: 'Privacy',
                    child: Column(
                      children: [
                        _LinkTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy policy',
                          onTap: () => openExternalLink(
                            context,
                            AppConstants.privacyPolicyUrl,
                          ),
                        ),
                        const Divider(),
                        _LinkTile(
                          icon: Icons.description_outlined,
                          label: 'Terms of use',
                          onTap: () =>
                              openExternalLink(context, AppConstants.termsUrl),
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Sign out or leave',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppButton(
                          label: 'Sign out',
                          icon: Icons.logout_rounded,
                          variant: AppButtonVariant.secondary,
                          isLoading: isSigningOut,
                          onPressed: isSigningOut
                              ? null
                              : () => ref
                                    .read(
                                      authenticationControllerProvider
                                          .notifier,
                                    )
                                    .logout(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                DeleteAccountDialog(role: user.role),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete my account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditableFields(UserModel user, bool isSaving) {
    Widget pair(Widget first, Widget second) => LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 440
          ? Column(
              children: [
                first,
                const SizedBox(height: AppSpacing.sm),
                second,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: first),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: second),
              ],
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pair(
          AppTextField(
            label: 'First name',
            controller: _firstNameController,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            errorText: _errors['firstName'],
          ),
          AppTextField(
            label: 'Last name',
            controller: _lastNameController,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            errorText: _errors['lastName'],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        pair(
          AppTextField(
            label: 'Phone',
            controller: _phoneController,
            enabled: !isSaving,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            errorText: _errors['phoneNumber'],
          ),
          AppTextField(
            label: 'Faculty',
            controller: _facultyController,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: 'Save changes',
            expand: false,
            isLoading: isSaving,
            onPressed: () => _save(user.profilePhotoUrl),
          ),
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
  }

  /// Saves the text fields, keeping [photoUrl] as the photo (pass an empty
  /// string to remove it).
  Future<void> _save(String? photoUrl) async {
    final errors = {
      'firstName': ProfileValidator.name(
        _firstNameController.text,
        'First name',
      ),
      'lastName': ProfileValidator.name(_lastNameController.text, 'Last name'),
      'phoneNumber': ProfileValidator.phoneNumber(_phoneController.text),
    };
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.values.any((message) => message != null)) {
      return;
    }

    await ref
        .read(profileControllerProvider.notifier)
        .save(
          ProfileUpdateRequest(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            phoneNumber: _phoneController.text,
            faculty: _facultyController.text,
            profilePhotoUrl: photoUrl,
          ),
        );
  }

  Future<void> _showPhotoOptions(UserModel user) async {
    final hasPhoto = (user.profilePhotoUrl ?? '').isNotEmpty;
    final choice = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A browser has no camera picker; it offers files instead.
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.of(context).pop(_PhotoChoice.camera),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(kIsWeb ? 'Upload a photo' : 'Choose from library'),
                onTap: () => Navigator.of(context).pop(_PhotoChoice.library),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () => Navigator.of(context).pop(_PhotoChoice.remove),
                ),
            ],
          ),
        ),
      ),
    );

    switch (choice) {
      case _PhotoChoice.camera:
        await _uploadFrom(ImageSource.camera);
      case _PhotoChoice.library:
        await _uploadFrom(ImageSource.gallery);
      case _PhotoChoice.remove:
        await _save('');
      case null:
        break;
    }
  }

  Future<void> _uploadFrom(ImageSource source) async {
    final XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      // Most often the user declined camera or photo access.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Servio couldn’t open the camera or your photos. You can allow '
              'access in your phone’s Settings.',
            ),
          ),
        );
      }
      return;
    }
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
}

enum _PhotoChoice { camera, library, remove }

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.user,
    required this.isUploadingPhoto,
    required this.onChangePhoto,
  });

  final UserModel user;
  final bool isUploadingPhoto;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = '${user.firstName} ${user.lastName}';
    final roleLabel = switch (user.role) {
      UserRole.student => 'Student',
      UserRole.lecturer => 'Lecturer',
      UserRole.coordinator => 'Coordinator',
    };

    return AppCard(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(name: name, photoUrl: user.profilePhotoUrl, size: 96),
              if (isUploadingPhoto)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              if (AppConstants.profilePhotoUploadsEnabled)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: IconButton.filled(
                    tooltip: 'Change photo',
                    onPressed: isUploadingPhoto ? null : onChangePhoto,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      side: const BorderSide(
                        color: AppColors.surface,
                        width: 3,
                      ),
                    ),
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              AppStatusChip(label: roleLabel, tone: AppTone.ink),
              AppStatusChip(
                label: user.isActive ? 'Active' : 'Awaiting approval',
                type: user.isActive
                    ? AppStatusChipType.success
                    : AppStatusChipType.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: onTap,
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
