// lib/screens/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  int _heritageIndex = 0;

  // ── Animation for tab switch ───────────────────────────────────────────────
  late AnimationController _tabAnimController;
  late Animation<double> _tabFade;

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
    _tabAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _tabFade =
        CurvedAnimation(parent: _tabAnimController, curve: Curves.easeOut);
    _tabAnimController.forward();
    _initHeritageSession();
  }

  @override
  void dispose() {
    _tabAnimController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

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

  int _toOriginalScreenIndex(int i) {
    switch (i) {
      case 0:
        return 0;
      case 2:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  void _switchHeritage(int index) {
    _tabAnimController.forward(from: 0);
    setState(() => _heritageIndex = index);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NavigationState.selectedIndex,
      builder: (context, originalIndex, _) {
        final bool onHeritage = originalIndex == 1;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FF),
          body: FadeTransition(
            opacity: _tabFade,
            child: onHeritage
                ? IndexedStack(index: _heritageIndex, children: _heritageTabs)
                : _originalScreens[_toOriginalScreenIndex(originalIndex)],
          ),
          bottomNavigationBar: onHeritage
              ? _buildHeritageNavBar()
              : _buildOriginalNavBar(originalIndex),
        );
      },
    );
  }

  // ── Original nav bar ───────────────────────────────────────────────────────

  Widget _buildOriginalNavBar(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001845).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _OrigNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: () {
                  _tabAnimController.forward(from: 0);
                  NavigationState.selectedIndex.value = 0;
                },
              ),
              _OrigNavItem(
                icon: Icons.history_edu_outlined,
                activeIcon: Icons.history_edu,
                label: 'Explore',
                index: 1,
                currentIndex: currentIndex,
                onTap: () {
                  _tabAnimController.forward(from: 0);
                  NavigationState.selectedIndex.value = 1;
                },
              ),
              _OrigNavItem(
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on,
                label: 'Location',
                index: 2,
                currentIndex: currentIndex,
                onTap: () {
                  _tabAnimController.forward(from: 0);
                  NavigationState.selectedIndex.value = 2;
                },
              ),
              _OrigNavItem(
                icon: Icons.recommend_outlined,
                activeIcon: Icons.recommend,
                label: 'Recommend',
                index: 3,
                currentIndex: currentIndex,
                onTap: () {
                  _tabAnimController.forward(from: 0);
                  NavigationState.selectedIndex.value = 3;
                },
              ),
              _OrigNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 4,
                currentIndex: currentIndex,
                onTap: () {
                  _tabAnimController.forward(from: 0);
                  NavigationState.selectedIndex.value = 4;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Heritage nav bar ───────────────────────────────────────────────────────

  Widget _buildHeritageNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF001845),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001845).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  _tabAnimController.forward(from: 0);
                  NavigationState.selectedIndex.value = 0;
                },
                child: Container(
                  width: 44,
                  height: 64,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                              width: 1),
                          color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 12, color: Color(0xFFFFD700)),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Thin vertical divider
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              ),

              // Heritage tab items
              _HeritageNavItem(
                index: 0,
                currentIndex: _heritageIndex,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
                onTap: () => _switchHeritage(0),
              ),
              _HeritageNavItem(
                index: 1,
                currentIndex: _heritageIndex,
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'History',
                onTap: () => _switchHeritage(1),
              ),
              _HeritageNavItem(
                index: 2,
                currentIndex: _heritageIndex,
                icon: Icons.quiz_outlined,
                activeIcon: Icons.quiz,
                label: 'Quiz',
                onTap: () => _switchHeritage(2),
              ),
              _HeritageNavItem(
                index: 3,
                currentIndex: _heritageIndex,
                icon: Icons.auto_stories_outlined,
                activeIcon: Icons.auto_stories,
                label: 'Legends',
                onTap: () => _switchHeritage(3),
              ),
              _HeritageNavItem(
                index: 4,
                currentIndex: _heritageIndex,
                icon: Icons.feedback_outlined,
                activeIcon: Icons.feedback,
                label: 'Feedback',
                onTap: () => _switchHeritage(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Original nav item ─────────────────────────────────────────────────────────

class _OrigNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _OrigNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 24 : 0,
              height: isSelected ? 3 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected
                    ? const Color(0xFF002D72)
                    : const Color(0xFFAABBCC),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF002D72)
                    : const Color(0xFFAABBCC),
                letterSpacing: isSelected ? 0.3 : 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Heritage nav item ─────────────────────────────────────────────────────────

class _HeritageNavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _HeritageNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gold indicator pill above icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 24 : 0,
              height: isSelected ? 3 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF5577AA),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF5577AA),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}