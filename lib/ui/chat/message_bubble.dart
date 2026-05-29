import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/chat/chat_models.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';
import 'package:ma_water/ui/shared/typewriter_text.dart';

/// A single chat row rendering one [ChatMessage], editorial monochrome style.
///
///  - **User**: a compact solid-ink bubble with white text and a pill-ish
///    radius, aligned to the trailing (end) edge.
///  - **Assistant**: a small solid-ink sparkle avatar ([GradientIcon] with
///    [Icons.auto_awesome], flat under the monochrome kit) sits at the leading
///    edge, and the reply text / generative-UI block flows beside it on the
///    clean white canvas, giving an airy editorial "document" feel.
///
/// When [message] carries a Generative-UI [ChatMessage.block], the [child]
/// (the already-built block widget) is rendered under any text instead of this
/// widget knowing about block specs.
///
/// When [animateText] is true *and* the message's block is a [SummaryTextSpec]
/// (plain prose), the prose is revealed with [TypewriterText] in a card that
/// matches the static `SummaryTextBlock` chrome, simulating a streaming Gemini
/// answer; [onTextAnimated] fires once the reveal completes so the caller can
/// flag the message as already-animated and stop re-animating on rebuild. For
/// every other block type [child] (the pre-built static block) is rendered.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.child,
    this.animateText = false,
    this.onTextAnimated,
  });

  /// The message to render.
  final ChatMessage message;

  /// Pre-built Generative-UI block widget for [ChatMessage.block], if any.
  final Widget? child;

  /// When true, a [SummaryTextSpec] block is revealed via [TypewriterText]
  /// (used only for the newest assistant reply, exactly once).
  final bool animateText;

  /// Invoked once the typewriter reveal of a [SummaryTextSpec] completes.
  final VoidCallback? onTextAnimated;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return _isUser ? _buildUser(context) : _buildAssistant(context);
  }

  // --------------------------------------------------------------------------
  // User — solid-ink bubble, white text, pill-ish radius, trailing edge.
  // --------------------------------------------------------------------------

  Widget _buildUser(BuildContext context) {
    final String text = message.text ?? '';
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(AppRadius.lg),
            topEnd: Radius.circular(AppRadius.lg),
            bottomEnd: Radius.circular(AppRadius.sm),
            bottomStart: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyLg.copyWith(color: AppColors.canvas),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Assistant — sparkle avatar + flowing content, leading edge.
  // --------------------------------------------------------------------------

  Widget _buildAssistant(BuildContext context) {
    final BlockSpec? block = message.block;

    // Newest plain-prose reply: stream it in with a typewriter caret inside a
    // card matching the static SummaryTextBlock chrome.
    final bool animateSummary =
        animateText && block is SummaryTextSpec && (child != null);
    if (animateSummary) {
      return _buildAssistantRow(
        _TypewriterSummaryCard(
          text: block.text,
          onComplete: onTextAnimated,
        ),
      );
    }

    final bool hasBlock = block != null && child != null;
    final String? text = message.text;
    final bool hasText = text != null && text.trim().isNotEmpty;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Plain assistant prose reads as a flat white hairline card so it
        // matches the static SummaryTextBlock / typewriter chrome.
        if (hasText) _AssistantTextCard(text: text),
        if (hasText && hasBlock) const SizedBox(height: AppSpacing.sm),
        if (hasBlock) child!,
      ],
    );

    return _buildAssistantRow(content);
  }

  /// Wraps assistant [content] with the leading sparkle avatar, shared by the
  /// static and typewriter paths so both align identically (RTL-correct).
  Widget _buildAssistantRow(Widget content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(top: AppSpacing.xxs),
          child: _SparkleAvatar(),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: content),
      ],
    );
  }
}

/// The small solid-ink sparkle (flat under the monochrome kit) that prefixes
/// every assistant message, set in a circular white hairline chip.
class _SparkleAvatar extends StatelessWidget {
  const _SparkleAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.lg + AppSpacing.xs,
      height: AppSpacing.lg + AppSpacing.xs,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline),
      ),
      alignment: Alignment.center,
      child: const GradientIcon(
        icon: Icons.auto_awesome,
        size: AppSpacing.md,
        gradient: AppColors.rainbowGradient,
      ),
    );
  }
}

/// A plain assistant prose reply on a flat white hairline card (radius lg),
/// matching the static `SummaryTextBlock` / [_TypewriterSummaryCard] chrome so
/// the bubble reads consistently across the static and streaming paths.
class _AssistantTextCard extends StatelessWidget {
  const _AssistantTextCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink),
      ),
    );
  }
}

/// A [SummaryTextSpec] reply rendered with a streaming [TypewriterText] reveal,
/// wrapped in chrome identical to the static `SummaryTextBlock` so the bubble
/// does not visibly shift when the animation finishes and the list rebuilds
/// with the static card. RTL is inherited from the ambient [Directionality].
class _TypewriterSummaryCard extends StatelessWidget {
  const _TypewriterSummaryCard({required this.text, this.onComplete});

  final String text;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: TypewriterText(
        text,
        style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink),
        onComplete: onComplete,
      ),
    );
  }
}
