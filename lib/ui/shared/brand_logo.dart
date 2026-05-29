import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';

/// The "Mā" brand lockup: a gradient water-drop glyph next to the wordmark
/// "مياه".
///
/// The drop uses a [ShaderMask] to paint [AppColors.primaryGradient] through
/// [Icons.water_drop]. Set [showWordmark] to `false` for an icon-only mark.
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
    final Widget drop = ShaderMask(
      shaderCallback: (Rect bounds) =>
          AppColors.primaryGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Icon(
        Icons.water_drop,
        size: iconSize,
        // Color is replaced by the shader; supplies the alpha mask.
        color: AppColors.card,
      ),
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
