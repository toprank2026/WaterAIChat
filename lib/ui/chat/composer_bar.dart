import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// The message-composition bar pinned to the bottom of the chat, Gemini style.
///
/// Layout (RTL): a rounded pill input wrapped in a thin **animated gradient
/// ring** ([AnimatedGradient]) that subtly flows around the field, a disabled
/// microphone placeholder (voice is out of scope for v1, PRD §F1), and a
/// circular send button. When the field holds text the send button becomes a
/// flowing [AnimatedGradient] circle; otherwise it dims. Submitting happens on
/// the keyboard action or the send button; empty/whitespace input is ignored.
class ComposerBar extends StatefulWidget {
  const ComposerBar({
    super.key,
    required this.onSend,
    this.controller,
  });

  /// Invoked with the trimmed message text when the user submits.
  final void Function(String text) onSend;

  /// Optional external controller. When provided, the parent owns the text
  /// (e.g. to prefill from a "ask about this station" action); otherwise this
  /// widget manages its own.
  final TextEditingController? controller;

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  TextEditingController? _internalController;
  bool _ownsController = false;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
      _ownsController = true;
    }
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant ComposerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(_onChanged);
      if (widget.controller == null && _internalController == null) {
        _internalController = TextEditingController();
        _ownsController = true;
      } else if (widget.controller != null && _ownsController) {
        _internalController?.dispose();
        _internalController = null;
        _ownsController = false;
      }
      _controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _internalController?.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Rebuild so the send button enables/disables with the input.
    setState(() {});
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _controller.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _buildInputPill()),
            const SizedBox(width: AppSpacing.xs),
            _SendButton(enabled: canSend, onTap: _submit),
          ],
        ),
      ),
    );
  }

  /// The pill input: a thin animated gradient ring framing a white field.
  Widget _buildInputPill() {
    const double ring = 1.5;
    return AnimatedGradient(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.all(ring),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            end: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  minLines: 1,
                  maxLines: 5,
                  style: AppTextStyles.bodyLg,
                  cursorColor: AppColors.teal,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'اكتب سؤالك عن مستوى الماء…',
                    hintStyle:
                        AppTextStyles.bodyLg.copyWith(color: AppColors.slate),
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              // Disabled mic placeholder — voice input is out of scope (F1).
              IconButton(
                onPressed: null,
                tooltip: 'الإدخال الصوتي غير متاح',
                icon: const Icon(Icons.mic_none),
                color: AppColors.slate,
                disabledColor: AppColors.slate,
                iconSize: AppSpacing.lg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular send button. A flowing [AnimatedGradient] when there's text to
/// send; a flat dimmed disc otherwise.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  static const double _size = AppSpacing.xl + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: _size,
          height: _size,
          child: enabled
              ? const AnimatedGradient(
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRadius.pill)),
                  child: Center(
                    child: Icon(
                      Icons.arrow_upward,
                      color: AppColors.card,
                      size: AppSpacing.lg,
                    ),
                  ),
                )
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.line,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_upward,
                      color: AppColors.slate,
                      size: AppSpacing.lg,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
