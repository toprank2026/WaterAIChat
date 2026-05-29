import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';

/// A flat solid-color background painted behind an optional [child].
///
/// Formerly a continuously orbiting [LinearGradient]; under the monochrome,
/// shadow-free editorial system the surface is now a single flat fill. The
/// first entry of [colors] (defaulting to [AppColors.ink]) supplies the
/// solid color — no animation, no gradient.
///
/// The looping [AnimationController] is retained (and disposed) so the widget
/// API is unchanged and call sites keep compiling, but it no longer drives any
/// visual change.
class AnimatedGradient extends StatefulWidget {
  const AnimatedGradient({
    this.colors = AppColors.geminiColors,
    this.child,
    this.duration = const Duration(seconds: 6),
    this.borderRadius,
    super.key,
  });

  /// Color list, kept for API compatibility. Only the first entry is used as
  /// the flat fill; if empty, falls back to [AppColors.ink].
  final List<Color> colors;

  /// Optional content painted on top of the solid fill.
  final Widget? child;

  /// Retained for API compatibility; no longer drives a visible animation.
  final Duration duration;

  /// Optional rounding clipped against the solid fill.
  final BorderRadius? borderRadius;

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Flat solid fill — first color, or ink. No gradient, no shadow.
    final Color fill = widget.colors.isNotEmpty
        ? widget.colors.first
        : AppColors.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: widget.borderRadius,
      ),
      child: widget.child,
    );
  }
}

/// Paints [text] in a flat solid [AppColors.ink].
///
/// Formerly filled the glyphs with a gradient via a [ShaderMask]; the [gradient]
/// param is retained for API compatibility but no longer affects rendering.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    this.style,
    this.gradient = AppColors.geminiGradient,
    super.key,
  });

  final String text;
  final TextStyle? style;

  /// Retained for API compatibility; no longer used for rendering.
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(color: AppColors.ink),
    );
  }
}

/// Paints an [icon] in a flat solid [AppColors.ink].
///
/// Formerly filled the glyph with a gradient via a [ShaderMask]; the [gradient]
/// param is retained for API compatibility but no longer affects rendering.
///
/// Call sites use [Icons.auto_awesome] (sparkle) for the Gemini accent.
class GradientIcon extends StatelessWidget {
  const GradientIcon({
    required this.icon,
    this.size = 20,
    this.gradient = AppColors.geminiGradient,
    super.key,
  });

  final IconData icon;
  final double size;

  /// Retained for API compatibility; no longer used for rendering.
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: AppColors.ink,
    );
  }
}
