import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';

/// A persistent, horizontally-scrollable row of quick prompt chips shown
/// directly above the composer in every chat state (Gemini-style quick
/// suggestions). Tapping a chip sends that prompt via [onSelect].
///
/// Disabled (dimmed, non-tappable) while a reply is being generated so the user
/// can't fire overlapping requests.
class QuickSuggestionsBar extends StatelessWidget {
  const QuickSuggestionsBar({
    super.key,
    required this.onSelect,
    this.enabled = true,
  });

  final void Function(String prompt) onSelect;
  final bool enabled;

  /// Curated quick prompts spanning the main capabilities.
  static const List<_Suggestion> _suggestions = <_Suggestion>[
    _Suggestion('مستوى سد الموصل', Icons.water_drop_outlined),
    _Suggestion('قارن سد الموصل وسد حديثة', Icons.compare_arrows),
    _Suggestion('أعلى 5 محطات', Icons.leaderboard_outlined),
    _Suggestion('إحصائيات سد الموصل', Icons.insights_outlined),
    _Suggestion('التنبيهات النشطة', Icons.notifications_active_outlined),
    _Suggestion('اعرض الخريطة', Icons.map_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
        ),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _SuggestionChip(
            suggestion: suggestion,
            onTap: enabled ? () => onSelect(suggestion.prompt) : null,
          );
        },
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion(this.prompt, this.icon);
  final String prompt;
  final IconData icon;
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.suggestion, this.onTap});

  final _Suggestion suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    // Secondary pill: flat white canvas + 1px hairline + ink text/icon.
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(suggestion.icon, size: 16, color: AppColors.ink),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  suggestion.prompt,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
