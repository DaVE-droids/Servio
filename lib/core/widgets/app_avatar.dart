import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tone.dart';

/// A person: their photo if they have one, otherwise their initials on a
/// soft rounded square (the sample's portrait tiles).
///
/// The tint is picked from the name, so the same person always gets the
/// same colour across every list and detail page.
class AppAvatar extends StatelessWidget {
  /// Creates an avatar.
  const AppAvatar({
    required this.name,
    this.photoUrl,
    this.size = 40,
    super.key,
  });

  /// Full name, used for initials and the tint.
  final String name;

  /// Optional photo.
  final String? photoUrl;

  /// Width and height.
  final double size;

  static const _tints = [AppTone.sky, AppTone.blush, AppTone.ink];

  @override
  Widget build(BuildContext context) {
    // A plain character sum rather than hashCode, which isn't guaranteed to
    // be the same on every platform.
    final tone =
        _tints[name.codeUnits.fold(0, (a, b) => a + b) % _tints.length];
    final radius = BorderRadius.circular(size * 0.3);
    final url = photoUrl;
    final initialsWidget = Center(
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: tone == AppTone.ink ? AppColors.ink : AppColors.inkDeep,
          height: 1,
        ),
      ),
    );

    return Semantics(
      label: name,
      image: url != null && url.isNotEmpty,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tone == AppTone.ink ? AppColors.inkSoft : tone.fill,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: url == null || url.isEmpty
            ? initialsWidget
            : Image.network(
                url,
                fit: BoxFit.cover,
                // Decode at display size rather than full resolution.
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => initialsWidget,
              ),
      ),
    );
  }

  /// Up to two initials from a name: "Ada Obi" → "AO".
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }
}
