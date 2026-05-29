import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/design/color_block.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Severity-coded alert card rendered inside the chat GenUI stream.
///
/// Rendered as a flat pastel **color block** (the signature surface of the
/// "Mā" design system) keyed by [AlertCardSpec.severity] — pink for critical,
/// coral for warning, lime for info. A small mono uppercase eyebrow ("تنبيه")
/// flags the block as an alert, above a bold Arabic [AlertCardSpec.title],
/// supporting [AlertCardSpec.body], and an optional AI note line. Ink text
/// throughout (weight, not gray, carries hierarchy). Tappable when [onTap] is
/// supplied (e.g. to open the related station).
class AlertCardBlock extends StatelessWidget {
  final AlertCardSpec spec;
  final VoidCallback? onTap;

  const AlertCardBlock({
    super.key,
    required this.spec,
    this.onTap,
  });

  /// Pastel color-block surface for a given alert [severity].
  static Color _blockColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return AppColors.blockLime;
      case AlertSeverity.warning:
        return AppColors.blockCoral;
      case AlertSeverity.critical:
        return AppColors.blockPink;
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
    final aiNote = spec.aiNote;

    final card = ColorBlock(
      color: _blockColor(spec.severity),
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mono uppercase eyebrow with the severity glyph — taxonomy marker.
          Row(
            children: [
              Icon(
                _iconFor(spec.severity),
                color: AppColors.ink,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'تنبيه',
                style: AppTextStyles.eyebrow.copyWith(color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            spec.title,
            style: AppTextStyles.titleLg.copyWith(color: AppColors.ink),
          ),
          if (spec.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              spec.body,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
            ),
          ],
          if (aiNote != null && aiNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _AiNote(note: aiNote),
          ],
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

/// Subtle italic AI commentary line, prefixed with a quiet mono Arabic label.
class _AiNote extends StatelessWidget {
  final String note;

  const _AiNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.ink,
          fontStyle: FontStyle.italic,
        ),
        children: [
          TextSpan(
            text: 'ملاحظة الذكاء: ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.ink,
            ),
          ),
          TextSpan(text: note),
        ],
      ),
    );
  }
}
