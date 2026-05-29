import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// Gemini-style empty state for the chat: a large gradient greeting, a sparkle
/// accent, and a few tappable suggestion cards that seed the first question.
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
          const SizedBox(height: AppSpacing.xl),
          // Sparkle accent — the Gemini "generative" cue, full-spectrum rainbow.
          const GradientIcon(
            icon: Icons.auto_awesome,
            size: AppSpacing.xxl,
            gradient: AppColors.rainbowGradient,
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientText(
            'مرحباً 👋',
            style: AppTextStyles.displayLg,
          ),
          const SizedBox(height: AppSpacing.xs),
          GradientText(
            'كيف أساعدك بمناسيب المياه اليوم؟',
            style: AppTextStyles.displayMd,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'اختر اقتراحاً للبدء، أو اكتب سؤالك بالعربية في الأسفل.',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.xl),
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

/// A single tappable suggestion: a leading icon, the prompt text, and a chevron.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(suggestion.icon, color: AppColors.teal, size: AppSpacing.lg),
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
                color: AppColors.slate,
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
