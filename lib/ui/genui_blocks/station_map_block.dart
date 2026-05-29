import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/utils/arabic_utils.dart';
import 'package:ma_water/data/models/enums.dart';
import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Renders a [StationMapSpec] as a GenUI card containing an OpenStreetMap
/// view with one status-coloured water-drop marker per station.
///
/// The camera auto-fits to the supplied markers; when no markers are present
/// it falls back to a sane view centred on Iraq. Tapping a marker invokes
/// [onTapMarker] with the station id.
class StationMapBlock extends StatefulWidget {
  const StationMapBlock({
    super.key,
    required this.spec,
    this.onTapMarker,
  });

  final StationMapSpec spec;
  final void Function(String stationId)? onTapMarker;

  @override
  State<StationMapBlock> createState() => _StationMapBlockState();
}

class _StationMapBlockState extends State<StationMapBlock> {
  /// Default camera centred on Iraq when no markers are available.
  static const LatLng _iraqCenter = LatLng(33.2, 43.7);
  static const double _iraqZoom = 6;

  /// Map height per spec (~280).
  static const double _mapHeight = 280;

  final MapController _mapController = MapController();

  List<LatLng> get _points => widget.spec.markers
      .map((m) => LatLng(m.lat, m.lng))
      .toList(growable: false);

  /// Fit the camera to the marker bounds once the map is ready.
  void _fitToMarkers() {
    final points = _points;
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 9);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(AppSpacing.xl),
        maxZoom: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small mono uppercase eyebrow flagging the block type.
                Text(
                  'STATIONS MAP',
                  style: AppTextStyles.eyebrow,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        widget.spec.title,
                        style: AppTextStyles.titleMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: _mapHeight,
            child: _buildMap(),
          ),
          const _StatusLegend(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final markers = widget.spec.markers;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _iraqCenter,
        initialZoom: _iraqZoom,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: _fitToMarkers,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mawater',
        ),
        MarkerLayer(
          markers: [
            for (final marker in markers)
              Marker(
                point: LatLng(marker.lat, marker.lng),
                width: 40,
                height: 48,
                alignment: Alignment.topCenter,
                child: _StationDropMarker(
                  color: AppColors.statusColor(marker.status),
                  onTap: widget.onTapMarker == null
                      ? null
                      : () => widget.onTapMarker!(marker.stationId),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A tappable, monochrome ink water-drop pin carrying a station's status as a
/// single colour accent.
///
/// FLAT, editorial: a solid ink teardrop (no drop shadow) sits over a status-
/// tinted hairline ring, with a white inset disc that holds the status-coloured
/// water-drop glyph. Ink does the heavy lifting against busy map tiles; the
/// status colour is the one accent so it stays unmistakable.
class _StationDropMarker extends StatelessWidget {
  const _StationDropMarker({
    required this.color,
    this.onTap,
  });

  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Status-tinted pastel-block disc + hairline ring for legibility.
          Positioned(
            top: 2,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
                border: Border.all(color: color, width: 1),
              ),
            ),
          ),
          // Flat ink teardrop pin (no shadow).
          const Icon(
            Icons.location_on,
            size: 42,
            color: AppColors.ink,
          ),
          // White inset disc carrying the status-coloured water-drop glyph.
          Positioned(
            top: 7,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop,
                size: 11,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact legend mapping the three station statuses to their accent colour
/// and Arabic label (طبيعي / تحذير / خطر), rendered as flat hairline chips.
class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          border: BorderDirectional(
            top: BorderSide(color: AppColors.hairline),
          ),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: const [
            _LegendItem(status: StationStatus.normal),
            _LegendItem(status: StationStatus.warning),
            _LegendItem(status: StationStatus.danger),
          ],
        ),
      ),
    );
  }
}

/// A single flat legend chip: a status-accent dot beside a mono uppercase
/// caption label, on a soft surface with a hairline border (pill shape).
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.status});

  final StationStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.sm,
        AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status accent dot.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            statusLabelAr(status),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
