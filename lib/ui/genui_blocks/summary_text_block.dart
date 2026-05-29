import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Renders a [SummaryTextSpec] — the plain-prose fallback block — inside a
/// standard GenUI card. Used for greetings, definitions, and any AI answer
/// that has no better structured representation.
class SummaryTextBlock extends StatelessWidget {
  final SummaryTextSpec spec;

  const SummaryTextBlock({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        spec.text,
        style: AppTextStyles.bodyLg,
        textAlign: TextAlign.start,
      ),
    );
  }
}
