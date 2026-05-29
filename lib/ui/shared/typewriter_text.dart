import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// Reveals [text] grapheme-by-grapheme (so emoji/diacritics stay intact),
/// like a Gemini-style streaming answer, with an optional blinking caret.
///
/// RTL-aware: the text uses the ambient [Directionality] (Arabic content reads
/// right-to-left) and the caret is appended in logical order, so it trails the
/// visible end of the text in both LTR and RTL.
///
/// Self-contained: owns and disposes its own ticker. Handles empty text (fires
/// [onComplete] immediately) and long text (animates in constant memory by
/// slicing precomputed grapheme boundaries).
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    this.style,
    this.charInterval = const Duration(milliseconds: 18),
    this.onComplete,
    this.showCaret = true,
    super.key,
  });

  /// The full string to reveal.
  final String text;

  /// Style for the revealed text; falls back to [AppTextStyles.bodyLg].
  final TextStyle? style;

  /// Delay between each revealed grapheme.
  final Duration charInterval;

  /// Invoked once when the full [text] has finished revealing.
  final VoidCallback? onComplete;

  /// Whether to show the blinking caret while/after revealing.
  final bool showCaret;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  /// Grapheme-boundary character offsets, so reveal never splits a cluster.
  late List<String> _graphemes;

  /// Drives the reveal: value 0..1 maps linearly onto grapheme count.
  late final AnimationController _reveal;

  /// Drives the blinking caret independently of the reveal speed.
  late final AnimationController _caret;

  int _shown = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _caret = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _reveal = AnimationController(vsync: this)
      ..addListener(_onRevealTick)
      ..addStatusListener(_onRevealStatus);
    _graphemes = _split(widget.text);
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _graphemes = _split(widget.text);
      _completed = false;
      _shown = 0;
      _start();
    }
  }

  @override
  void dispose() {
    _reveal
      ..removeListener(_onRevealTick)
      ..removeStatusListener(_onRevealStatus)
      ..dispose();
    _caret.dispose();
    super.dispose();
  }

  /// Splits [text] into user-perceived characters (grapheme clusters).
  ///
  /// Dart's [String.characters] honors Unicode boundaries, keeping emoji and
  /// Arabic base+diacritic combinations together so the reveal never tears a
  /// glyph in half.
  static List<String> _split(String text) => text.characters.toList();

  void _start() {
    _reveal.stop();
    if (_graphemes.isEmpty) {
      // Nothing to reveal — report completion after this frame so listeners can
      // safely call setState in response.
      _completed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete?.call();
      });
      return;
    }
    // Total duration scales with length; the per-grapheme cadence stays at
    // [charInterval] regardless of how long the text is.
    _reveal
      ..duration = widget.charInterval * _graphemes.length
      ..value = 0
      ..forward();
  }

  void _onRevealTick() {
    final int next = (_reveal.value * _graphemes.length).floor().clamp(
          0,
          _graphemes.length,
        );
    if (next != _shown) {
      setState(() => _shown = next);
    }
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      if (_shown != _graphemes.length) {
        setState(() => _shown = _graphemes.length);
      }
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = widget.style ?? AppTextStyles.bodyLg;
    final String visible = _graphemes.take(_shown).join();

    if (!widget.showCaret) {
      return Text(visible, style: baseStyle);
    }

    // Caret is appended in logical order via a TextSpan so it tracks the end of
    // the revealed text and inherits the text direction from Directionality.
    return AnimatedBuilder(
      animation: _caret,
      builder: (context, _) {
        return Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: visible),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Opacity(
                  opacity: _caret.value,
                  child: _Caret(
                    color: baseStyle.color ?? AppColors.ink,
                    height: (baseStyle.fontSize ?? 15) * 1.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A thin vertical caret bar sized to the surrounding text.
class _Caret extends StatelessWidget {
  const _Caret({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 1),
      child: Container(
        width: 2,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// A Gemini-style "generating answer" row: a sparkle [GradientIcon] followed by
/// the Arabic label "يولّد الإجابة…" whose color sweeps along the gemini
/// gradient via a moving [ShaderMask], giving a soft shimmering effect.
///
/// Self-contained — owns and disposes its own animation controller.
class GeneratingLabel extends StatefulWidget {
  const GeneratingLabel({super.key});

  @override
  State<GeneratingLabel> createState() => _GeneratingLabelState();
}

class _GeneratingLabelState extends State<GeneratingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const String _label = 'يولّد الإجابة…';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        AppTextStyles.caption.copyWith(color: Colors.white);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GradientIcon(icon: Icons.auto_awesome, size: 16),
        const SizedBox(width: AppSpacing.xs),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Sweep the gradient horizontally across the text to shimmer it.
            final double dx = _controller.value;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                final double w = bounds.width;
                return LinearGradient(
                  colors: AppColors.geminiColors,
                  begin: Alignment(-1 - 2 * dx, 0),
                  end: Alignment(1 - 2 * dx, 0),
                  tileMode: TileMode.mirror,
                ).createShader(
                  Rect.fromLTWH(0, 0, w == 0 ? 1 : w, bounds.height),
                );
              },
              child: child,
            );
          },
          // The text is built once; only the shader moves each frame.
          child: Text(_label, style: style),
        ),
      ],
    );
  }
}
