import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
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
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: AppColors.teal,
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
          ),
          SizedBox(
            height: _mapHeight,
            child: _buildMap(),
          ),
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

/// A tappable water-drop pin tinted with a station's status colour.
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
        children: [
          Icon(
            Icons.location_on,
            size: 40,
            color: color,
            shadows: const [
              Shadow(
                color: Color(0x33000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          Positioned(
            top: 7,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop,
                size: 10,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
