import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// A Gemini-style "thinking" row shown while the assistant is reasoning.
///
/// Layout (RTL): a sparkle [GradientIcon], three pulsing gradient dots, then the
/// Arabic label "يفكّر...". The dots stagger their scale/opacity on a single
/// looping ticker, giving a smooth shimmering pulse. Self-contained — owns and
/// disposes its own animation controller.
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const int _dotCount = 3;
  static const Duration _period = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _period,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Eased 0->1->0 pulse for the dot at [index], staggered around the loop.
  double _pulse(double t, int index) {
    final double phase = (t - index / _dotCount) % 1.0;
    // Triangle wave 0..1..0 then smoothed for a soft breathing feel.
    final double tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return Curves.easeInOut.transform(tri.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GradientIcon(icon: Icons.auto_awesome, size: 16),
            const SizedBox(width: AppSpacing.xs),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double t = _controller.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(_dotCount, (int i) {
                    final double p = _pulse(t, i);
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.xxs,
                      ),
                      child: Opacity(
                        opacity: 0.4 + 0.6 * p,
                        child: Transform.scale(
                          scale: 0.7 + 0.5 * p,
                          child: const _GradientDot(),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'يفكّر...',
              style: AppTextStyles.caption.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small circular dot filled with the flowing gemini gradient.
class _GradientDot extends StatelessWidget {
  const _GradientDot();

  static const double _size = 7;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child: AnimatedGradient(
          duration: const Duration(seconds: 4),
          colors: AppColors.geminiColors,
        ),
      ),
    );
  }
}
