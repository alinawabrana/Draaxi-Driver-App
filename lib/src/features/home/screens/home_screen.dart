import 'dart:async';
import 'dart:ui' as ui;

import 'package:draaxi_driver/src/features/authentication/service/user_service.dart';
import 'package:draaxi_driver/src/features/home/service/driver_api_service.dart';
import 'package:draaxi_driver/src/features/wallet/service/wallet_store.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:draaxi_driver/src/common/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _DummyRideRequest {
  const _DummyRideRequest({
    required this.id,
    required this.requestId,
    this.offerId,
    this.offerStatus,
    this.requestStatus,
    this.hasAcceptedDriver = false,
    required this.riderName,
    this.riderPhone,
    required this.fromLocation,
    required this.toLocation,
    required this.distanceKm,
    required this.etaMinutes,
    required this.suggestedFare,
    required this.serviceAmount,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    this.ttlSeconds,
  });

  final String id;
  final String requestId;
  final String? offerId;
  final String? offerStatus;
  final String? requestStatus;
  final bool hasAcceptedDriver;
  final String riderName;
  final String? riderPhone;
  final String fromLocation;
  final String toLocation;
  final double distanceKm;
  final int etaMinutes;
  final double suggestedFare;
  final double serviceAmount;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
  final int? ttlSeconds;

  static String? _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static double? _pickDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static int? _pickInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _pickDoubleFromSources(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      final value = _pickDouble(source, keys);
      if (value != null) return value;
    }
    return null;
  }

  static _DummyRideRequest? fromApi(Map<String, dynamic> raw) {
    final pickupAlt = (raw['pickup_location'] is Map<String, dynamic>)
        ? raw['pickup_location'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final dropoffAlt = (raw['dropoff_location'] is Map<String, dynamic>)
        ? raw['dropoff_location'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final pickup = (raw['pickup'] is Map<String, dynamic>)
        ? raw['pickup'] as Map<String, dynamic>
        : pickupAlt;
    final dropoff = (raw['dropoff'] is Map<String, dynamic>)
        ? raw['dropoff'] as Map<String, dynamic>
        : dropoffAlt;
    final rider = (raw['rider'] is Map<String, dynamic>)
        ? raw['rider'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final pricing = (raw['pricing'] is Map<String, dynamic>)
        ? raw['pricing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final fareBreakdown = (raw['fare_breakdown'] is Map<String, dynamic>)
        ? raw['fare_breakdown'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final charges = (raw['charges'] is Map<String, dynamic>)
        ? raw['charges'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final sources = <Map<String, dynamic>>[raw, pricing, fareBreakdown, charges];

    final requestId =
        _pickString(raw, ['request_id', 'ride_id', 'id']) ??
        _pickInt(raw, ['request_id', 'ride_id', 'id'])?.toString();
    if (requestId == null || requestId.isEmpty) return null;
    final offerId =
        _pickString(raw, ['offer_id']) ??
        _pickInt(raw, ['offer_id'])?.toString();
    final offerStatus = _pickString(raw, ['status', 'offer_status']);
    final requestStatus = _pickString(raw, ['request_status']);
    final rawHasAcceptedDriver = raw['has_accepted_driver'];
    final hasAcceptedDriver = rawHasAcceptedDriver is bool
        ? rawHasAcceptedDriver
        : rawHasAcceptedDriver is num
        ? rawHasAcceptedDriver == 1
        : rawHasAcceptedDriver is String
        ? rawHasAcceptedDriver.trim().toLowerCase() == 'true' ||
              rawHasAcceptedDriver.trim() == '1'
        : false;

    final fromLat =
        _pickDouble(pickup, ['lat', 'latitude']) ??
        _pickDouble(pickupAlt, ['lat', 'latitude']) ??
        _pickDouble(raw, ['pickup_lat', 'pickup_latitude', 'from_lat']);
    final fromLng =
        _pickDouble(pickup, ['lng', 'lon', 'longitude']) ??
        _pickDouble(pickupAlt, ['lng', 'lon', 'longitude']) ??
        _pickDouble(raw, ['pickup_lng', 'pickup_longitude', 'from_lng']);
    final toLat =
        _pickDouble(dropoff, ['lat', 'latitude']) ??
        _pickDouble(dropoffAlt, ['lat', 'latitude']) ??
        _pickDouble(raw, ['dropoff_lat', 'dropoff_latitude', 'to_lat']);
    final toLng =
        _pickDouble(dropoff, ['lng', 'lon', 'longitude']) ??
        _pickDouble(dropoffAlt, ['lng', 'lon', 'longitude']) ??
        _pickDouble(raw, ['dropoff_lng', 'dropoff_longitude', 'to_lng']);

    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
      return null;
    }

    final fromAddress =
        _pickString(pickup, ['address', 'name']) ??
        _pickString(raw, ['pickup_address', 'from_location', 'from']);
    final toAddress =
        _pickString(dropoff, ['address', 'name']) ??
        _pickString(raw, ['dropoff_address', 'to_location', 'to']);
    final riderName =
        _pickString(rider, ['name']) ??
        _pickString(raw, ['rider_name', 'customer_name']) ??
        'Rider';
    final riderPhone =
        _pickString(rider, ['phone']) ?? _pickString(raw, ['rider_phone']);

    final distanceKm =
        _pickDouble(raw, ['distance_km', 'distance']) ??
        (Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng) / 1000);
    final etaMinutes =
        _pickInt(raw, ['eta_min', 'duration_min', 'eta_minutes']) ??
        (((distanceKm / 30) * 60).ceil()).clamp(1, 120);
    final fare =
        _pickDoubleFromSources(sources, [
          'suggested_fare',
          'fare',
          'offered_fare',
          'final_fare',
          'total_fare',
          'amount',
        ]) ??
        0;
    final servicePercent = _pickDoubleFromSources(sources, [
      'service_percentage',
      'service_percent',
      'commission_percentage',
      'platform_fee_percentage',
    ]);
    final serviceAmount =
        _pickDoubleFromSources(sources, [
          'service_amount',
          'service_fee',
          'service_charge',
          'platform_fee',
          'commission',
          'commission_amount',
          'admin_commission',
          'driver_service_fee',
        ]) ??
        (servicePercent != null && fare > 0 ? (fare * servicePercent) / 100 : 0);

    return _DummyRideRequest(
      id: 'RQ-$requestId',
      requestId: requestId,
      offerId: offerId,
      offerStatus: offerStatus,
      requestStatus: requestStatus,
      hasAcceptedDriver: hasAcceptedDriver,
      riderName: riderName,
      riderPhone: riderPhone,
      fromLocation: fromAddress ?? 'Pickup',
      toLocation: toAddress ?? 'Dropoff',
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      suggestedFare: fare,
      serviceAmount: serviceAmount,
      fromLatitude: fromLat,
      fromLongitude: fromLng,
      toLatitude: toLat,
      toLongitude: toLng,
      ttlSeconds:
          _pickInt(raw, ['ttl_seconds', 'ttl', 'expires_in']) ??
          _pickInt(raw, ['remaining_seconds']),
    );
  }
}

enum _RidePhase { toRider, toDestination }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _defaultTarget = LatLng(30.1575, 71.5249);
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#1f1f1f"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#383838"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#343434"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#7a7a7a"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f2f2f"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';
  static const String _lightMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#efefef"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6e6e6e"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#fbfbfb"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#7a7a7a"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9c9c9"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}
]
  ''';

  final UserService _userService = UserService();
  final DriverApiService _driverApiService = DriverApiService();
  static const int _requestTimeoutSeconds = 15;

  bool _hasCheckedProfile = false;
  bool _hasResolvedStartupState = false;
  bool _isLoadingProfile = false;
  Map<String, dynamic>? _userData;
  bool _isOnline = false;
  bool? _profileCompletedFromStatus;
  bool? _isApprovedFromStatus;
  bool _isFetchingRequests = false;
  bool _isSubmittingRideAction = false;
  List<_DummyRideRequest> _backendRideRequests = const [];
  List<_DummyRideRequest> _visibleRideRequests = const [];
  Map<String, int> _requestRemainingSeconds = const {};
  Timer? _requestCountdownTimer;
  Timer? _pendingRequestsPollingTimer;
  Timer? _locationSyncTimer;
  Timer? _activeRidePollingTimer;
  Timer? _startupRetryTimer;
  _DummyRideRequest? _acceptedRide;
  _DummyRideRequest? _awaitingRiderRequest;
  String? _activeRideId;
  bool _isRideInNavigation = false;
  _RidePhase _ridePhase = _RidePhase.toRider;
  bool _hasReachedRider = false;
  bool _pickupMarkedOnServer = false;
  bool _isNavigationMuted = true;
  double? _rideRemainingDistanceKm;
  int? _rideRemainingEtaMinutes;
  bool _hasReachedDestination = false;
  GoogleMapController? _mapController;
  BitmapDescriptor? _currentLocationIcon;
  LatLng? _currentLatLng;
  Set<Marker> _markers = const <Marker>{};
  Set<Circle> _circles = const <Circle>{};
  Set<Polyline> _polylines = const <Polyline>{};

  List<_DummyRideRequest> get _nearbyRideRequests {
    final current = _currentLatLng;
    if (current == null) return _backendRideRequests;

    return _backendRideRequests.where((request) {
      final km =
          Geolocator.distanceBetween(
            current.latitude,
            current.longitude,
            request.fromLatitude,
            request.fromLongitude,
          ) /
          1000;
      return km <= 3;
    }).toList(growable: false);
  }

  bool _isAwaitingRiderConfirmation(_DummyRideRequest request) {
    final offerStatus = request.offerStatus?.trim().toLowerCase();
    final requestStatus = request.requestStatus?.trim().toLowerCase();
    return request.hasAcceptedDriver ||
        offerStatus == 'driver_accepted' ||
        requestStatus == 'driver_accepted' ||
        requestStatus == 'driver_offered';
  }

  int _initialCountdownForRequest(_DummyRideRequest request) {
    final ttl = request.ttlSeconds;
    if (ttl == null || ttl <= 0) return _requestTimeoutSeconds;
    return ttl > _requestTimeoutSeconds ? _requestTimeoutSeconds : ttl;
  }

  void _startRequestCountdownTicker() {
    _requestCountdownTimer?.cancel();
    _requestCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isOnline) {
        _requestCountdownTimer?.cancel();
        return;
      }
      if (_visibleRideRequests.isEmpty) return;

      final expiredIds = <String>[];
      final updated = Map<String, int>.from(_requestRemainingSeconds);

      for (final request in _visibleRideRequests) {
        final current = updated[request.id] ?? _requestTimeoutSeconds;
        final next = current - 1;
        if (next <= 0) {
          expiredIds.add(request.id);
          updated.remove(request.id);
        } else {
          updated[request.id] = next;
        }
      }

      setState(() {
        _requestRemainingSeconds = updated;
      });

      for (final id in expiredIds) {
        _removeRideRequestById(id);
      }
    });
  }

  void _fillVisibleRideRequests() {
    final candidates = _nearbyRideRequests;
    if (candidates.isEmpty) {
      _visibleRideRequests = const [];
      _requestRemainingSeconds = const {};
      return;
    }

    final maxVisible = candidates.length < 3 ? candidates.length : 3;
    final current = candidates.take(maxVisible).toList(growable: false);

    final countdowns = Map<String, int>.from(_requestRemainingSeconds);
    countdowns.removeWhere((key, _) => !current.any((item) => item.id == key));
    for (final request in current) {
      countdowns.putIfAbsent(
        request.id,
        () => _initialCountdownForRequest(request),
      );
    }

    _visibleRideRequests = current;
    _requestRemainingSeconds = countdowns;
  }

  void _startRequestCards() {
    setState(() {
      _visibleRideRequests = const [];
      _requestRemainingSeconds = const {};
      _fillVisibleRideRequests();
    });
    _startRequestCountdownTicker();
  }

  void _stopRequestCards() {
    _requestCountdownTimer?.cancel();
    setState(() {
      _visibleRideRequests = const [];
      _requestRemainingSeconds = const {};
    });
  }

  void _removeRideRequestById(String requestId) {
    if (!mounted || !_isOnline) return;
    setState(() {
      _visibleRideRequests = _visibleRideRequests
          .where((request) => request.id != requestId)
          .toList(growable: false);
      final updated = Map<String, int>.from(_requestRemainingSeconds);
      updated.remove(requestId);
      _requestRemainingSeconds = updated;
      _fillVisibleRideRequests();
    });
  }

  Future<void> _acceptRideRequest(_DummyRideRequest request) async {
    if (_isSubmittingRideAction) return;
    final offerId = request.offerId;
    if (offerId == null || offerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing offer id for this request.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _isSubmittingRideAction = true);
    final response = await _driverApiService.acceptRequest(offerId);
    if (!mounted) return;
    setState(() => _isSubmittingRideAction = false);
    if (response['success'] != true) {
      final message =
          (response['error'] as String?) ?? 'Unable to accept request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return;
    }

    final payload = response['payload'] as Map<String, dynamic>? ?? const {};
    debugPrint('✅ Offer accepted by driver: payload=$payload');
    final data = payload['data'];
    final rideMap = (data is Map<String, dynamic>)
        ? (data['ride'] as Map<String, dynamic>? ?? data)
        : const <String, dynamic>{};
    final rideIdRaw = rideMap['ride_id'] ?? rideMap['id'] ?? payload['ride_id'];
    final rideId = rideIdRaw?.toString();
    _requestCountdownTimer?.cancel();
    setState(() {
      _awaitingRiderRequest = request;
      _activeRideId = rideId;
    });
    _removeRideRequestById(request.id);
    _startActiveRidePolling();
    await _syncCurrentRide();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Offer sent for ${request.id}. Waiting for rider.'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _updateActiveRideTracking() async {
    final request = _acceptedRide;
    if (request == null) return;

    final riderPoint = LatLng(request.fromLatitude, request.fromLongitude);
    final destination = LatLng(request.toLatitude, request.toLongitude);
    final origin = _trackingOriginFor(request);
    final target = _ridePhase == _RidePhase.toRider ? riderPoint : destination;
    final meters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      target.latitude,
      target.longitude,
    );
    final distanceKm = meters / 1000;
    final etaMinutes = ((distanceKm / 30) * 60).ceil().clamp(1, 120);
    final hasReachedRiderNow =
        _ridePhase == _RidePhase.toRider && distanceKm <= 0.15;
    final hasReachedDestinationNow =
        _ridePhase == _RidePhase.toDestination && distanceKm <= 0.15;

    final shouldAnnounceReached = hasReachedRiderNow && !_hasReachedRider;
    setState(() {
      _rideRemainingDistanceKm = distanceKm;
      _rideRemainingEtaMinutes = etaMinutes;
      if (hasReachedRiderNow) {
        _hasReachedRider = true;
      }
      if (hasReachedDestinationNow) {
        _hasReachedDestination = true;
      }
    });
    if (hasReachedRiderNow && !_pickupMarkedOnServer) {
      await _markReachedRiderOnServer();
    }
    if (shouldAnnounceReached && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have reached rider location'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
    _updateCurrentLocationOverlay();

    final controller = _mapController;
    if (controller != null) {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(_latLngBoundsFrom(origin, target), 72),
        );
      } catch (_) {}
    }
  }

  Future<void> _startRideAfterPickup() async {
    if (_acceptedRide == null || !_hasReachedRider) return;
    final rideId = _activeRideId;
    if (rideId != null) {
      if (!_pickupMarkedOnServer) {
        await _markReachedRiderOnServer();
      }
      final result = await _driverApiService.beginTrip(rideId);
      if (!mounted) return;
      if (result['success'] != true) {
        final message = (result['error'] as String?) ?? 'Unable to start ride.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    setState(() {
      _ridePhase = _RidePhase.toDestination;
      _hasReachedDestination = false;
    });
    await _updateActiveRideTracking();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride started to destination'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _completeCurrentRide() async {
    if (_acceptedRide == null || !_hasReachedDestination) return;
    final rideId = _activeRideId;
    if (rideId == null) return;
    final result = await _driverApiService.completeRide(rideId);
    if (!mounted) return;
    if (result['success'] != true) {
      final message =
          (result['error'] as String?) ?? 'Unable to complete ride.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return;
    }

    final ride = _acceptedRide!;
    final serviceAmount = ride.serviceAmount;
    if (serviceAmount > 0) {
      WalletStore.instance.recordServiceFeeDeduction(
        rideLabel: ride.id,
        serviceAmount: serviceAmount,
        totalFare: ride.suggestedFare,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          serviceAmount > 0
              ? 'Ride completed. Service fee of \$${serviceAmount.toStringAsFixed(2)} deducted.'
              : 'Ride completed',
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
    await _exitNavigationMode();
  }

  Future<void> _resetRideState() async {
    if (!mounted) return;
    setState(() {
      _acceptedRide = null;
      _awaitingRiderRequest = null;
      _activeRideId = null;
      _isRideInNavigation = false;
      _ridePhase = _RidePhase.toRider;
      _hasReachedRider = false;
      _pickupMarkedOnServer = false;
      _rideRemainingDistanceKm = null;
      _rideRemainingEtaMinutes = null;
      _hasReachedDestination = false;
    });
    _updateCurrentLocationOverlay();
    await _moveToCurrentLocation();
    if (_isOnline) {
      await _refreshPendingRequests();
      _startRequestCards();
    }
  }

  Future<void> _cancelCurrentRide() async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride session is not available for cancellation yet.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Do you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    final result = await _driverApiService.cancelRide(rideId);
    if (!mounted) return;
    if (result['success'] != true) {
      final message = (result['error'] as String?) ?? 'Unable to cancel ride.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride cancelled'),
        duration: Duration(milliseconds: 900),
      ),
    );
    await _resetRideState();
  }

  Future<void> _exitNavigationMode() async {
    _requestCountdownTimer?.cancel();
    _activeRidePollingTimer?.cancel();
    final rideId = _activeRideId;
    if (rideId != null && _isRideInNavigation) {
      await _driverApiService.cancelRide(rideId);
    }
    await _resetRideState();
  }

  Future<bool> _confirmExitNavigation() async {
    if (!_isRideInNavigation) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit Ride Navigation'),
        content: const Text('Do you want to exit the active ride navigation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await _exitNavigationMode();
    }
    return false;
  }

  LatLngBounds _latLngBoundsFrom(LatLng a, LatLng b) {
    final minLat = a.latitude < b.latitude ? a.latitude : b.latitude;
    final maxLat = a.latitude > b.latitude ? a.latitude : b.latitude;
    final minLng = a.longitude < b.longitude ? a.longitude : b.longitude;
    final maxLng = a.longitude > b.longitude ? a.longitude : b.longitude;

    final safeMaxLat = minLat == maxLat ? maxLat + 0.001 : maxLat;
    final safeMaxLng = minLng == maxLng ? maxLng + 0.001 : maxLng;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(safeMaxLat, safeMaxLng),
    );
  }

  LatLng _trackingOriginFor(_DummyRideRequest request) {
    final current = _currentLatLng;
    final rider = LatLng(request.fromLatitude, request.fromLongitude);
    if (current == null) {
      return LatLng(rider.latitude - 0.0045, rider.longitude - 0.0045);
    }

    // Demo mode guard: if device is far from dummy ride city, start route near rider.
    final kmFromRider =
        Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          rider.latitude,
          rider.longitude,
        ) /
        1000;
    if (kmFromRider > 35) {
      return LatLng(rider.latitude - 0.0045, rider.longitude - 0.0045);
    }
    return current;
  }

  Future<void> _recenterOnRideTarget() async {
    final request = _acceptedRide;
    final controller = _mapController;
    if (request == null || controller == null) return;
    final origin = _trackingOriginFor(request);
    final target = _ridePhase == _RidePhase.toRider
        ? LatLng(request.fromLatitude, request.fromLongitude)
        : LatLng(request.toLatitude, request.toLongitude);
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(_latLngBoundsFrom(origin, target), 72),
      );
    } catch (_) {}
  }

  Future<void> _handleRideAction(
    String actionLabel,
    _DummyRideRequest request, {
    double? offeredFare,
    bool showSnack = true,
  }) async {
    if (_isSubmittingRideAction) return;
    final offerId = request.offerId;
    if (offerId == null || offerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing offer id for this request.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _isSubmittingRideAction = true);

    Map<String, dynamic> response;
    if (offeredFare != null) {
      response = await _driverApiService.offerFare(offerId, offeredFare);
    } else {
      response = await _driverApiService.declineRequest(offerId);
    }

    if (!mounted) return;
    setState(() => _isSubmittingRideAction = false);

    if (response['success'] != true) {
      final message =
          (response['error'] as String?) ?? 'Unable to process request action.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return;
    }

    if (showSnack) {
      final fareText = offeredFare != null
          ? ' at \$${offeredFare.toStringAsFixed(0)}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actionLabel ${request.id}$fareText'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }

    _removeRideRequestById(request.id);
    await _refreshPendingRequests();
  }

  Future<void> _showOfferFareSheet(_DummyRideRequest request) async {
    _requestCountdownTimer?.cancel();
    var offerText = request.suggestedFare.toStringAsFixed(0);

    final offeredFare = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return StatefulBuilder(
          builder: (context, _) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 18,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer Your Fare',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: offerText,
                      onChanged: (value) => offerText = value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Fare amount',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final parsed = double.tryParse(offerText.trim());
                          if (parsed == null || parsed <= 0) {
                            Navigator.of(sheetContext).pop();
                            return;
                          }
                          Navigator.of(sheetContext).pop(parsed);
                        },
                        child: const Text('Send Offer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || !_isOnline) return;

    if (offeredFare != null) {
      await _handleRideAction(
        'Fare offered for',
        request,
        offeredFare: offeredFare,
      );
      return;
    }

    final stillVisible = _visibleRideRequests.any(
      (item) => item.id == request.id,
    );
    if (stillVisible) {
      _startRequestCountdownTicker();
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'online' ||
          normalized == 'active';
    }
    return false;
  }

  List<Map<String, dynamic>> _extractListFromPayload(
    Map<String, dynamic> payload,
  ) {
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (data is Map<String, dynamic>) {
      for (final key in ['offers', 'requests', 'items', 'pending']) {
        final nested = data[key];
        if (nested is List) {
          final parentRequestId = data['request_id'];
          final parentStatus = data['status'];
          final hasAcceptedDriver = data['has_accepted_driver'];
          return nested
              .whereType<Map<String, dynamic>>()
              .map((item) {
                return <String, dynamic>{
                  ...item,
                  if (parentRequestId != null && item['request_id'] == null)
                    'request_id': parentRequestId,
                  if (parentStatus != null && item['request_status'] == null)
                    'request_status': parentStatus,
                  if (hasAcceptedDriver != null &&
                      item['has_accepted_driver'] == null)
                    'has_accepted_driver': hasAcceptedDriver,
                };
              })
              .toList(growable: false);
        }
      }
      return <Map<String, dynamic>>[data];
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> _refreshPendingRequests() async {
    if ((!_isOnline && !_isRideInNavigation && _activeRideId == null) ||
        _isRideInNavigation ||
        _isFetchingRequests) {
      return;
    }
    _isFetchingRequests = true;

    final result = await _driverApiService.getPendingRequests();
    if (!mounted) return;
    _isFetchingRequests = false;
    if (result['success'] != true) {
      return;
    }

    final payload = result['payload'] as Map<String, dynamic>? ?? const {};
    final rows = _extractListFromPayload(payload);
    final parsed = <_DummyRideRequest>[];
    for (var i = 0; i < rows.length; i += 1) {
      final row = rows[i];
      final request = _DummyRideRequest.fromApi(row);
      if (request == null) {
        debugPrint(
          '⚠️ Pending request row[$i] skipped. Keys=${row.keys.toList()}',
        );
        continue;
      }
      debugPrint(
        '🧾 Pending request row[$i] parsed: requestId=${request.requestId}, offerId=${request.offerId}',
      );
      parsed.add(request);
    }
    debugPrint(
      '🚕 Pending requests sync: raw=${rows.length}, parsed=${parsed.length}',
    );

    _DummyRideRequest? awaitingRequest;
    for (final request in parsed) {
      if (_isAwaitingRiderConfirmation(request)) {
        awaitingRequest = request;
        break;
      }
    }

    setState(() {
      _awaitingRiderRequest = awaitingRequest;
      _backendRideRequests = parsed;
      _fillVisibleRideRequests();
      if (awaitingRequest != null) {
        _visibleRideRequests = _visibleRideRequests
            .where((item) => item.id != awaitingRequest!.id)
            .toList(growable: false);
      }
    });
    if (_visibleRideRequests.isNotEmpty) {
      _startRequestCountdownTicker();
    }
  }

  Future<void> _postCurrentLocationToBackend() async {
    if (!_isOnline) return;
    final current = _currentLatLng;
    if (current == null) return;
    await _driverApiService.updateDriverLocation(
      lat: current.latitude,
      lng: current.longitude,
    );
  }

  void _startPendingRequestsPolling() {
    _pendingRequestsPollingTimer?.cancel();
    _pendingRequestsPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshPendingRequests(),
    );
  }

  void _startLocationSync() {
    _locationSyncTimer?.cancel();
    _locationSyncTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _postCurrentLocationToBackend(),
    );
  }

  Future<void> _syncCurrentRide() async {
    final result = await _driverApiService.getCurrentRide();
    if (!mounted) return;
    if (result['success'] != true) {
      if (result['statusCode'] == 404 && _isRideInNavigation) {
        setState(() {
          _acceptedRide = null;
          _awaitingRiderRequest = null;
          _activeRideId = null;
          _isRideInNavigation = false;
          _ridePhase = _RidePhase.toRider;
          _hasReachedRider = false;
          _pickupMarkedOnServer = false;
          _rideRemainingDistanceKm = null;
          _rideRemainingEtaMinutes = null;
          _hasReachedDestination = false;
        });
      }
      return;
    }

    final payload = result['payload'] as Map<String, dynamic>? ?? const {};
    final rawData = payload['data'];
    if (rawData is! Map<String, dynamic>) return;

    final ride = (rawData['ride'] is Map<String, dynamic>)
        ? rawData['ride'] as Map<String, dynamic>
        : rawData;
    if ((ride['status']?.toString().toLowerCase() ?? '') == 'completed') {
      await _resetRideState();
      return;
    }
    final offer = (ride['request'] is Map<String, dynamic>)
        ? ride['request'] as Map<String, dynamic>
        : (ride['offer'] is Map<String, dynamic>)
        ? ride['offer'] as Map<String, dynamic>
        : ride;
    final request = _DummyRideRequest.fromApi(<String, dynamic>{
      ...ride,
      ...offer,
    });
    if (request == null) return;

    final phaseRaw = (ride['phase'] ?? ride['status'])
        ?.toString()
        .toLowerCase();
    final riderReached = _toBool(ride['rider_reached']);
    final phase =
        riderReached || phaseRaw == 'to_destination' || phaseRaw == 'ongoing'
        ? _RidePhase.toDestination
        : _RidePhase.toRider;
    final rideId = (ride['ride_id'] ?? ride['id'])?.toString();
    debugPrint('🧭 Active ride sync: rideId=$rideId, phase=$phaseRaw');

    setState(() {
      _acceptedRide = request;
      _awaitingRiderRequest = null;
      _activeRideId = rideId;
      _isRideInNavigation = true;
      _ridePhase = phase;
      _hasReachedRider =
          riderReached || phase == _RidePhase.toDestination || _hasReachedRider;
      _pickupMarkedOnServer = _hasReachedRider;
      _hasReachedDestination =
          phase == _RidePhase.toDestination && _hasReachedDestination;
      _rideRemainingDistanceKm = (ride['remaining_distance_km'] is num)
          ? (ride['remaining_distance_km'] as num).toDouble()
          : _rideRemainingDistanceKm;
      _rideRemainingEtaMinutes = (ride['remaining_eta_min'] is num)
          ? (ride['remaining_eta_min'] as num).toInt()
          : _rideRemainingEtaMinutes;
      _visibleRideRequests = const [];
      _requestRemainingSeconds = const {};
    });
    _startActiveRidePolling();
    await _updateActiveRideTracking();
  }

  void _startActiveRidePolling() {
    _activeRidePollingTimer?.cancel();
    _activeRidePollingTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      _syncCurrentRide();
    });
  }

  Future<bool> _markReachedRiderOnServer({bool markLocally = false}) async {
    final rideId = _activeRideId;
    if (_pickupMarkedOnServer) {
      if (markLocally && mounted) {
        setState(() => _hasReachedRider = true);
      }
      return true;
    }
    if (rideId == null || rideId.isEmpty) {
      if (markLocally && mounted) {
        setState(() {
          _hasReachedRider = true;
          _pickupMarkedOnServer = true;
        });
      }
      return true;
    }
    final result = await _driverApiService.markReachedPickup(rideId);
    if (!mounted) return false;
    if (result['success'] == true) {
      setState(() {
        _pickupMarkedOnServer = true;
        if (markLocally) {
          _hasReachedRider = true;
        }
      });
      return true;
    }
    return false;
  }

  Future<void> _handleReachedRider() async {
    if (_acceptedRide == null || _ridePhase != _RidePhase.toRider) return;
    final success = await _markReachedRiderOnServer(markLocally: true);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to mark rider as reached.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await _updateActiveRideTracking();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pickup reached. You can start the ride now.'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  void _markReachedDestination() {
    if (_acceptedRide == null || _ridePhase != _RidePhase.toDestination) return;
    setState(() => _hasReachedDestination = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Destination reached. Complete the ride to finish.'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _syncDriverStatusFromBackend() async {
    final result = await _driverApiService.getDriverStatus();
    if (!mounted || result['success'] != true) return;
    final payload = result['payload'] as Map<String, dynamic>? ?? const {};
    final data = (payload['data'] is Map<String, dynamic>)
        ? payload['data'] as Map<String, dynamic>
        : payload;
    final isOnline = _toBool(data['is_online']);
    final profileCompleted = _toBool(data['profile_completed']);
    final profileStatus = data['profile_status']
        ?.toString()
        .trim()
        .toLowerCase();
    final isApproved =
        profileStatus == 'approved' ||
        profileStatus == 'verified' ||
        profileStatus == 'active';
    debugPrint('🟢 Driver status sync: isOnline=$isOnline');
    setState(() {
      _isOnline = isOnline;
      _profileCompletedFromStatus = profileCompleted;
      _isApprovedFromStatus = isApproved;
    });

    if (isOnline) {
      _startLocationSync();
      _startPendingRequestsPolling();
      _startActiveRidePolling();
      await _syncCurrentRide();
      if (!_isRideInNavigation) {
        await _refreshPendingRequests();
        _startRequestCards();
      }
    } else {
      _pendingRequestsPollingTimer?.cancel();
      _locationSyncTimer?.cancel();
      _activeRidePollingTimer?.cancel();
      _stopRequestCards();
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _moveToCurrentLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final target = LatLng(position.latitude, position.longitude);
      final controller = _mapController;
      _currentLatLng = target;
      _updateCurrentLocationOverlay();
      if (_isOnline && _acceptedRide == null) {
        _startRequestCards();
        await _postCurrentLocationToBackend();
      } else if (_acceptedRide != null) {
        await _updateActiveRideTracking();
      }

      if (controller != null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to fetch current location.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadCurrentLocationIcon() async {
    final icon = await _buildCurrentLocationMarkerIcon();
    if (!mounted) return;
    setState(() {
      _currentLocationIcon = icon;
    });
    _updateCurrentLocationOverlay();
  }

  Future<BitmapDescriptor> _buildCurrentLocationMarkerIcon() async {
    const markerWidth = 8.9;
    const markerHeight = 12.45;
    const rasterScale = 2.0;
    final width = markerWidth * rasterScale;
    final height = markerHeight * rasterScale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = const Color(0xFF414141)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = ui.Path();
    final bottomX = width / 2;
    final bottomY = height;
    final topX = width / 2;
    const topY = 0.0;
    const leftX = 0.0;
    final rightX = width;
    final baseY = height * 0.68;

    path.moveTo(bottomX, bottomY);
    path.lineTo(leftX, baseY);
    path.lineTo(topX, topY);
    path.lineTo(rightX, baseY);
    path.close();

    canvas.drawPath(path, paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.round(), height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      return BitmapDescriptor.defaultMarker;
    }
    return BitmapDescriptor.bytes(bytes);
  }

  void _updateCurrentLocationOverlay() {
    final point = _currentLatLng;
    if (!mounted) return;

    final accepted = _acceptedRide;
    final effectivePoint = accepted != null
        ? _trackingOriginFor(accepted)
        : point;
    if (effectivePoint == null) return;
    final icon = _currentLocationIcon ?? BitmapDescriptor.defaultMarker;
    final nextMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('current_location'),
        position: effectivePoint,
        icon: icon,
        anchor: const Offset(0.5, 1),
      ),
    };
    final nextPolylines = <Polyline>{};

    if (accepted != null && _isRideInNavigation) {
      final riderPoint = LatLng(accepted.fromLatitude, accepted.fromLongitude);
      final destinationPoint = LatLng(
        accepted.toLatitude,
        accepted.toLongitude,
      );
      final target = _ridePhase == _RidePhase.toRider
          ? riderPoint
          : destinationPoint;

      nextMarkers.add(
        Marker(
          markerId: const MarkerId('rider_pickup'),
          position: riderPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: accepted.riderName,
            snippet: 'Pickup Point',
          ),
        ),
      );
      nextMarkers.add(
        Marker(
          markerId: const MarkerId('ride_destination'),
          position: destinationPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(snippet: 'Destination'),
        ),
      );
      nextPolylines.add(
        Polyline(
          polylineId: const PolylineId('active_ride_route_glow'),
          points: [effectivePoint, target],
          width: 13,
          color:
              (_ridePhase == _RidePhase.toRider
                      ? const Color(0xFFEDAE10)
                      : const Color(0xFF5A48FF))
                  .withValues(alpha: 0.32),
        ),
      );
      nextPolylines.add(
        Polyline(
          polylineId: const PolylineId('active_ride_route'),
          points: [effectivePoint, target],
          width: 6,
          color: _ridePhase == _RidePhase.toRider
              ? const Color(0xFFEDAE10)
              : const Color(0xFF5A48FF),
        ),
      );
    }

    setState(() {
      _markers = nextMarkers;
      _circles = _isRideInNavigation
          ? const <Circle>{}
          : <Circle>{
              Circle(
                circleId: const CircleId('current_outer_1'),
                center: effectivePoint,
                radius: 250,
                fillColor: const Color(0x1AFEC400),
                strokeWidth: 0,
              ),
              Circle(
                circleId: const CircleId('current_outer_2'),
                center: effectivePoint,
                radius: 180,
                fillColor: const Color(0x26FEC400),
                strokeWidth: 0,
              ),
              Circle(
                circleId: const CircleId('current_outer_3'),
                center: effectivePoint,
                radius: 95,
                fillColor: const Color(0x40FEC400),
                strokeWidth: 0,
              ),
              Circle(
                circleId: const CircleId('current_outer_4'),
                center: effectivePoint,
                radius: 42,
                fillColor: const Color(0x80FEC400),
                strokeWidth: 0,
              ),
            };
      _polylines = nextPolylines;
    });
  }

  bool _requiresProfileCompletion(Map<String, dynamic>? driverProfile) {
    if (driverProfile == null || driverProfile.isEmpty) {
      return true;
    }

    final vehicleDoc = driverProfile['vehicle_doc'] as String?;
    final licenseDoc = driverProfile['license_doc'] as String?;
    final vehicleType = driverProfile['vehicle_type'] as String?;
    final vehicleNo = driverProfile['vehicle_no'] as String?;
    final licenseNo = driverProfile['license_no'] as String?;

    return (vehicleDoc == null || vehicleDoc.isEmpty) ||
        (licenseDoc == null || licenseDoc.isEmpty) ||
        (vehicleType == null || vehicleType.isEmpty) ||
        (vehicleNo == null || vehicleNo.isEmpty) ||
        (licenseNo == null || licenseNo.isEmpty);
  }

  bool _isApproved(Map<String, dynamic>? driverProfile) {
    if (driverProfile == null || driverProfile.isEmpty) return false;

    final candidates = <dynamic>[
      driverProfile['is_approved'],
      driverProfile['approved'],
      driverProfile['documents_approved'],
    ];

    for (final value in candidates) {
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'approved' ||
            normalized == 'verified' ||
            normalized == 'active' ||
            normalized == '1' ||
            normalized == 'true') {
          return true;
        }
      }
    }

    final statusCandidates = <dynamic>[
      driverProfile['status'],
      driverProfile['verification_status'],
      driverProfile['approval_status'],
      driverProfile['doc_status'],
      driverProfile['documents_status'],
    ];

    for (final value in statusCandidates) {
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'approved' ||
            normalized == 'verified' ||
            normalized == 'active') {
          return true;
        }
      }
    }

    final approvedAt = driverProfile['approved_at'];
    if (approvedAt is String && approvedAt.trim().isNotEmpty) {
      return true;
    }

    return false;
  }

  bool _effectiveProfileCompleted(Map<String, dynamic>? driverProfile) {
    return _profileCompletedFromStatus ??
        !_requiresProfileCompletion(driverProfile);
  }

  bool _effectiveProfileApproved(Map<String, dynamic>? driverProfile) {
    return _isApprovedFromStatus ?? _isApproved(driverProfile);
  }

  bool _isTransientStartupError(String? error) {
    if (error == null || error.isEmpty) return false;
    final normalized = error.toLowerCase();
    return normalized.contains('network error') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('timed out') ||
        normalized.contains('timeout');
  }

  void _scheduleStartupRetry() {
    _startupRetryTimer?.cancel();
    _startupRetryTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _isLoadingProfile) return;
      _hasCheckedProfile = false;
      _checkDriverProfile();
    });
  }

  Future<void> _showDocumentGateDialog({required bool isComplete}) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final title = isComplete
            ? 'Documents Under Review'
            : 'Documents Required';
        final description = isComplete
            ? 'Your documents are submitted and currently under review. You will be able to go online once they are approved.'
            : 'Upload the required driver documents to go online and start receiving rides.';
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete
                      ? Colors.orange.withValues(alpha: 0.14)
                      : Colors.red.withValues(alpha: 0.14),
                ),
                child: Icon(
                  isComplete ? Icons.hourglass_top : Icons.assignment_turned_in,
                  color: isComplete ? Colors.orange : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(description, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  context.goNamed(ARouter.documentUpload);
                }
              },
              child: const Text('Upload Documents'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentLocationIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDriverProfile();
      _moveToCurrentLocation();
    });
  }

  Future<void> _checkDriverProfile() async {
    if (_hasCheckedProfile) return;

    setState(() {
      _hasCheckedProfile = true;
      _isLoadingProfile = true;
    });

    final result = await _userService.getUserProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;

      setState(() {
        _userData = data;
        _isLoadingProfile = false;
      });
      WalletStore.instance.seedFromBackend(data);
      await _syncCurrentRide();
      await _syncDriverStatusFromBackend();
      if (!_isRideInNavigation) {
        await _refreshPendingRequests();
      }
      if (mounted) {
        setState(() => _hasResolvedStartupState = true);
      }
    } else {
      final error = result['error'] as String?;
      final isTransient = _isTransientStartupError(error);
      setState(() {
        _isLoadingProfile = false;
        _hasResolvedStartupState = !isTransient;
      });
      if (error?.toLowerCase().contains('unauthenticated') == true ||
          error?.toLowerCase().contains('401') == true) {
        // Token missing or invalid - redirect to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.goNamed(ARouter.signIn);
            }
          });
        }
      } else if (isTransient) {
        debugPrint('🌐 Startup profile fetch hit transient error. Retrying...');
        _scheduleStartupRetry();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (result['error'] as String?) ?? 'Failed to load profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleOnlineChanged(bool nextValue) async {
    if (!nextValue) {
      final offlinePoint = _currentLatLng;
      await _driverApiService.setDriverStatus(
        isOnline: false,
        isAvailable: false,
        lat: offlinePoint?.latitude,
        lng: offlinePoint?.longitude,
      );
      setState(() {
        _isOnline = false;
        _backendRideRequests = const [];
        _acceptedRide = null;
        _awaitingRiderRequest = null;
        _activeRideId = null;
        _isRideInNavigation = false;
        _ridePhase = _RidePhase.toRider;
        _hasReachedRider = false;
        _pickupMarkedOnServer = false;
        _rideRemainingDistanceKm = null;
        _rideRemainingEtaMinutes = null;
        _hasReachedDestination = false;
      });
      _pendingRequestsPollingTimer?.cancel();
      _locationSyncTimer?.cancel();
      _activeRidePollingTimer?.cancel();
      _stopRequestCards();
      _updateCurrentLocationOverlay();
      return;
    }

    final driverProfile = _userData?['driver_profile'] as Map<String, dynamic>?;
    final isComplete = _effectiveProfileCompleted(driverProfile);
    final isApproved = _effectiveProfileApproved(driverProfile);

    if (!isComplete || !isApproved) {
      await _showDocumentGateDialog(isComplete: isComplete);
      if (!mounted) return;
      setState(() => _isOnline = false);
      return;
    }

    if (_currentLatLng == null) {
      await _moveToCurrentLocation();
    }
    final onlinePoint = _currentLatLng;
    if (onlinePoint == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location is required to go online.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _isOnline = false);
      return;
    }

    final statusResult = await _driverApiService.setDriverStatus(
      isOnline: true,
      isAvailable: true,
      lat: onlinePoint.latitude,
      lng: onlinePoint.longitude,
    );
    if (!mounted) return;
    if (statusResult['success'] != true) {
      final error =
          (statusResult['error'] as String?) ?? 'Unable to go online.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 2)),
      );
      setState(() => _isOnline = false);
      return;
    }

    setState(() => _isOnline = true);
    _startLocationSync();
    _startPendingRequestsPolling();
    await _postCurrentLocationToBackend();
    await _syncCurrentRide();
    if (!_isRideInNavigation) {
      await _refreshPendingRequests();
      _startRequestCards();
    }
  }

  Widget _buildRideRequestCard(ThemeData theme, _DummyRideRequest request) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF272A31) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final bodyColor = isDark
        ? const Color(0xFFD2D6DE)
        : const Color(0xFF646B75);
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final remainingSeconds =
        _requestRemainingSeconds[request.id] ?? _requestTimeoutSeconds;
    final isPendingOffer = (request.offerStatus ?? 'pending') == 'pending';
    final hasAcceptedDriver = request.hasAcceptedDriver;
    final statusLabel =
        request.offerStatus ?? request.requestStatus ?? 'pending';
    final actionsEnabled = isPendingOffer && !hasAcceptedDriver;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Container(
        key: ValueKey<String>(request.id),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF4BE05), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4BE05).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          request.id,
                          style: const TextStyle(
                            color: Color(0xFFEDAE10),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasAcceptedDriver
                              ? const Color(0xFF22A05D).withValues(alpha: 0.14)
                              : const Color(0xFFEDAE10).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel.replaceAll('_', ' '),
                          style: TextStyle(
                            color: hasAcceptedDriver
                                ? const Color(0xFF22A05D)
                                : const Color(0xFFEDAE10),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$remainingSeconds s',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        request.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: remainingSeconds / _requestTimeoutSeconds,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFEDAE10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _rideDetailRow(
              label: 'From',
              value: request.fromLocation,
              labelColor: bodyColor,
              valueColor: titleColor,
            ),
            const SizedBox(height: 6),
            _rideDetailRow(
              label: 'To',
              value: request.toLocation,
              labelColor: bodyColor,
              valueColor: titleColor,
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: lineColor),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.route,
                    label: 'Distance',
                    value: '${request.distanceKm.toStringAsFixed(1)} km',
                    color: titleColor,
                    muted: bodyColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    icon: Icons.schedule,
                    label: 'Time',
                    value: '${request.etaMinutes} min',
                    color: titleColor,
                    muted: bodyColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    icon: Icons.payments_outlined,
                    label: 'Fare',
                    value: '\$${request.suggestedFare.toStringAsFixed(0)}',
                    color: titleColor,
                    muted: bodyColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmittingRideAction || !actionsEnabled
                        ? null
                        : () => _handleRideAction('Declined request', request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmittingRideAction || !actionsEnabled
                        ? null
                        : () => _showOfferFareSheet(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEDAE10),
                      side: BorderSide(
                        color: const Color(0xFFEDAE10).withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text('Offer Your Fare'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmittingRideAction || !actionsEnabled
                        ? null
                        : () => _acceptRideRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22A05D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
            if (hasAcceptedDriver) ...[
              const SizedBox(height: 10),
              Text(
                'Waiting for rider confirmation before ride starts.',
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rideDetailRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 45,
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4BE05).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFFEDAE10)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupProgressChip(ThemeData theme) {
    final distance = _rideRemainingDistanceKm;
    final eta = _rideRemainingEtaMinutes;
    if (distance == null || eta == null || _acceptedRide == null) {
      return const SizedBox.shrink();
    }
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A31) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF4BE05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '${_ridePhase == _RidePhase.toRider ? 'Pickup' : 'Trip'}: ${distance.toStringAsFixed(1)} km • $eta min',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1F1F1F),
        ),
      ),
    );
  }

  Widget _buildAwaitingRiderCard(ThemeData theme, _DummyRideRequest request) {
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF272A31) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final bodyColor = isDark
        ? const Color(0xFFD2D6DE)
        : const Color(0xFF646B75);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF4BE05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEDAE10).withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFFEDAE10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waiting For Rider',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Offer accepted by you for ${request.id}',
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDAE10).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Waiting for rider to accept your offer. Ride navigation will start automatically once backend confirms the accepted driver.',
              style: TextStyle(
                color: titleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _rideDetailRow(
            label: 'From',
            value: request.fromLocation,
            labelColor: bodyColor,
            valueColor: titleColor,
          ),
          const SizedBox(height: 6),
          _rideDetailRow(
            label: 'To',
            value: request.toLocation,
            labelColor: bodyColor,
            valueColor: titleColor,
          ),
          if (_activeRideId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancelCurrentRide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.55)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Cancel Ride',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveRideBottomSheet(ThemeData theme, _DummyRideRequest ride) {
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final bodyColor = isDark
        ? const Color(0xFFD2D6DE)
        : const Color(0xFF646B75);
    final distance = _rideRemainingDistanceKm;
    final eta = _rideRemainingEtaMinutes;
    final statusText = _ridePhase == _RidePhase.toRider
        ? (_hasReachedRider
              ? 'Reached rider location'
              : 'Heading to rider pickup')
        : (_hasReachedDestination
              ? 'Reached destination'
              : 'Ride in progress to destination');
    final statusColor =
        (_hasReachedRider && _ridePhase == _RidePhase.toRider) ||
            (_hasReachedDestination && _ridePhase == _RidePhase.toDestination)
        ? const Color(0xFF22A05D)
        : const Color(0xFFEDAE10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A31) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: const Color(0xFFF4BE05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF4BE05).withValues(alpha: 0.2),
                child: Text(
                  ride.riderName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFEDAE10),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.riderName,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Ride ${ride.id}',
                      style: TextStyle(color: bodyColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _iconRoundButton(Icons.message_outlined, const Color(0xFFEDAE10)),
              const SizedBox(width: 8),
              _iconRoundButton(Icons.call_outlined, const Color(0xFF22A05D)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.schedule,
                  label: 'Time Remaining',
                  value: eta != null ? '$eta min' : '--',
                  color: titleColor,
                  muted: bodyColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  icon: Icons.route,
                  label: 'Distance Remaining',
                  value: distance != null
                      ? '${distance.toStringAsFixed(1)} km'
                      : '--',
                  color: titleColor,
                  muted: bodyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_ridePhase == _RidePhase.toRider ? 'Pickup' : 'Destination'}: ${_ridePhase == _RidePhase.toRider ? ride.fromLocation : ride.toLocation}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fare \$${ride.suggestedFare.toStringAsFixed(2)} • Service fee \$${ride.serviceAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: bodyColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_ridePhase == _RidePhase.toRider && !_hasReachedRider) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleReachedRider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEDAE10),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'I Have Reached',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (_ridePhase == _RidePhase.toRider && _hasReachedRider) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startRideAfterPickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22A05D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Start Ride',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (_ridePhase == _RidePhase.toDestination &&
              !_hasReachedDestination) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _markReachedDestination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4BE05),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Reached Destination',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (_ridePhase == _RidePhase.toDestination &&
              _hasReachedDestination) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeCurrentRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C7C59),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Complete Ride',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancelCurrentRide,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.55)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancel Ride',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSideControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navControlButton(
          icon: Icons.my_location,
          onTap: _recenterOnRideTarget,
        ),
        const SizedBox(height: 10),
        _navControlButton(icon: Icons.search, onTap: () {}),
        const SizedBox(height: 10),
        _navControlButton(
          icon: _isNavigationMuted ? Icons.volume_off : Icons.volume_up,
          onTap: () => setState(() => _isNavigationMuted = !_isNavigationMuted),
        ),
      ],
    );
  }

  Widget _navControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _iconRoundButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              icon == Icons.call_outlined
                  ? 'Calling rider...'
                  : 'Opening chat...',
            ),
            duration: const Duration(milliseconds: 700),
          ),
        );
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildNavigationTopPanel(ThemeData theme, _DummyRideRequest ride) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C7C59),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _confirmExitNavigation,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.straight, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _ridePhase == _RidePhase.toRider
                  ? 'Towards rider pickup'
                  : 'Towards ${ride.toLocation}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: const Icon(Icons.mic_none, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _requestCountdownTimer?.cancel();
    _pendingRequestsPollingTimer?.cancel();
    _locationSyncTimer?.cancel();
    _activeRidePollingTimer?.cancel();
    _startupRetryTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStyle = theme.brightness == Brightness.dark
        ? _darkMapStyle
        : _lightMapStyle;
    final onSurface = theme.colorScheme.onSurface;
    final driverProfile = _userData?['driver_profile'] as Map<String, dynamic>?;
    final profileImage = driverProfile?['profile_image'] as String?;
    final isApproved = _effectiveProfileApproved(driverProfile);
    final isComplete = _effectiveProfileCompleted(driverProfile);
    final isResolvingStatus = _isLoadingProfile || !_hasResolvedStartupState;

    return PopScope(
      canPop: !_isRideInNavigation,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isRideInNavigation) {
          _confirmExitNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultTarget,
                  zoom: 16.2,
                ),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                buildingsEnabled: true,
                indoorViewEnabled: true,
                trafficEnabled: true,
                mapToolbarEnabled: false,
                fortyFiveDegreeImageryEnabled: true,
                style: mapStyle,
                circles: _circles,
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _moveToCurrentLocation();
                },
              ),
            ),
            if (!_isRideInNavigation)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage:
                                    profileImage != null &&
                                        profileImage.isNotEmpty
                                    ? NetworkImage(
                                        ImageUtils.getImageUrl(profileImage),
                                      )
                                    : null,
                                child:
                                    profileImage == null || profileImage.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        color: Colors.grey.shade600,
                                      )
                                    : null,
                              ),
                              if (_isOnline)
                                Positioned(
                                  right: -1,
                                  bottom: -1,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isOnline ? 'Online' : 'Offline',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                ),
                              ),
                              if (isResolvingStatus)
                                Text(
                                  'Loading…',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: onSurface.withValues(alpha: 0.6),
                                  ),
                                )
                              else if (!isComplete)
                                Text(
                                  'Upload documents',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else if (!isApproved)
                                Text(
                                  'Pending approval',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                Text(
                                  'Ready',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Switch.adaptive(
                            value: _isOnline,
                            onChanged: _isLoadingProfile
                                ? null
                                : _handleOnlineChanged,
                            activeThumbColor: Colors.green,
                            activeTrackColor: Colors.green.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isRideInNavigation && _acceptedRide != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _buildNavigationTopPanel(theme, _acceptedRide!),
                  ),
                ),
              ),
            if (_isRideInNavigation && _acceptedRide != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 92),
                    child: _buildNavigationSideControls(),
                  ),
                ),
              ),
            if (_acceptedRide != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: _isRideInNavigation ? 90 : 84,
                      left: 16,
                      right: 16,
                    ),
                    child: _buildPickupProgressChip(theme),
                  ),
                ),
              ),
            if (_isOnline &&
                _acceptedRide == null &&
                _visibleRideRequests.isNotEmpty)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 86),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.92,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Incoming Requests (${_visibleRideRequests.length})',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _visibleRideRequests.length,
                              itemBuilder: (context, index) {
                                final request = _visibleRideRequests[index];
                                return Transform.translate(
                                  offset: Offset(0, index * -4),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildRideRequestCard(
                                      theme,
                                      request,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isOnline &&
                !_isRideInNavigation &&
                _acceptedRide == null &&
                _awaitingRiderRequest != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 86),
                    child: _buildAwaitingRiderCard(
                      theme,
                      _awaitingRiderRequest!,
                    ),
                  ),
                ),
              ),
            if (_acceptedRide != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: _buildActiveRideBottomSheet(theme, _acceptedRide!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
