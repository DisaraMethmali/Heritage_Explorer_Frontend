// frontend/lib/screens/location_screen.dart (GPS + backend logic + SMART AUTO UPDATE)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _LocationScreenState extends State<LocationScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoading = true;
  String loadingMessage = "Fetching your current location...";
  String userPlace = "";
  String exactAddress = "";
  String nearestSite = "";
  String distance = "";
  String travelTime = "";
  int siteId = 0;

  double? _currentLat;
  double? _currentLon;

  // last fetched coords (for smart update) / comment when testing
  // double? _lastLat; 
  // double? _lastLon;

  double? _destLat;
  double? _destLon;

  bool isAtHeritageSite = false;
  List<Map<String, dynamic>> eventsList = [];

  Map<String, dynamic>? weather;
  Map<String, dynamic>? disaster;
  String? safetyStatus;

  Timer? _autoTimer;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late AnimationController _contentController;
  late Animation<double> _shimmer;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _contentController, curve: Curves.easeOutCubic));

    _initLocation();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _shimmerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _manualRefresh() async {
    await _fetchAndSend();
  }

  Future<void> _initLocation() async {
    setState(() => loadingMessage = "Checking location permissions...");

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

    setState(() => loadingMessage = "Detecting your GPS position...");
    await _fetchAndSend();
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
    return;
  }

  Future<void> _fetchAndSend() async {
    try {
      setState(() => loadingMessage = "Fetching nearby heritage sites...");

      // Position pos = await Geolocator.getCurrentPosition(
      //   desiredAccuracy: LocationAccuracy.high,
      // );

      // // Save user location
      // _currentLat = pos.latitude;
      // _currentLon = pos.longitude;

      // Fake GPS for testing
      double fakeLat = 7.2902; //Galle fort: 6.0488
      double fakeLon = 80.6337; //Galle fort: 80.2205
      _currentLat = fakeLat;
      _currentLon = fakeLon;

      const backendUrl = "$baseUrl/location";
      final res = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"latitude": _currentLat, "longitude": _currentLon}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        exactAddress = data["place_name"] ?? "";
        userPlace = _shortPlace(exactAddress);
        nearestSite = data["nearest_site"] ?? "";

        dynamic rd = data["road_distance_km"];
        distance = (rd is double) ? rd.toStringAsFixed(2) : rd.toString();

        travelTime = data["duration"] ?? "";
        siteId = data["site_id"];
        eventsList = List<Map<String, dynamic>>.from(data["events"]);

        weather = data["weather"];
        disaster = data["disaster"];
        safetyStatus = data["safety_status"];

        _destLat = data["site_lat"];
        _destLon = data["site_lon"];

        double? distValue = double.tryParse(distance);
        isAtHeritageSite = distValue != null && distValue < 0.2;
        GeoState.isUserNearSite = isAtHeritageSite;

        // Unity GPS Sync
        // if (_currentLat != null && _currentLon != null) {
        //   UnityService.post({
        //     "type": "SYNC_GPS",
        //     "lat": _currentLat,
        //     "lon": _currentLon,
        //   });
        // }

        setState(() => isLoading = false);
        _contentController.forward(from: 0);
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

  String _shortPlace(String address) {
    List<String> parts = address.split(",");
    if (parts.isNotEmpty && parts[0].contains("+")) {
      if (parts.length >= 3) return "${parts[1].trim()}, ${parts[2].trim()}";
      return address;
    }
    return parts.take(2).join(",").trim();
  }

  // ── Safety Badge ───────────────────────────────────────────────────────────

  Widget _buildSafetyBadge(String status) {
    Color bg, fg;
    IconData icon;
    switch (status) {
      case "SAFE":
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.shield_outlined;
        break;
      case "CAUTION":
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        icon = Icons.warning_amber_outlined;
        break;
      case "UNSAFE":
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.dangerous_outlined;
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoadingView() : _buildContentView(),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 18, color: Color(0xFFFFD700)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'DISCOVER HERITAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              Text(
                'Your Location',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _manualRefresh,
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 5, bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'REFRESH',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Loading View ───────────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001233), Color(0xFF023E8A), Color(0xFF0077B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
        AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) => Positioned.fill(
              child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
        ),
        SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            width: 1),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF0A4FA3), Color(0xFF001845)],
                          center: Alignment(-0.3, -0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_searching,
                          size: 36, color: Color(0xFFFFD700)),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                const CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    loadingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFADD8E6),
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Content View ───────────────────────────────────────────────────────────

  Widget _buildContentView() {
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _contentFade,
      child: SlideTransition(
        position: _contentSlide,
        child: RefreshIndicator(
          onRefresh: _manualRefresh,
          color: const Color(0xFFFFD700),
          backgroundColor: const Color(0xFF002D72),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ── Hero banner ──────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      height: screenHeight * 0.32,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF001233),
                            Color(0xFF023E8A),
                            Color(0xFF0077B6)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    Positioned.fill(
                        child: CustomPaint(painter: _MeshPainter())),
                    AnimatedBuilder(
                      animation: _shimmer,
                      builder: (context, _) => Positioned.fill(
                          child: CustomPaint(
                              painter: _ShimmerPainter(_shimmer.value))),
                    ),

                    // Hero text content
                    SizedBox(
                      height: screenHeight * 0.32,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isAtHeritageSite
                                      ? 'YOU ARE AT A HERITAGE SITE'
                                      : 'NEAREST HERITAGE SITE',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                nearestSite,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                ),
                              ),

                              if (!isAtHeritageSite) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "$distance km away  ·  $travelTime",
                                  style: const TextStyle(
                                    color: Color(0xFFADD8E6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Wave cutout
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(double.infinity, 36),
                        painter: _WavePainter(),
                      ),
                    ),
                  ],
                ),

                // ── Body ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // ── Conditions card ───────────────────────────────
                      if (!isAtHeritageSite) ...[
                        _SectionLabel(label: 'SITE CONDITIONS'),
                        const SizedBox(height: 12),

                        _InfoCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  if (safetyStatus != null)
                                    _buildSafetyBadge(safetyStatus!),
                                  const Spacer(),
                                  if (weather != null &&
                                      weather!["icon"] != null)
                                    Image.network(
                                      "https:${weather!["icon"]}",
                                      width: 36,
                                      height: 36,
                                    ),
                                  if (weather != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      weather!["condition"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334466),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              if (weather != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _WeatherStat(
                                        icon: Icons.thermostat_outlined,
                                        label: "Temp",
                                        value:
                                            "${weather!["temperature_c"] ?? "--"}°C",
                                      ),
                                      _WeatherStat(
                                        icon: Icons.water_drop_outlined,
                                        label: "Humidity",
                                        value:
                                            "${weather!["humidity"] ?? "--"}%",
                                      ),
                                      _WeatherStat(
                                        icon: Icons.air,
                                        label: "Wind",
                                        value:
                                            "${weather!["wind_kph"] ?? "--"} km/h",
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (disaster != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: disaster!["has_alert"] == true
                                        ? (disaster!["risk_level"] == "High"
                                            ? const Color(0xFFFFEBEE)
                                            : const Color(0xFFFFF8E1))
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        disaster!["has_alert"] == true
                                            ? Icons.warning_amber_outlined
                                            : Icons.check_circle_outline,
                                        size: 18,
                                        color: disaster!["has_alert"] == true
                                            ? (disaster!["risk_level"] == "High"
                                                ? const Color(0xFFC62828)
                                                : const Color(0xFFE65100))
                                            : const Color(0xFF2E7D32),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          disaster!["has_alert"] == true
                                              ? disaster!["message"] ??
                                                  "Weather Alert"
                                              : "No active disaster alerts",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: disaster!["has_alert"] == true
                                                ? (disaster!["risk_level"] ==
                                                        "High"
                                                    ? const Color(0xFFC62828)
                                                    : const Color(0xFFE65100))
                                                : const Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],

                      // ── Location card ─────────────────────────────────
                      _SectionLabel(label: 'YOUR LOCATION'),
                      const SizedBox(height: 12),

                      _InfoCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0077B6)
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.my_location,
                                      color: Color(0xFF0077B6), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAtHeritageSite
                                            ? "You are at"
                                            : "You're currently in",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF90A4C4),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userPlace,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFB800),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            if (!isAtHeritageSite &&
                                exactAddress.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.place_outlined,
                                        size: 16, color: Color(0xFF90A4C4)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        exactAddress,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF445577),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Action buttons ────────────────────────────────
                      _SectionLabel(label: 'EXPLORE'),
                      const SizedBox(height: 14),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HeritageScreen(
                                siteName: nearestSite,
                                siteId: siteId,
                                events: eventsList,
                                currentLat: _currentLat,
                                currentLon: _currentLon,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFB800),
                                Color(0xFFFFD700),
                                Color(0xFFFFC200)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF001845)
                                      .withValues(alpha: 0.12),
                                ),
                                child: const Icon(Icons.explore_outlined,
                                    color: Color(0xFF001845), size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Explore Nearby Heritage',
                                style: TextStyle(
                                  color: Color(0xFF001845),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                              Color(0xFFFFD700),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () {
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
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF002D72)
                                  .withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF002D72)
                                    .withValues(alpha: 0.07),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF002D72)
                                      .withValues(alpha: 0.08),
                                ),
                                child: const Icon(Icons.map_outlined,
                                    color: Color(0xFF002D72), size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Show Route on Map',
                                style: TextStyle(
                                  color: Color(0xFF002D72),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Center(
                        child: Text(
                          "Pull down to refresh your location",
                          style: TextStyle(
                            color: Color(0xFF90A4C4),
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Components ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF002D72),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          top: const BorderSide(color: Color(0xFFFFD700), width: 2.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002D72).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeatherStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0077B6)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF223355))),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF90A4C4))),
      ],
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    p.color = const Color(0xFFFFD700).withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 1.05, -20), size.width * 0.65, p);

    p.color = const Color(0xFF48CAE4).withValues(alpha: 0.09);
    canvas.drawCircle(Offset(-30, size.height * 0.9), size.width * 0.55, p);

    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.03);
    p.strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x + 60, size.height), p);
    }

    final dot = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.drawCircle(
            Offset(size.width - 30 - i * 22.0, 80 + j * 22.0), 1.8, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(progress - 1, 0),
      end: Alignment(progress, 0),
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.04),
        Colors.transparent,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) =>
      old.progress != progress;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F8FF)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.35);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.7, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}