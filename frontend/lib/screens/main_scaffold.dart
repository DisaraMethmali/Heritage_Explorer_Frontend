// lib/screens/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/navigation_state.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

// Original 4 screens
import 'home_screen.dart';
import 'location_screen.dart';
import 'recommendation_screen.dart';
import 'about_screen.dart';

// Heritage Explorer 5 screens
import 'chat/chat_screen.dart';
import 'history/history_screen.dart';
import 'quiz/quiz_screen.dart';
import 'explore/explore_screen.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';
import 'folklore_screen.dart';
import 'anomaly_screen.dart';
import 'feedback_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Heritage Explorer inner tab index
  int _heritageIndex = 0;

  static const _heritageTabs = [
    ChatScreen(),
    HistoryScreen(),
    QuizScreen(),
    ExploreScreen(),
    FeedbackScreen(),
  ];

  static const List<Widget> _originalScreens = [
    HomeScreen(),
    LocationScreen(),
    RecommendationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initHeritageSession();
  }

  void _initHeritageSession() {
    final userId = context.read<AuthProvider>().user?.userId ?? 'guest';
    final sessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    context.read<ChatProvider>().setUserId(userId);
    context.read<ChatProvider>().setSessionId(sessionId);
    context.read<ChatProvider>().loadHistoryFromServer();
  }

  Future<void> _logout() async {
    context.read<ChatProvider>().clearAll();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NavigationState.selectedIndex,
      builder: (context, originalIndex, _) {
        // originalIndex 1 = "Heritage" tab → show 5-tab heritage section
        final bool onHeritage = originalIndex == 1;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F0E8),
          body: onHeritage
              ? IndexedStack(index: _heritageIndex, children: _heritageTabs)
              : _originalScreens[_toOriginalScreenIndex(originalIndex)],
          bottomNavigationBar: onHeritage
              ? _buildHeritageNavBar()
              : _buildOriginalNavBar(originalIndex),
        );
      },
    );
  }

  // Maps top-level index (0,2,3) → original screens list index (0,1,2)
 int _toOriginalScreenIndex(int i) {
  switch (i) {
    case 0:
      return 0; // Home
    case 2:
      return 1; // Location
    case 3:
      return 2; // Recommend
    case 4:
      return 3; // Profile
    default:
      return 0; // fallback to Home
  }
}

  // ── Original 4-tab nav bar ───────────────────────────────────────────────
  Widget _buildOriginalNavBar(int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF004C7A),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: (index) => NavigationState.selectedIndex.value = index,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_edu_outlined),
          activeIcon: Icon(Icons.history_edu),
          label: 'Explore',        // tapping this opens the 5-tab section
        ),
        BottomNavigationBarItem(
                icon: Icon(Icons.location_on),
                label: "Location",
              ),
        BottomNavigationBarItem(
          icon: Icon(Icons.recommend),
          label: 'Recommend',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  // ── Heritage 5-tab nav bar ───────────────────────────────────────────────
  Widget _buildHeritageNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE8D5B0), width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Back arrow to return to the original nav
              _backButton(),
              _heritageNavItem(0, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
              _heritageNavItem(1, Icons.history, Icons.history, 'History'),
              _heritageNavItem(2, Icons.quiz_outlined, Icons.quiz, 'Quiz'),
              _heritageNavItem(3, Icons.auto_stories_outlined, Icons.auto_stories, 'Legends'),
              _heritageNavItem(4, Icons.feedback_outlined, Icons.feedback, 'Feedback'),
              ],
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () => NavigationState.selectedIndex.value = 0,
      child: const SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF8B4513)),
            Text('Back', style: TextStyle(color: Color(0xFF8B4513), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _heritageNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _heritageIndex == index;
    const activeColor = Color(0xFF8B4513);
    const inactiveColor = Color(0xFFAD9680);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _heritageIndex = index),
        splashColor: const Color(0xFFD4A96A).withOpacity(0.2),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 32 : 0,
              height: isSelected ? 3 : 0,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10.5,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}