import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/di/providers.dart';
import 'package:ma_water/data/models/alert.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/ui/genui_blocks/alert_card_block.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/shared/empty_state.dart';
import 'package:ma_water/ui/shared/shimmer.dart';
import 'package:ma_water/ui/station_detail/station_detail_screen.dart';

/// Full-screen list of open anomaly alerts.
///
/// Watches [alertsProvider] and renders each [Alert] as a severity-coded,
/// tappable [AlertCardBlock] (built from an [AlertCardSpec]). Tapping a card
/// opens the [StationDetailScreen] for the alert's station. Shows a loading
/// skeleton while detection runs and a friendly empty state when no alerts
/// are open.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('التنبيهات', style: AppTextStyles.titleLg),
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      body: alertsAsync.when(
        loading: () => const _AlertsLoading(),
        error: (_, _) => const EmptyState(
          icon: Icons.check_circle_outline,
          title: 'لا توجد تنبيهات حالياً',
          subtitle: 'كل المحطات ضمن المعدّل الطبيعي.',
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'لا توجد تنبيهات حالياً',
              subtitle: 'كل المحطات ضمن المعدّل الطبيعي.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            // +1 leading slot for the editorial eyebrow/count header.
            itemCount: alerts.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AlertsHeader(count: alerts.length);
              }
              final alert = alerts[index - 1];
              return AlertCardBlock(
                spec: _specFor(alert),
                onTap: () => _openStation(context, alert.stationId),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds an [AlertCardSpec] from an [Alert]: the Arabic message becomes the
  /// title and the relative detection time becomes the supporting body.
  AlertCardSpec _specFor(Alert alert) {
    return AlertCardSpec(
      severity: alert.severity,
      title: alert.messageAr,
      body: relativeArabic(alert.detectedAt),
      stationId: alert.stationId,
    );
  }

  void _openStation(BuildContext context, String stationId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StationDetailScreen(stationId: stationId),
      ),
    );
  }
}

/// Editorial list header: a small mono uppercase eyebrow ("ALERTS") flagging
/// the section as taxonomy, a bold Arabic heading, and a quiet mono caption
/// counting the open alerts. Flat ink-on-canvas — no card, no shadow.
class _AlertsHeader extends StatelessWidget {
  const _AlertsHeader({required this.count});

  /// Number of open alerts currently shown in the list.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xxs,
        end: AppSpacing.xxs,
        bottom: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALERTS',
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'التنبيهات المفتوحة',
            style: AppTextStyles.displayMd,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$count تنبيه نشط',
            style: AppTextStyles.caption.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder: a shimmering [ListSkeleton] standing in for the alert
/// cards that are about to appear, in the same padded scroll region.
class _AlertsLoading extends StatelessWidget {
  const _AlertsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: const [
        ListSkeleton(),
      ],
    );
  }
}
