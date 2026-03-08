// frontend/lib/screens/map_route_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MapRouteScreen extends StatefulWidget {
  final double userLat;
  final double userLon;

  // Direct destination coordinates from backend
  final double destLat;
  final double destLon;

  final String siteName;

  const MapRouteScreen({
    super.key,
    required this.userLat,
    required this.userLon,
    required this.destLat, // Heritage site latitude
    required this.destLon, // Heritage site longitude
    required this.siteName,
  });

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen>
    with TickerProviderStateMixin {

  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};
  final List<LatLng> _polylineCoords = [];

  late PolylinePoints polylinePoints;

  StreamSubscription<Position>? positionStream; // REAL-TIME TRACKING

  bool _isLoadingRoute = false;

  // Google Maps Directions API Key
  static const String googleAPIKey = "AIzaSyCmDTmBIMU9QquyjZiYpsgnnQ0mg3QkrwA";

  // ── Design tokens (from profile_screen) ───────────────────────────────────
  static const Color _navy     = Color(0xFF001233);
  static const Color _navyMid  = Color(0xFF002D72);
  static const Color _blue     = Color(0xFF023E8A);
  static const Color _gold     = Color(0xFFFFD700);
  static const Color _goldDeep = Color(0xFFFFB800);
  static const Color _textMain = Color(0xFF001845);
  static const Color _textSub  = Color(0xFF90A4C4);

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();

    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    _addStaticMarkers(); // user + heritage markers
    _loadPolyline();     // load route polyline
    _startTrackingUser(); // start real-time GPS tracking
  }

  @override
  void dispose() {
    positionStream?.cancel(); // stop GPS tracking when leaving screen
    _shimmerController.dispose();
    super.dispose();
  }

  // ADD MARKERS (logic unchanged)
  void _addStaticMarkers() {
    // USER MARKER
    _markers.add(
      Marker(
        markerId: const MarkerId("user"),
        position: LatLng(widget.userLat, widget.userLon),
        infoWindow: const InfoWindow(title: "You are here"),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    );

    // HERITAGE SITE MARKER
    _markers.add(
      Marker(
        markerId: const MarkerId("heritage"),
        position: LatLng(widget.destLat, widget.destLon),
        infoWindow: InfoWindow(title: widget.siteName),
      ),
    );

    setState(() {});
  }

  // REAL-TIME GPS TRACKING (logic unchanged)
  void _startTrackingUser() async {
    LocationSettings settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // update every 1 meter
    );

    positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) async {
      LatLng newPos = LatLng(pos.latitude, pos.longitude);

      // remove old marker + add new user marker
      _markers.removeWhere((m) => m.markerId.value == "user");
      _markers.add(
        Marker(
          markerId: const MarkerId("user"),
          position: newPos,
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );

      setState(() {});

      // smooth camera movement
      // final controller = await _controller.future;
      // controller.animateCamera(CameraUpdate.newLatLng(newPos));
    });
  }

  // GET GOOGLE POLYLINE (logic unchanged)
  Future<void> _loadPolyline() async {
    setState(() => _isLoadingRoute = true);
    try {
      final url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${widget.userLat},${widget.userLon}"
          "&destination=${widget.destLat},${widget.destLon}"
          "&key=$googleAPIKey";

      final routeResponse = await http.get(Uri.parse(url));
      final json = jsonDecode(routeResponse.body);

      if (json["routes"].isNotEmpty) {
        final encodedPolyline = json["routes"][0]["overview_polyline"]["points"];
        final decoded = polylinePoints.decodePolyline(encodedPolyline);

        _polylineCoords.clear();
        for (var p in decoded) {
          _polylineCoords.add(LatLng(p.latitude, p.longitude));
        }
      }

      setState(() {});

      // AUTO-ZOOM & FIT BOTH MARKERS + ROUTE IN SCREEN
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          widget.userLat < widget.destLat ? widget.userLat : widget.destLat,
          widget.userLon < widget.destLon ? widget.userLon : widget.destLon,
        ),
        northeast: LatLng(
          widget.userLat > widget.destLat ? widget.userLat : widget.destLat,
          widget.userLon > widget.destLon ? widget.userLon : widget.destLon,
        ),
      );

      final GoogleMapController controller = await _controller.future;

      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60), // padding 60 px
      );
    } catch (e) {
      debugPrint("Error loading route: $e");
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  // MANUAL REFRESH FOR ROUTE + MARKERS (logic unchanged)
  Future<void> _refreshRoute() async {
    // Clear old polyline
    _polylineCoords.clear();

    // Add markers again (in case user moved)
    _markers.clear();
    _addStaticMarkers();

    // Reload polyline route
    await _loadPolyline();

    setState(() {});
  }

  // OPEN GOOGLE MAPS FOR TURN-BY-TURN NAVIGATION (logic unchanged)
  Future<void> _openGoogleMapsNavigation() async {
    final url =
        "google.navigation:q=${widget.destLat},${widget.destLon}&mode=d";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Browser fallback
      final browserUrl =
          "https://www.google.com/maps/dir/?api=1&destination=${widget.destLat},${widget.destLon}";
      await launchUrl(Uri.parse(browserUrl));
    }
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      // ── AppBar (matches profile_screen style) ─────────────────────────────
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
          ),
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 1.5),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.map_outlined, size: 16, color: _gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ROUTE MAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.siteName,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_gold, Color(0xFFFFA500), _gold]),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // ── Google Map ─────────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.userLat, widget.userLon),
                zoom: 12,
              ),
              markers: _markers,
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  color: _navyMid,
                  width: 5,
                  points: _polylineCoords,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              onMapCreated: (controller) {
                _controller.complete(controller);
                mapController = controller;
              },
            ),

            // ── Route loading indicator ────────────────────────────────────
            if (_isLoadingRoute)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _gold.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: _navyMid.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _goldDeep,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Loading route…',
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

            // ── Refresh button (top-right) ─────────────────────────────────
            Positioned(
              top: 16,
              right: 12,
              child: GestureDetector(
                onTap: _refreshRoute,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _navyMid.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.refresh_rounded, color: _navyMid, size: 22),
                ),
              ),
            ),

            // ── Start Navigation button (bottom) ──────────────────────────
            Positioned(
              bottom: 20,
              left: 60,
              right: 60,
              child: GestureDetector(
                onTap: _openGoogleMapsNavigation,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [_goldDeep, _gold, Color(0xFFFFC200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 25, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _navy.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.navigation_rounded, color: _navy, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Start Navigation",
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Destination info chip (bottom-left above button) ───────────
            Positioned(
              bottom: 86,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _gold.withValues(alpha: 0.45), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _navyMid.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: _goldDeep, size: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.siteName,
                    style: const TextStyle(
                      color: _textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}