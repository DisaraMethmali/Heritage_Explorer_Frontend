// frontend/lib/screens/vr_screen.dart

import 'package:flutter/material.dart';

class VRScreen extends StatelessWidget {
  final bool geoSyncEnabled;
  final bool demoModeEnabled;

  const VRScreen({
    super.key,
    required this.geoSyncEnabled,
    required this.demoModeEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "VR Experience",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.view_in_ar,
                size: 90,
                color: Color(0xFF004C7A),
              ),
              const SizedBox(height: 24),
              const Text(
                "VR Experience\nStill in Development",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004C7A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "GeoSync: ${geoSyncEnabled ? "ON" : "OFF"}\n"
                "Demo Mode: ${demoModeEnabled ? "ON" : "OFF"}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
