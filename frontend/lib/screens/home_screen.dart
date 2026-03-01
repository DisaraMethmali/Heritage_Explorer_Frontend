// frontend/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../state/navigation_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),

      appBar: AppBar(
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        title: const Text(
          "Heritage Explorer",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // App Identity Icon
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.public,
                  size: 80,
                  color: Color(0xFF004C7A),
                ),
              ),

              const SizedBox(height: 30),

              // Welcome Message
              const Text(
                "Welcome to Heritage Explorer",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004C7A),
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle / Description
              const Text(
                "Discover Sri Lanka’s rich history around you using smart location-based recommendations.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 50),

              // Detect My Location Button
              ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text("Detect My Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8860B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
                onPressed: () {
                  NavigationState.selectedIndex.value = 1; // Location tab
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
