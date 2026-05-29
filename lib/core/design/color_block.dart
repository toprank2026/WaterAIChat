import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';

/// A flat, oversized **pastel color block** — the signature surface of the
/// "Mā" design system (see DESIGN.md → "Color-Block Sections").
///
/// Color blocks are the system's depth device: instead of shadowed white
/// cards, a story/section drops onto a saturated pastel panel (lime, lilac,
/// cream, pink, mint, coral) or the deep [AppColors.blockNavy]. The change
/// from white canvas to a colored panel *is* the section break.
///
/// ### The look
/// - **Flat.** No shadow, no gradient. The color carries the elevation.
/// - **Rounded.** [AppRadius.lg] (24) corners by default, like a giant sticky
///   note placed on a clean desk.
/// - **Generous.** [AppSpacing.lg] / [AppSpacing.xl] interior padding so the
///   panel reads as a poster, not a wall of copy.
/// - **Ink text.** Children inherit ink (#000) by default; on the dark navy
///   block pass [inverse]`: true` so text flips to canvas white (#fff).
///
/// ### Usage
/// ```dart
/// // Lime "systems" block
/// ColorBlock(
///   color: AppColors.blockLime,
///   child: Text('مرحبا', style: AppTextStyles.titleLg),
/// )
///
/// // Deep navy block — flip text to white
/// ColorBlock(
///   color: AppColors.blockNavy,
///   inverse: true,
///   child: Text('اشحن منتجاتك', style: AppTextStyles.titleLg),
/// )
///
/// // Tighter inline panel (custom padding + smaller radius)
/// ColorBlock(
///   color: AppColors.blockCream,
///   radius: AppRadius.md,
///   padding: const EdgeInsetsDirectional.all(AppSpacing.md),
///   child: const Text('قالب'),
/// )
/// ```
///
/// Pick exactly **one** [AppColors.block*] token per block and let the white
/// canvas separate it from the next — never stack two blocks in one viewport
/// (DESIGN.md → Do's & Don'ts). Do **not** add a [BoxShadow] or gradient to a
/// color block; the color is the depth.
///
/// This widget is intentionally tiny and stateless so it is cheap to reuse and
/// safe to render in tests. The default foreground color is applied via
/// [DefaultTextStyle] and [IconTheme] so plain [Text]/[Icon] children pick up
/// the correct ink/white color without per-call-site overrides — explicit
/// colors on a child's own style always win.
class ColorBlock extends StatelessWidget {
  const ColorBlock({
    super.key,
    required this.color,
    required this.child,
    this.padding,
    this.radius = AppRadius.lg,
    this.inverse = false,
  });

  /// The pastel (or navy) panel background. Use an [AppColors.block*] token.
  final Color color;

  /// Content placed inside the panel.
  final Widget child;

  /// Interior padding. Defaults to [AppSpacing.xl] all around (poster-style
  /// breathing room). Pass an [EdgeInsetsDirectional] to stay RTL-correct.
  final EdgeInsetsGeometry? padding;

  /// Corner radius. Defaults to [AppRadius.lg] (24).
  final double radius;

  /// When `true`, foreground text/icons default to canvas white (#fff) instead
  /// of ink (#000). Use on the dark [AppColors.blockNavy] block.
  final bool inverse;

  /// Builds the flat [BoxDecoration] for a color block — handy when you need
  /// the surface without the padding/text wiring (e.g. for a [Container] or
  /// [Ink] you are decorating yourself). Always flat: no shadow, no gradient.
  static BoxDecoration decoration({
    required Color color,
    double radius = AppRadius.lg,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color foreground = inverse ? AppColors.canvas : AppColors.ink;

    return DecoratedBox(
      decoration: decoration(color: color, radius: radius),
      child: Padding(
        padding: padding ?? const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: child,
          ),
        ),
      ),
    );
  }
}
