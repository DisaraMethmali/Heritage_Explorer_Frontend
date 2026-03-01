// frontend/lib/screens/map_route_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

class _MapRouteScreenState extends State<MapRouteScreen> {
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};
  final List<LatLng> _polylineCoords = [];

  late PolylinePoints polylinePoints;

  StreamSubscription<Position>? positionStream; // REAL-TIME TRACKING

  // Google Maps Directions API Key
  static const String googleAPIKey = "AIzaSyCmDTmBIMU9QquyjZiYpsgnnQ0mg3QkrwA";

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();

    _addStaticMarkers(); // user + heritage markers
    _loadPolyline();     // load route polyline
    _startTrackingUser(); // start real-time GPS tracking
  }

  // ADD MARKERS
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

  // REAL-TIME GPS TRACKING (stream)
  // updates blue dot on map every 1 meter movement
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

  // GET GOOGLE POLYLINE
  Future<void> _loadPolyline() async {
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
    }
  }

  // MANUAL REFRESH FOR ROUTE + MARKERS
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

  // OPEN GOOGLE MAPS FOR TURN-BY-TURN NAVIGATION
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

  @override
  void dispose() {
    positionStream?.cancel(); // stop GPS tracking when leaving screen
    super.dispose();
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Route to ${widget.siteName}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
      ),

      // GOOGLE MAP WIDGET — SHOWS MARKERS + POLYLINE ROUTE
      body: SafeArea(      // prevents UI from being covered at bottom
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.userLat, widget.userLon),
                zoom: 12,
              ),
              markers: _markers,
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  color: const Color(0xFF004C7A),
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

            // FLOATING REFRESH BUTTON
            Positioned(
              top: 60,
              right: 10,
              child: FloatingActionButton(
                heroTag: "refreshRoute",
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: _refreshRoute,
                child: const Icon(Icons.refresh, color: Colors.blue, size: 28),
              ),
            ),

            // START NAVIGATION BUTTON
            Positioned(
              bottom: 20,
              left: 40,
              right: 60,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMapsNavigation,
                icon: const Icon(Icons.navigation),
                label: const Text("Start Navigation (Google Maps)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
