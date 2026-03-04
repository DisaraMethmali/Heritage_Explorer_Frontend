// frontend/lib/screens/location_screen.dart (GPS + backend logic + SMART AUTO UPDATE)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../services/unity_service.dart';
import 'heritage_screen.dart';
import 'map_route_screen.dart';
import '../utils/config.dart';
import '../state/geo_state.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool isLoading = true;
  String loadingMessage = "Fetching your current location...";
  String userPlace = "";
  String exactAddress = "";
  String nearestSite = "";
  String distance = ""; // shows ROAD distance
  String travelTime = ""; // travel duration text
  int siteId = 0;

  // user coords
  double? _currentLat;
  double? _currentLon;

  // last fetched coords (for smart update) / comment when testing
  // double? _lastLat;
  // double? _lastLon;

  // heritage site coords
  double? _destLat;
  double? _destLon;

  bool isAtHeritageSite = false;
  List<Map<String, dynamic>> eventsList = [];

  Timer? _autoTimer; // SMART AUTO UPDATE TIMER

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  // PULL TO REFRESH → Calls API manually
  Future<void> _manualRefresh() async {
    await _fetchAndSend();
  }

  // INITIAL PERMISSION + FIRST GPS FETCH
  Future<void> _initLocation() async {
    setState(() {
      loadingMessage = "Checking location permissions...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        isLoading = false;
        loadingMessage = "Please enable location services to continue.";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          isLoading = false;
          loadingMessage = "Location permission denied. Please enable it.";
        });
        return;
      }
    }

    setState(() {
      loadingMessage = "Detecting your GPS position...";
    });

    await _fetchAndSend();

    // ENABLE SMART AUTO UPDATE
    _startSmartAutoUpdate();
  }

  // SMART AUTO UPDATE SYSTEM
  // void _startSmartAutoUpdate() {
  //   _autoTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
  //     // Get current location first
  //     Position pos = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     double newLat = pos.latitude;
  //     double newLon = pos.longitude;

  //     // If this is the first run, save and stop here
  //     if (_lastLat == null || _lastLon == null) {
  //       _lastLat = newLat;
  //       _lastLon = newLon;
  //       return;
  //     }

  //     // Check distance moved
  //     double moved = Geolocator.distanceBetween(
  //       _lastLat!, _lastLon!,
  //       newLat, newLon,
  //     );

  //     if (moved < 300) {
  //       return; // NOT enough movement → skip backend call
  //     }

  //     // If moved > 300m → update backend
  //     await _fetchAndSend();

  //     // update last known position
  //     _lastLat = newLat;
  //     _lastLon = newLon;
  //   });
  // }

  // Fake GPS for testing - Disable Auto update during testing
  void _startSmartAutoUpdate() {
    return; // prevents real GPS from overwriting fake GPS
  }

  // GET CURRENT LOCATION + CALL BACKEND
  Future<void> _fetchAndSend() async {
    try {
      setState(() {
        loadingMessage = "Fetching nearby heritage sites...";
      });

      // Position pos = await Geolocator.getCurrentPosition(
      //   desiredAccuracy: LocationAccuracy.high,
      // );

      // // Save user location
      // _currentLat = pos.latitude;
      // _currentLon = pos.longitude;

      // Fake GPS for testing
      // double fakeLat = 7.2902;
      // double fakeLon = 80.6337;

      double fakeLat = 6.042331;
      double fakeLon = 80.208467;

      // Save user location
      _currentLat = fakeLat;
      _currentLon = fakeLon;

      // const backendUrl = "$baseUrl/location";
      const backendUrl = "http://10.0.2.2:5000/location";
      final res = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"latitude": _currentLat, "longitude": _currentLon}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Extract data
        exactAddress = data["place_name"] ?? "";
        userPlace = _shortPlace(exactAddress);
        nearestSite = data["nearest_site"] ?? "";

        // ROAD DISTANCE from backend
        dynamic rd = data["road_distance_km"];
        distance = (rd is double) ? rd.toStringAsFixed(2) : rd.toString();

        // TRAVEL TIME (duration from backend)
        travelTime = data["duration"] ?? "";

        siteId = data["site_id"];
        eventsList = List<Map<String, dynamic>>.from(data["events"]);

        // destination coords from backend
        _destLat = data["site_lat"];
        _destLon = data["site_lon"];

        // “at site” detection using ROAD distance
        double? distValue = double.tryParse(distance);
        isAtHeritageSite = distValue != null && distValue < 0.2;

        // EXPORT TRUTH (ONE LINE ONLY)
        GeoState.isUserNearSite = isAtHeritageSite;

        // if (_currentLat != null && _currentLon != null) {
        //   UnityService.post({
        //     "type": "SYNC_GPS",
        //     "lat": _currentLat,
        //     "lon": _currentLon,
        //   });
        // }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          loadingMessage = "Server error: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        loadingMessage = "Error fetching location: $e";
      });
    }
  }

  // Shortens long address AND removes PLUS CODES if present
  String _shortPlace(String address) {
    List<String> parts = address.split(",");

    // If first part is a Google Plus Code like "2XJ4+MMV"
    if (parts.isNotEmpty && parts[0].contains("+")) {
      // Remove plus code and take next 2 segments (area + city)
      if (parts.length >= 3) {
        return "${parts[1].trim()}, ${parts[2].trim()}";
      }
      return address; // fallback
    }

    // Default behavior: return first two segments
    return parts.take(2).join(",").trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: const Text(
          "Discover Your Heritage",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // MAIN BODY
      body: SafeArea(
        // prevents UI from being covered by the bottom nav bar
        child: Center(
          child: isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_searching,
                      size: 70,
                      color: Color(0xFF004C7A),
                    ),
                    const SizedBox(height: 25),
                    const CircularProgressIndicator(
                      color: Color(0xFFB8860B),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        loadingMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF3E2723),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              // CONTENT AFTER LOADING (CARD FIRST , BUTTONS NEXT WITH PULL TO REFRESH)
              : RefreshIndicator(
                  onRefresh: _manualRefresh, // PULL TO REFRESH ADDED HERE
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // REQUIRED
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // LOCATION CARD
                          Card(
                            elevation: 8,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadowColor: Colors.black26,
                            child: Padding(
                              padding: const EdgeInsets.all(25),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 70,
                                    color: Color(0xFF004C7A),
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    isAtHeritageSite
                                        ? "You are at"
                                        : "You’re currently in",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    userPlace,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB8860B),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  if (!isAtHeritageSite)
                                    Column(
                                      children: [
                                        const Text(
                                          "Exact address:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          exactAddress,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 25),
                                  Divider(color: Colors.grey.shade300),

                                  const SizedBox(height: 20),

                                  if (isAtHeritageSite)
                                    Column(
                                      children: [
                                        const Text(
                                          "You are standing at:",
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          nearestSite,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF004C7A),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        const Text(
                                          "Nearest Heritage Site:",
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          nearestSite,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF004C7A),
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Show DISTANCE and TRAVEL TIME
                                        Text(
                                          "Distance: $distance km away",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        Text(
                                          "Travel time: $travelTime",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // "Explore Nearby Heritage" button
                          ElevatedButton.icon(
                            // Inside location_screen.dart -> ElevatedButton ("Explore Nearby Heritage")
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HeritageScreen(
                                    siteName: nearestSite,
                                    siteId: siteId,
                                    events: eventsList,
                                    currentLat: _currentLat, // Pass real lat
                                    currentLon: _currentLon, // Pass real lon
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.explore_outlined),
                            label: const Text("Explore Nearby Heritage"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB8860B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 14,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // "Show Route on Map" button
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_currentLat != null &&
                                  _currentLon != null &&
                                  _destLat != null &&
                                  _destLon != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapRouteScreen(
                                      userLat: _currentLat!,
                                      userLon: _currentLon!,
                                      destLat: _destLat!,
                                      destLon: _destLon!,
                                      siteName: nearestSite,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text("Show Route on Map"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004C7A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 14,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
