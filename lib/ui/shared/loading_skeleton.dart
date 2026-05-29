import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';

/// A single flat grayscale placeholder rectangle whose opacity pulses.
///
/// Used to compose loading skeletons. Flat, no shadow — a hairline-soft fill
/// pill (radius [AppRadius.sm]) that pulses via an ambient [AnimationController]
/// so a row of bars share the same animation feel without each managing its own
/// ticker.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({
    super.key,
    required this.width,
    required this.height,
    required this.opacity,
    this.color,
  });

  /// Bar width in logical pixels.
  final double width;

  /// Bar height in logical pixels.
  final double height;

  /// Current animated opacity (0..1).
  final double opacity;

  /// Optional fill color; defaults to [AppColors.hairlineSoft] (grayscale).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? AppColors.hairlineSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// An animated placeholder bubble shown while the assistant is "typing".
///
/// Mimics an incoming assistant (bot) message: a flat white hairline card
/// (radius [AppRadius.lg], no shadow) holding a leading solid-ink avatar dot and
/// a few grayscale bars whose opacity oscillates to suggest activity.
/// Self-contained (owns its own animation) so callers can drop it into the chat
/// list directly.
class ChatBubbleSkeleton extends StatefulWidget {
  const ChatBubbleSkeleton({super.key});

  @override
  State<ChatBubbleSkeleton> createState() => _ChatBubbleSkeletonState();
}

class _ChatBubbleSkeletonState extends State<ChatBubbleSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        final double o = _opacity.value;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: o,
                  child: Container(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonBar(width: 160, height: AppSpacing.sm, opacity: o),
                    const SizedBox(height: AppSpacing.xs),
                    SkeletonBar(width: 120, height: AppSpacing.sm, opacity: o),
                    const SizedBox(height: AppSpacing.xs),
                    SkeletonBar(width: 90, height: AppSpacing.sm, opacity: o),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
