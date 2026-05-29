import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';

/// A continuously flowing [LinearGradient] painted as the background of an
/// optional [child].
///
/// The gradient's `begin`/`end` alignments orbit the box driven by a looping
/// [AnimationController], producing a smooth, subtle, infinite "living" sheen —
/// the Gemini-style ambient gradient used across the chat, settings, and
/// onboarding surfaces.
///
/// Self-contained: owns and disposes its own ticker.
class AnimatedGradient extends StatefulWidget {
  const AnimatedGradient({
    this.colors = AppColors.geminiColors,
    this.child,
    this.duration = const Duration(seconds: 6),
    this.borderRadius,
    super.key,
  });

  /// Gradient stops, in order. Defaults to [AppColors.geminiColors].
  final List<Color> colors;

  /// Optional content painted on top of the animated gradient.
  final Widget? child;

  /// One full orbit of the gradient direction.
  final Duration duration;

  /// Optional rounding clipped against the gradient fill.
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
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (_controller.isAnimating) {
        _controller
          ..stop()
          ..repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A unit-circle alignment offset by [phase] turns (0..1).
  Alignment _alignmentForPhase(double phase) {
    final double angle = phase * 2 * math.pi;
    return Alignment(math.cos(angle), math.sin(angle));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        final Alignment begin = _alignmentForPhase(t);
        // Diametrically opposite point keeps the gradient axis full-width.
        final Alignment end = _alignmentForPhase(t + 0.5);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: widget.colors,
              begin: begin,
              end: end,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Paints [text] filled with a [gradient] via a [ShaderMask].
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    this.style,
    this.gradient = AppColors.geminiGradient,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        // The shader supplies the visible color; white keeps the mask opaque.
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

/// Paints an [icon] filled with a [gradient] via a [ShaderMask].
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
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => gradient.createShader(bounds),
      child: Icon(
        icon,
        size: size,
        // White so the gradient shader is what shows through the mask.
        color: Colors.white,
      ),
    );
  }
}
