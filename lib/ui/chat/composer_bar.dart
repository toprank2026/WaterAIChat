import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';

/// The message-composition bar pinned to the bottom of the chat.
///
/// Layout (RTL), Figma editorial look: a flat white input framed by a 1px
/// [AppColors.hairline] border with [AppRadius.lg] rounded corners, a disabled
/// microphone placeholder (voice is out of scope for v1, PRD §F1), and a solid
/// black circular send button with a white arrow. No shadows, no gradients —
/// the send disc simply dims when there's nothing to send. Submitting happens
/// on the keyboard action or the send button; empty/whitespace input is
/// ignored.
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
            Expanded(child: _buildInputField()),
            const SizedBox(width: AppSpacing.xs),
            _SendButton(enabled: canSend, onTap: _submit),
          ],
        ),
      ),
    );
  }

  /// The input field: a flat white surface with a 1px hairline border and
  /// [AppRadius.lg] corners. Flat, no shadow.
  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
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
              cursorColor: AppColors.ink,
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
    );
  }
}

/// Circular send button. Solid black disc with a white arrow when there's text
/// to send; a flat dimmed disc otherwise. Flat — no shadow, no gradient.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  static const double _size = AppSpacing.xl + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.ink : AppColors.surfaceSoft,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Center(
            child: Icon(
              Icons.arrow_upward,
              color: enabled ? AppColors.canvas : AppColors.slate,
              size: AppSpacing.lg,
            ),
          ),
        ),
      ),
    );
  }
}
