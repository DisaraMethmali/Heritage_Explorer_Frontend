// frontend/lib/screens/main_scaffold.dart (Bottom Navigation Scaffold - Main container for the app after splash.)

import 'package:flutter/material.dart';

import '../state/navigation_state.dart';
import 'home_screen.dart';
import 'location_screen.dart';
import 'recommendation_screen.dart';
import 'about_screen.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NavigationState.selectedIndex,
      builder: (context, currentIndex, _) {
        return Scaffold(
          body: _screens[currentIndex],

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF004C7A),
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              NavigationState.selectedIndex.value = index;
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on),
                label: "Location",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.recommend),
                label: "Recommend",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                label: "About",
              ),
            ],
          ),
        );
      },
    );
  }

  static const List<Widget> _screens = [
    HomeScreen(),
    LocationScreen(),
    RecommendationScreen(),
    AboutScreen(),
  ];
}
