import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Severity-coded alert card rendered inside the chat GenUI stream.
///
/// Tinted by [AlertCardSpec.severity], with a leading warning icon, bold
/// Arabic [AlertCardSpec.title], supporting [AlertCardSpec.body], and an
/// optional italic AI note line prefixed with a subtle label. Tappable when
/// [onTap] is supplied (e.g. to open the related station).
class AlertCardBlock extends StatelessWidget {
  final AlertCardSpec spec;
  final VoidCallback? onTap;

  const AlertCardBlock({
    super.key,
    required this.spec,
    this.onTap,
  });

  /// Foreground accent color for a given alert [severity].
  static Color _accentColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return AppColors.ok;
      case AlertSeverity.warning:
        return AppColors.warn;
      case AlertSeverity.critical:
        return AppColors.danger;
    }
  }

  /// Background (tint) color for a given alert [severity].
  static Color _backgroundColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return AppColors.okBg;
      case AlertSeverity.warning:
        return AppColors.warnBg;
      case AlertSeverity.critical:
        return AppColors.dangerBg;
    }
  }

  /// Leading icon for a given alert [severity].
  static IconData _iconFor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.critical:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(spec.severity);
    final background = _backgroundColor(spec.severity);
    final aiNote = spec.aiNote;

    final card = Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconFor(spec.severity),
            color: accent,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  style: AppTextStyles.titleLg.copyWith(color: accent),
                ),
                if (spec.body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    spec.body,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                  ),
                ],
                if (aiNote != null && aiNote.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _AiNote(note: aiNote),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: card,
      ),
    );
  }
}

/// Subtle italic AI commentary line, prefixed with a quiet Arabic label.
class _AiNote extends StatelessWidget {
  final String note;

  const _AiNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.slate,
          fontStyle: FontStyle.italic,
        ),
        children: [
          TextSpan(
            text: 'ملاحظة الذكاء: ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.slate,
              fontStyle: FontStyle.italic,
            ),
          ),
          TextSpan(text: note),
        ],
      ),
    );
  }
}
