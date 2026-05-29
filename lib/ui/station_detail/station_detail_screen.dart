import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/di/providers.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/data/models/reading.dart';
import 'package:ma_water/data/models/repo_types.dart';
import 'package:ma_water/data/models/station.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';
import 'package:ma_water/ui/genui_blocks/line_chart_block.dart';
import 'package:ma_water/ui/shared/empty_state.dart';
import 'package:ma_water/ui/shared/shimmer.dart';
import 'package:ma_water/ui/shared/status_pill.dart';

/// Bundles everything the detail screen needs for a single station so the UI
/// can resolve it with one [FutureProvider] state instead of juggling three.
class _StationDetailData {
  const _StationDetailData({
    required this.station,
    required this.readings,
    required this.current,
  });

  final Station station;
  final List<WaterLevelReading> readings;
  final CurrentLevel current;
}

/// Loads the station, its last-30-days history and its current level for the
/// detail screen. Returns `null` station data when the id is unknown so the UI
/// can render an [EmptyState] rather than throwing.
final _stationDetailProvider =
    FutureProvider.family<_StationDetailData?, String>((ref, stationId) async {
  final repo = ref.read(waterStationRepositoryProvider);
  final station = await repo.getStationById(stationId);
  if (station == null) return null;

  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 30));
  final readingsFuture = repo.getHistory(
    stationId: stationId,
    from: from,
    to: now,
    interval: ReadingInterval.day,
  );
  final currentFuture = repo.getCurrentLevel(stationId);

  return _StationDetailData(
    station: station,
    readings: await readingsFuture,
    current: await currentFuture,
  );
});

/// Full-screen detail view for a single water-level station.
///
/// Shows a header card (name, water body + governorate, status, meta chips), a
/// 30-day line chart with danger thresholds, and a primary call-to-action that
/// prefills the chat composer with a question about this station and returns to
/// the chat.
class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_stationDetailProvider(stationId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text('تفاصيل المحطة', style: AppTextStyles.titleLg),
          backgroundColor: AppColors.canvas,
          surfaceTintColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const Border(
            bottom: BorderSide(color: AppColors.hairline),
          ),
        ),
        body: dataAsync.when(
          loading: () => const _DetailLoading(),
          error: (_, _) => const EmptyState(
            icon: Icons.cloud_off,
            title: 'تعذّر تحميل بيانات المحطة',
            subtitle: 'حدث خطأ أثناء جلب البيانات. حاول مرة أخرى.',
          ),
          data: (data) {
            if (data == null) {
              return const EmptyState(
                icon: Icons.location_off,
                title: 'المحطة غير موجودة',
                subtitle: 'لم نعثر على محطة بهذا المعرّف.',
              );
            }
            return _DetailBody(data: data);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.data});

  final _StationDetailData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = data.station;

    final spec = LineChartSpec(
      title: 'مستوى الماء — آخر 30 يوماً',
      stationId: station.id,
      points: [
        for (final r in data.readings)
          TimePoint(t: r.timestamp, v: r.levelM),
      ],
      dangerHigh: station.dangerHighM,
      dangerLow: station.dangerLowM,
    );

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            // Leave room for the pinned bottom CTA.
            AppSpacing.xxl + AppSpacing.xl,
          ),
          children: [
            _HeaderCard(station: station, current: data.current),
            const SizedBox(height: AppSpacing.md),
            LineChartBlock(spec: spec),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: _AskButtonBar(station: station),
        ),
      ],
    );
  }
}

/// Loading placeholder shown while the station/history futures resolve.
///
/// Mirrors [_DetailBody]'s layout (same [ListView] padding) so content does not
/// jump on load: a header-card-sized [ShimmerBox] followed by a [ChartSkeleton]
/// standing in for the 30-day line chart. No CTA bar is shown until a real
/// station is available to prefill the composer with.
class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl + AppSpacing.xl,
      ),
      children: [
        ShimmerBox(
          height: 150,
          radius: BorderRadius.circular(AppRadius.lg),
        ),
        const SizedBox(height: AppSpacing.md),
        const ChartSkeleton(),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.station, required this.current});

  final Station station;
  final CurrentLevel current;

  @override
  Widget build(BuildContext context) {
    final installed = DateFormat('yyyy/MM/dd', 'en').format(station.installedAt);
    final coords =
        '${station.latitude.toStringAsFixed(4)}، ${station.longitude.toStringAsFixed(4)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Editorial eyebrow + status, set in small uppercase mono taxonomy.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'محطة قياس',
                  style: AppTextStyles.eyebrow,
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(status: current.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Oversized editorial name — weight carries the hierarchy.
          Text(
            station.nameAr,
            style: AppTextStyles.displayMd,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${station.waterBodyAr} • ${station.governorateAr}',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.slate),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(
                icon: Icons.tag,
                label: 'المحطة رقم ${station.number}',
              ),
              _MetaChip(
                icon: _bodyTypeIcon(station.bodyType),
                label: _bodyTypeLabelAr(station.bodyType),
              ),
              _MetaChip(
                icon: Icons.event,
                label: 'التأسيس $installed',
              ),
              _MetaChip(
                icon: Icons.place_outlined,
                label: coords,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md, color: AppColors.ink),
          const SizedBox(width: AppSpacing.xxs + 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _AskButtonBar extends ConsumerWidget {
  const _AskButtonBar({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: _AskPillButton(
          label: 'اسأل عن هذه المحطة',
          icon: Icons.chat_bubble_outline,
          onPressed: () {
            ref.read(composerPrefillProvider.notifier).state =
                'ما هو مستوى المياه في ${station.nameAr}؟';
            Navigator.of(context).maybePop();
          },
        ),
      ),
    );
  }
}

/// The primary call-to-action: a flat black pill (ink background, canvas-white
/// label + icon) per the Figma `button-primary` — no gradient, no shadow, just
/// solid ink with [AppRadius.pill] corners.
class _AskPillButton extends StatelessWidget {
  const _AskPillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.sm + AppSpacing.xxs,
            horizontal: AppSpacing.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.canvas, size: AppSpacing.lg),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.titleMd.copyWith(color: AppColors.canvas),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _bodyTypeLabelAr(WaterBodyType type) {
  switch (type) {
    case WaterBodyType.river:
      return 'نهر';
    case WaterBodyType.dam:
      return 'سد';
    case WaterBodyType.lake:
      return 'بحيرة';
    case WaterBodyType.tributary:
      return 'رافد';
  }
}

IconData _bodyTypeIcon(WaterBodyType type) {
  switch (type) {
    case WaterBodyType.river:
      return Icons.water;
    case WaterBodyType.dam:
      return Icons.water_damage_outlined;
    case WaterBodyType.lake:
      return Icons.waves;
    case WaterBodyType.tributary:
      return Icons.call_split;
  }
}
