import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/design/color_block.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// Editorial empty state for the chat: a small mono eyebrow, a large ink
/// headline on a soft cream color block, a flat ink sparkle accent, and a few
/// tappable suggestion pills that seed the first question.
///
/// Shown by [ChatScreen] when the transcript holds only the seeded welcome
/// message. Tapping a suggestion forwards its text to [onSuggestion], which the
/// chat screen wires to `controller.send(text)`.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, required this.onSuggestion});

  /// Invoked with a suggestion's text when the user taps a card.
  final void Function(String text) onSuggestion;

  /// Curated first-prompt suggestions (PRD §10: level, compare, top-N, alerts).
  static const List<_Suggestion> _suggestions = <_Suggestion>[
    _Suggestion(
      icon: Icons.water_drop_outlined,
      text: 'مستوى سد الموصل',
    ),
    _Suggestion(
      icon: Icons.compare_arrows_outlined,
      text: 'قارن سد الموصل وسد حديثة',
    ),
    _Suggestion(
      icon: Icons.leaderboard_outlined,
      text: 'أعلى 5 محطات اليوم',
    ),
    _Suggestion(
      icon: Icons.notifications_active_outlined,
      text: 'التنبيهات النشطة',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Cream color block — the one pastel "poster" panel of the section.
          ColorBlock(
            color: AppColors.blockCream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flat ink sparkle — the "generative" cue (kit is now flat).
                const GradientIcon(
                  icon: Icons.auto_awesome,
                  size: AppSpacing.xl,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Mono UPPERCASE eyebrow above the headline.
                Text('MĀ · AI', style: AppTextStyles.eyebrow),
                const SizedBox(height: AppSpacing.sm),
                // Big editorial ink headline.
                Text('مرحباً 👋', style: AppTextStyles.displayLg),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'كيف أساعدك بمناسيب المياه اليوم؟',
                  style: AppTextStyles.displayMd,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'اختر اقتراحاً للبدء، أو اكتب سؤالك بالعربية في الأسفل.',
                  style: AppTextStyles.bodyLg,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Mono eyebrow flagging the suggestion list.
          Text('اقتراحات', style: AppTextStyles.eyebrow),
          const SizedBox(height: AppSpacing.md),
          ..._suggestions.map(
            (s) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: _SuggestionCard(
                suggestion: s,
                onTap: () => onSuggestion(s.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single tappable suggestion rendered as a flat white hairline pill: a
/// leading ink icon, the prompt text, and a trailing arrow.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.hairline),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(suggestion.icon, color: AppColors.ink, size: AppSpacing.lg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  suggestion.text,
                  style: AppTextStyles.titleMd,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.arrow_outward,
                color: AppColors.ink,
                size: AppSpacing.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Immutable suggestion descriptor.
class _Suggestion {
  const _Suggestion({required this.icon, required this.text});

  final IconData icon;
  final String text;
}
