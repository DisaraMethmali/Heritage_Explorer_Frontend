import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/unity_service.dart';

class VRScreen extends StatefulWidget {
  final bool geoSyncEnabled;
  final bool demoModeEnabled;
  final String siteName;

  const VRScreen({
    super.key,
    required this.geoSyncEnabled,
    required this.demoModeEnabled,
    required this.siteName,
  });

  @override
  State<VRScreen> createState() => _VRScreenState();
}

class _VRScreenState extends State<VRScreen> {
  bool isHistorical = false;
  double _heading = 0.0;
  double _battery = 0.0; //
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    // High-frequency polling for smooth compass movement
    _statusTimer = Timer.periodic(
      const Duration(milliseconds: 100), // Faster polling
      (_) => _updateStatus(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    try {
      final res = await http
          .post(Uri.parse(UnityService.unityUrl))
          .timeout(const Duration(seconds: 1));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _heading = (data['heading'] ?? 0.0).toDouble(); //
            _battery = (data['battery'] ?? 0.0).toDouble().abs(); //
          });
        }
      }
    } catch (_) {}
  }

  void _toggleEra(bool showPast) async {
    setState(() => isHistorical = showPast);
    await UnityService.post({
      "type": "SWITCH_LOCATION",
      "location": widget.siteName.contains("Galle") ? "Galle" : "TempleOfTooth",
      "era": showPast ? "Historical" : "Modern",
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Control Center",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          // --- BATTERY INDICATOR ---
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _battery > 20
                      ? Icons.battery_charging_full
                      : Icons.battery_alert,
                  color: _battery > 20 ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  "${_battery.toInt()}%",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // --- REAL-TIME COMPASS ---
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer decorative ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 8,
                      ),
                    ),
                  ),
                  // Rotating Compass Plate
                  AnimatedRotation(
                    turns: _heading / 360,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.explore_outlined,
                      size: 200,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  // Static North Indicator
                  Positioned(
                    top: 20,
                    child: Column(
                      children: [
                        const Text(
                          "N",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 10,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- VR STATUS CARD ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Text(
                  widget.siteName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statusBadge(
                      widget.geoSyncEnabled ? "GPS ACTIVE" : "GPS OFF",
                      widget.geoSyncEnabled,
                    ),
                    const SizedBox(width: 8),
                    _statusBadge("DEMO MODE", widget.demoModeEnabled),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "${_heading.toInt()}°",
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- ERA SWITCHER ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _eraButton(
                    label: "PRESENT",
                    icon: Icons.wb_sunny_outlined,
                    isActive: !isHistorical,
                    onTap: () => _toggleEra(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _eraButton(
                    label: "PAST",
                    icon: Icons.auto_awesome_motion_outlined,
                    isActive: isHistorical,
                    onTap: () => _toggleEra(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? Colors.greenAccent.withOpacity(0.5)
              : Colors.redAccent.withOpacity(0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.greenAccent : Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _eraButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF38BDF8)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white38,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
