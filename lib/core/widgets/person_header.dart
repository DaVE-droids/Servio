import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import 'app_avatar.dart';
import 'app_card.dart';

/// The top of a person's detail page, after the sample's "Student Details"
/// card: a large portrait tile, the name, identifying chips, and room for a
/// status, the journey track, and actions underneath.
class PersonHeader extends StatelessWidget {
  /// Creates a person header.
  const PersonHeader({
    required this.name,
    this.photoUrl,
    this.tags = const [],
    this.status,
    this.footer,
    super.key,
  });

  /// Full name.
  final String name;

  /// Optional photo.
  final String? photoUrl;

  /// Short identifying facts shown as grey chips (matric number, class…).
  final List<String> tags;

  /// Optional status pill shown after the tags.
  final Widget? status;

  /// Optional content under the identity: journey track, actions.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        children: [
          AppAvatar(name: name, photoUrl: photoUrl, size: 96),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags.where((tag) => tag.trim().isNotEmpty))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ?status,
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
