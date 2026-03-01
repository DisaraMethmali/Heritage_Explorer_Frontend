// frontend/lib/screens/about_screen.dart

import 'package:flutter/material.dart';


class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      body: const Center(
        child: Text(
          "Heritage Explorer\n\nA location-based heritage discovery app.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
