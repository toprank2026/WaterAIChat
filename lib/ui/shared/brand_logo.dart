import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';

/// The "Mā" brand lockup: a solid ink water-drop mark beside the wordmark
/// "مياه".
///
/// Monochrome and FLAT — the drop is painted in pure [AppColors.ink] (no
/// gradient, no shader), and the wordmark uses [AppTextStyles.displayMd] in ink.
/// Set [showWordmark] to `false` for an icon-only mark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.iconSize = AppSpacing.xl,
    this.showWordmark = true,
  });

  /// Diameter of the water-drop glyph.
  final double iconSize;

  /// Whether to render the "مياه" wordmark beside the glyph.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final Widget drop = Icon(
      Icons.water_drop,
      size: iconSize,
      color: AppColors.ink,
    );

    if (!showWordmark) return drop;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        drop,
        const SizedBox(width: AppSpacing.xs),
        Text(
          'مياه',
          style: AppTextStyles.displayMd,
        ),
      ],
    );
  }
}
