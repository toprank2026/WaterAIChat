import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';

/// Wraps [child] in a continuously sweeping diagonal "light" highlight.
///
/// Drives a looping [AnimationController] that slides a [LinearGradient] across
/// the child via a [ShaderMask]. The sweep is strictly monochrome — a soft
/// [AppColors.surfaceSoft] base with a slightly brighter (still grayscale)
/// canvas/[AppColors.hairlineSoft] highlight band, then back to base — so it
/// never introduces color, matching the flat editorial system. Compose loading
/// placeholders by wrapping grey [ShimmerBox]es (or whole skeleton presets) in
/// a single [Shimmer] so they share one smooth, synchronized sweep.
///
/// Self-contained: owns and disposes its own ticker. The sweep `repeat()`s,
/// which is safe for widget tests that call a single `pump()` (it never settles
/// but does not block a single frame).
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  /// The content masked by the moving highlight (typically grey placeholders).
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// One full sweep across the child.
  static const Duration _period = Duration(milliseconds: 1400);

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            // Slide a highlight band diagonally from off-start to off-end.
            // t: 0 -> 1 maps the band's center across (and past) the bounds.
            final double t = _controller.value;
            // Travel from -1 .. 2 so the band fully enters and exits.
            final double shift = -1.0 + t * 3.0;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // Grayscale sweep only: soft base -> faint canvas highlight ->
              // back to base. No pastel, no color.
              colors: const <Color>[
                AppColors.surfaceSoft,
                AppColors.hairlineSoft,
                AppColors.canvas,
                AppColors.surfaceSoft,
              ],
              stops: <double>[
                (shift - 0.30).clamp(0.0, 1.0),
                (shift - 0.10).clamp(0.0, 1.0),
                (shift + 0.10).clamp(0.0, 1.0),
                (shift + 0.30).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single rounded shimmering block — the atom of every skeleton preset.
///
/// Renders a flat grey ([AppColors.surfaceSoft]) rounded box wrapped in
/// [Shimmer]. Pass an explicit [width] or leave it null to fill the available
/// horizontal space.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    this.width,
    required this.height,
    this.radius,
    super.key,
  });

  /// Block width; null stretches to the parent's constraints.
  final double? width;

  /// Block height in logical pixels.
  final double height;

  /// Corner rounding; defaults to [AppRadius.sm].
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: radius ?? BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// Shared GenUI-card chrome for the skeleton presets: flat white surface, a
/// single 1px [AppColors.hairline] border and [AppRadius.lg] corners with
/// [AppSpacing.md] padding. No shadow — depth comes from the hairline alone,
/// matching the flat editorial GenUI blocks.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: child,
    );
  }
}

/// Placeholder for an assistant reply card: a title bar plus three text lines.
///
/// Sized like a real bot reply bubble and aligned to the start (RTL-correct).
class ChatReplySkeleton extends StatelessWidget {
  const ChatReplySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Title bar.
              const ShimmerBox(width: 140, height: 16),
              const SizedBox(height: AppSpacing.sm),
              // Three body lines, the last one short.
              const ShimmerBox(height: 12),
              const SizedBox(height: AppSpacing.xs),
              const ShimmerBox(height: 12),
              const SizedBox(height: AppSpacing.xs),
              ShimmerBox(
                width: 180,
                height: 12,
                radius: BorderRadius.circular(AppRadius.sm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for a chart block: a title, a ~140h plot area, and an axis line.
///
/// Total height lands near 220 logical pixels, matching the real chart cards.
class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Chart title.
          const ShimmerBox(width: 120, height: 14),
          const SizedBox(height: AppSpacing.md),
          // Plot area: a row of bars of varying heights baselined together.
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const <Widget>[
                _ChartBar(0.45),
                SizedBox(width: AppSpacing.sm),
                _ChartBar(0.70),
                SizedBox(width: AppSpacing.sm),
                _ChartBar(0.35),
                SizedBox(width: AppSpacing.sm),
                _ChartBar(0.90),
                SizedBox(width: AppSpacing.sm),
                _ChartBar(0.55),
                SizedBox(width: AppSpacing.sm),
                _ChartBar(0.75),
                SizedBox(width: AppSpacing.sm),
                _ChartBar(0.50),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // X-axis baseline.
          const ShimmerBox(height: 8),
        ],
      ),
    );
  }
}

/// A single chart bar occupying [fraction] of the available column height.
class _ChartBar extends StatelessWidget {
  const _ChartBar(this.fraction);

  /// Bar height as a fraction (0..1) of the plot area height.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FractionallySizedBox(
        heightFactor: fraction.clamp(0.0, 1.0),
        child: ShimmerBox(
          height: double.infinity,
          radius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// Placeholder for a map block: a single ~280h rounded shimmering block.
class MapSkeleton extends StatelessWidget {
  const MapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      height: 280,
      radius: BorderRadius.circular(AppRadius.lg),
    );
  }
}

/// Placeholder for a ranked/station list: [rows] avatar-and-two-lines rows.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({this.rows = 5, super.key});

  /// Number of placeholder rows to render.
  final int rows;

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            const _ListRowSkeleton(),
          ],
        ],
      ),
    );
  }
}

/// A single list row: a circular avatar, two stacked text lines, a trailing pill.
class _ListRowSkeleton extends StatelessWidget {
  const _ListRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // Leading circular avatar.
        const ShimmerBox(
          width: 40,
          height: 40,
          radius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Two stacked text lines.
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ShimmerBox(height: 12),
              SizedBox(height: AppSpacing.xs),
              ShimmerBox(width: 120, height: 10),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Trailing status pill.
        ShimmerBox(
          width: 48,
          height: 20,
          radius: BorderRadius.circular(AppRadius.pill),
        ),
      ],
    );
  }
}

/// Placeholder for a 2x2 stat grid: four tile placeholders.
class StatGridSkeleton extends StatelessWidget {
  const StatGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _StatTileSkeleton()),
            SizedBox(width: AppSpacing.md),
            Expanded(child: _StatTileSkeleton()),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(child: _StatTileSkeleton()),
            SizedBox(width: AppSpacing.md),
            Expanded(child: _StatTileSkeleton()),
          ],
        ),
      ],
    );
  }
}

/// A single stat tile: a GenUI card with a label line and a big value bar.
class _StatTileSkeleton extends StatelessWidget {
  const _StatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          // Label.
          ShimmerBox(width: 70, height: 10),
          SizedBox(height: AppSpacing.sm),
          // Big metric value.
          ShimmerBox(width: 90, height: 24),
        ],
      ),
    );
  }
}
