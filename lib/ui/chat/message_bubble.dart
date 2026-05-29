import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/chat/chat_models.dart';

/// A single chat row rendering one [ChatMessage] as a bubble.
///
/// Variants follow the PRD §10.6 component recipes:
///  - **User**: [AppColors.primaryGradient] fill, white text, corner radii
///    `lg lg xs lg`, padded `sm md`, aligned to the trailing (end) edge.
///  - **Assistant**: [AppColors.card] surface, [AppColors.ink] text, 1px
///    [AppColors.line] border, corner radii `lg lg lg xs`, aligned to the
///    leading (start) edge.
///
/// When [message] carries a Generative-UI [ChatMessage.block], the [child]
/// (the already-built block widget) is rendered inside/under the bubble text
/// instead of relying on this widget to know about block specs.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.child,
  });

  /// The message to render.
  final ChatMessage message;

  /// Pre-built Generative-UI block widget for [ChatMessage.block], if any.
  final Widget? child;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final bool hasBlock = message.block != null && child != null;
    final String? text = message.text;
    final bool hasText = text != null && text.trim().isNotEmpty;

    // Assistant blocks (charts, maps, ranked lists) want full width to be
    // legible, so block-bearing assistant messages stretch across the row.
    final bool fullWidth = !_isUser && hasBlock;

    final Widget bubble = Container(
      constraints: fullWidth
          ? null
          : BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasText)
            Text(
              text,
              style: AppTextStyles.bodyLg.copyWith(
                color: _isUser ? AppColors.card : AppColors.ink,
              ),
            ),
          if (hasText && hasBlock) const SizedBox(height: AppSpacing.sm),
          if (hasBlock) child!,
        ],
      ),
    );

    return Align(
      alignment:
          _isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: bubble,
    );
  }

  BoxDecoration _decoration() {
    if (_isUser) {
      return const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(AppRadius.lg),
          topEnd: Radius.circular(AppRadius.lg),
          bottomEnd: Radius.circular(AppRadius.sm),
          bottomStart: Radius.circular(AppRadius.lg),
        ),
      );
    }
    return const BoxDecoration(
      color: AppColors.card,
      border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
      borderRadius: BorderRadiusDirectional.only(
        topStart: Radius.circular(AppRadius.lg),
        topEnd: Radius.circular(AppRadius.lg),
        bottomEnd: Radius.circular(AppRadius.lg),
        bottomStart: Radius.circular(AppRadius.sm),
      ),
    );
  }
}
