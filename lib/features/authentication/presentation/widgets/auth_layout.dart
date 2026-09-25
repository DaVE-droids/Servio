import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/brand_mark.dart';

/// The frame shared by sign-in, sign-up, password reset, and the waiting
/// screens: a brand panel telling the placement journey on wide screens,
/// and the form on white.
class AuthLayout extends StatelessWidget {
  /// Creates the auth layout.
  const AuthLayout({
    required this.title,
    required this.children,
    this.subtitle,
    this.eyebrow,
    this.maxFormWidth = 420,
    super.key,
  });

  /// Form heading.
  final String title;

  /// Line under the heading.
  final String? subtitle;

  /// Small label above the heading.
  final String? eyebrow;

  /// Form content.
  final List<Widget> children;

  /// Widest the form column grows.
  final double maxFormWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= 940;

    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxFormWidth),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isWide) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandLockup(markSize: 34),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (eyebrow != null) ...[
                  Text(eyebrow!.toUpperCase(), style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(title, style: textTheme.headlineLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 6, child: form),
                ],
              )
            : form,
      ),
    );
  }
}

/// The left half on wide screens: what Servio is, told as the journey
/// every placement takes.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLockup(markSize: 36, onDark: true),
          const Spacer(),
          Text(
            'Every placement, from first form to final sign-off.',
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Students log their days, lecturers supervise, and coordinators '
            'see the whole cohort — in one place.',
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _JourneyStop(
            label: 'Placement submitted',
            detail: 'Company, supervisor, and dates, checked by a coordinator',
            fill: AppColors.sky,
          ),
          const _JourneyStop(
            label: 'Days logged and supervised',
            detail: 'Daily check-ins, logbook entries, and lecturer visits',
            fill: AppColors.blush,
          ),
          const _JourneyStop(
            label: 'Signed off',
            detail: 'A complete, auditable record of the internship',
            fill: Colors.white,
            isLast: true,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _JourneyStop extends StatelessWidget {
  const _JourneyStop({
    required this.label,
    required this.detail,
    required this.fill,
    this.isLast = false,
  });

  final String label;
  final String detail;
  final Color fill;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    detail,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
