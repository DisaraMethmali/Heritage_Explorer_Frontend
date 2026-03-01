// frontend/lib/screens/splash_screen.dart (attractive loading page)

import 'dart:async';
import 'package:flutter/material.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(   // Added SafeArea 
        child: Container(
          // Beautiful warm gradient background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFD580), // soft golden
                Color(0xFF87CEEB), // light sky blue
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),

          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rounded logo card
                  Container(
                    height: 140,
                    width: 140,
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
                    child: const Center(
                      child: Icon(
                        Icons.public,
                        color: Color(0xFF1565C0),
                        size: 80,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // App name
                  const Text(
                    "Heritage Explorer",
                    style: TextStyle(
                      color: Color(0xFF004B8D),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                    ),
                  ),

                  // Tagline
                  const SizedBox(height: 10),
                  const Text(
                    "Discover Sri Lanka’s Living History",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress indicator
                  const CircularProgressIndicator(
                    color: Color(0xFF1565C0),
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
