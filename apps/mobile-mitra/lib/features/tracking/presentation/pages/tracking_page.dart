import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/common/error_card.dart';
import '../../../../shared/widgets/loaders/card_skeleton.dart';
import '../../domain/entities/active_tracking.dart';
import '../cubit/tracking_cubit.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key, this.bookingId});

  final int? bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TrackingCubit>()..load(bookingId: bookingId),
      child: const _TrackingView(),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const _TrackingAppBar(),
      body: BlocBuilder<TrackingCubit, TrackingState>(
        builder: (context, state) {
          return switch (state) {
            TrackingLoading() || TrackingInitial() => const _LoadingMap(),
            TrackingError(:final message) => RefreshIndicator(
                onRefresh: context.read<TrackingCubit>().load,
                child: ListView(
                  padding: AppSpacing.screen,
                  children: [
                    ErrorCard(
                      message: message,
                      onRetry: context.read<TrackingCubit>().load,
                    ),
                  ],
                ),
              ),
            TrackingLoaded(:final tracking) => _TrackingMap(tracking: tracking),
            _ => const _UnknownState(),
          };
        },
      ),
    );
  }
}

// A real, interactive map needs tight/bounded layout constraints straight
// from the Scaffold body. Putting it inside a CustomScrollView/sliver (as
// this page did before) makes SliverFillRemaining query the map's intrinsic
// height, and flutter_map's internal LayoutBuilder explicitly rejects
// intrinsic-dimension queries -- hence why the app bar lives on Scaffold.appBar
// instead of as a SliverAppBar, and this is a plain Stack, not a sliver.
class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.tracking});

  final ActiveTracking tracking;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _OsmLiveMap(tracking: tracking),
        Positioned(
          left: AppSpacing.mobileMargin,
          right: AppSpacing.mobileMargin,
          top: AppSpacing.md,
          child: _StatusCard(tracking: tracking),
        ),
        Positioned(
          left: AppSpacing.mobileMargin,
          right: AppSpacing.mobileMargin,
          bottom: AppSpacing.lg,
          child: _NavigationCard(tracking: tracking),
        ),
      ],
    );
  }
}

class _TrackingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TrackingAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/orders'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        'Peta Tracking',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
      actions: [
        IconButton(
          onPressed: context.read<TrackingCubit>().load,
          icon: const Icon(Icons.my_location_rounded),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.tracking});

  final ActiveTracking tracking;

  @override
  Widget build(BuildContext context) {
    final distance = tracking.distanceKm <= 0
        ? 'Jarak belum tersedia'
        : '${tracking.distanceKm.toStringAsFixed(1)} km';
    final eta = tracking.etaMinutes <= 0
        ? 'ETA dihitung'
        : '${tracking.etaMinutes} menit';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: AppRadius.card,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFDDF8EA),
              child: Icon(Icons.route_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tracking.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${tracking.patientName} - $distance - $eta',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({required this.tracking});

  final ActiveTracking tracking;

  @override
  Widget build(BuildContext context) {
    final action = _trackingActionFor(tracking);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_trackingActionIcon(action), color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _trackingActionText(action),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            if (action != _TrackingAction.idle) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => _handleTrackingAction(context, action, tracking.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.control,
                    ),
                  ),
                  icon: Icon(_trackingActionButtonIcon(action)),
                  label: Text(_trackingActionButtonLabel(action)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleTrackingAction(
    BuildContext context,
    _TrackingAction action,
    int bookingId,
  ) {
    final cubit = context.read<TrackingCubit>();
    switch (action) {
      case _TrackingAction.arrive:
        cubit.markArrived(bookingId);
        break;
      case _TrackingAction.handle:
        cubit.startTreatment(bookingId);
        break;
      case _TrackingAction.finish:
        cubit.complete(bookingId);
        break;
      case _TrackingAction.idle:
        break;
    }
  }
}

class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: const Column(
        children: [
          CardSkeleton(height: 88),
          SizedBox(height: AppSpacing.md),
          CardSkeleton(height: 460),
        ],
      ),
    );
  }
}

class _UnknownState extends StatelessWidget {
  const _UnknownState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppSpacing.screen,
      child: ErrorCard(message: 'State tracking tidak dikenali.'),
    );
  }
}

/// Real, live-updating map rendered with free OpenStreetMap tiles.
/// The mitra marker follows the device GPS stream directly (no polling),
/// while the patient marker comes from the booking's saved address
/// coordinates.
class _OsmLiveMap extends StatefulWidget {
  const _OsmLiveMap({required this.tracking});

  final ActiveTracking tracking;

  @override
  State<_OsmLiveMap> createState() => _OsmLiveMapState();
}

class _OsmLiveMapState extends State<_OsmLiveMap> {
  static const _fallbackCenter = LatLng(-6.200000, 106.816666);

  /// Below this, the last fetched road route is still close enough to the
  /// mitra's new position that re-fetching isn't worth the extra request.
  static const _routeRefetchThresholdMeters = 40;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _mitraPosition;
  String? _locationError;
  bool _hasCentered = false;

  List<LatLng>? _routePoints;
  LatLng? _routeFetchedFrom;
  bool _isFetchingRoute = false;

  LatLng? get _patientPosition => widget.tracking.hasPatientLocation
      ? LatLng(widget.tracking.patientLatitude!, widget.tracking.patientLongitude!)
      : null;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setLocationError('Aktifkan layanan lokasi untuk live tracking.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setLocationError('Izin lokasi ditolak. Aktifkan untuk live tracking.');
      return;
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _onPosition(current);
    } catch (_) {
      // Fall through to the stream below; it will retry on its own.
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void _setLocationError(String message) {
    if (!mounted) return;
    setState(() => _locationError = message);
  }

  void _onPosition(Position position) {
    if (!mounted) return;
    setState(() {
      _mitraPosition = LatLng(position.latitude, position.longitude);
      _locationError = null;
    });

    if (!_hasCentered) {
      _hasCentered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }

    _maybeFetchRoute();
  }

  /// Fetches the actual road path from OSRM's free public routing API
  /// (no API key) instead of drawing a straight line between mitra and
  /// patient. Re-fetches only when the mitra has moved far enough from
  /// where the last route was drawn from, so a normal GPS update stream
  /// (every ~5m) doesn't hammer the public server.
  void _maybeFetchRoute() {
    final mitra = _mitraPosition;
    final patient = _patientPosition;
    if (mitra == null || patient == null || _isFetchingRoute) return;

    final lastOrigin = _routeFetchedFrom;
    if (lastOrigin != null &&
        Geolocator.distanceBetween(
              lastOrigin.latitude,
              lastOrigin.longitude,
              mitra.latitude,
              mitra.longitude,
            ) <
            _routeRefetchThresholdMeters) {
      return;
    }

    _fetchRoute(mitra, patient);
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    _isFetchingRoute = true;
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(const Duration(seconds: 10));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) return;

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || decoded['code'] != 'Ok') return;

      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return;

      final geometry = (routes.first as Map<String, dynamic>)['geometry'];
      final coordinates = geometry is Map<String, dynamic> ? geometry['coordinates'] : null;
      if (coordinates is! List || coordinates.isEmpty) return;

      final points = coordinates
          .whereType<List<dynamic>>()
          .where((point) => point.length >= 2)
          .map((point) => LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()))
          .toList();

      if (!mounted || points.isEmpty) return;
      setState(() {
        _routePoints = points;
        _routeFetchedFrom = from;
      });
    } catch (_) {
      // OSRM's free demo server can be flaky/rate-limited -- the map just
      // keeps drawing the straight line between mitra and patient instead.
    } finally {
      _isFetchingRoute = false;
      client.close(force: true);
    }
  }

  void _fitBounds() {
    final mitra = _mitraPosition;
    final patient = _patientPosition;
    if (mitra == null) return;

    if (patient == null) {
      _mapController.move(mitra, 15);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([mitra, patient]),
        padding: const EdgeInsets.fromLTRB(56, 140, 56, 240),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mitra = _mitraPosition;
    final patient = _patientPosition;

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mitra ?? patient ?? _fallbackCenter,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.perawatku.mitra',
            ),
            if (mitra != null && patient != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints ?? [mitra, patient],
                    strokeWidth: 4,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (mitra != null)
                  Marker(
                    point: mitra,
                    width: 42,
                    height: 42,
                    child: const _MapPin(color: AppColors.primary, icon: Icons.motorcycle_rounded),
                  ),
                if (patient != null)
                  Marker(
                    point: patient,
                    width: 42,
                    height: 42,
                    child: const _MapPin(color: AppColors.error, icon: Icons.person_pin_circle_rounded),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
        if (mitra == null)
          Positioned(
            left: AppSpacing.mobileMargin,
            right: AppSpacing.mobileMargin,
            top: AppSpacing.md + 88,
            child: _MapNoticeBanner(
              message: _locationError ?? 'Mencari lokasi GPS Anda...',
              isError: _locationError != null,
            ),
          ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _MapNoticeBanner extends StatelessWidget {
  const _MapNoticeBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isError ? AppColors.error : Colors.black87).withValues(alpha: 0.85),
        borderRadius: AppRadius.control,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.location_disabled_rounded : Icons.gps_fixed_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TrackingAction {
  arrive,
  handle,
  finish,
  idle,
}

_TrackingAction _trackingActionFor(ActiveTracking tracking) {
  if (tracking.status.toLowerCase() != 'on_the_way') {
    return tracking.hasActiveService ? _TrackingAction.idle : _TrackingAction.idle;
  }

  if (!_hasHistory(tracking, 'arrival')) return _TrackingAction.arrive;
  if (!_hasHistory(tracking, 'treatment_started')) return _TrackingAction.handle;
  return _TrackingAction.finish;
}

bool _hasHistory(ActiveTracking tracking, String marker) {
  final normalizedMarker = marker.toLowerCase();
  final readableMarker = normalizedMarker.replaceAll('_', ' ');
  return tracking.histories.any((history) {
    final treatmentType = history.treatmentType.toLowerCase();
    final title = history.title.toLowerCase();
    final notes = history.notes.toLowerCase();
    return treatmentType == normalizedMarker ||
        title.contains(readableMarker) ||
        notes.contains(readableMarker) ||
        (normalizedMarker == 'arrival' &&
            (title.contains('sampai') || title.contains('tiba'))) ||
        (normalizedMarker == 'treatment_started' &&
            title.contains('penanganan'));
  });
}

String _trackingActionText(_TrackingAction action) {
  return switch (action) {
    _TrackingAction.arrive => 'Live map aktif. Tandai jika Anda sudah tiba.',
    _TrackingAction.handle => 'Anda sudah sampai. Mulai tangani pasien terlebih dahulu.',
    _TrackingAction.finish => 'Penanganan sedang berjalan. Selesaikan setelah layanan selesai.',
    _TrackingAction.idle => 'Belum ada perjalanan aktif',
  };
}

String _trackingActionButtonLabel(_TrackingAction action) {
  return switch (action) {
    _TrackingAction.arrive => 'Saya Sudah Sampai',
    _TrackingAction.handle => 'Tangani Pasien',
    _TrackingAction.finish => 'Selesaikan Layanan',
    _TrackingAction.idle => 'Tidak Ada Aksi',
  };
}

IconData _trackingActionIcon(_TrackingAction action) {
  return switch (action) {
    _TrackingAction.arrive => Icons.near_me_rounded,
    _TrackingAction.handle => Icons.medical_information_outlined,
    _TrackingAction.finish => Icons.task_alt_rounded,
    _TrackingAction.idle => Icons.info_outline_rounded,
  };
}

IconData _trackingActionButtonIcon(_TrackingAction action) {
  return switch (action) {
    _TrackingAction.arrive => Icons.location_on_outlined,
    _TrackingAction.handle => Icons.healing_outlined,
    _TrackingAction.finish => Icons.check_circle_outline_rounded,
    _TrackingAction.idle => Icons.info_outline_rounded,
  };
}
