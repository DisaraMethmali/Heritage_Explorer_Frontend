// frontend/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/navigation_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _cardsController;
  late AnimationController _shimmerController;

  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _heroController, curve: Curves.easeOutCubic));

    _cardsFade =
        CurvedAnimation(parent: _cardsController, curve: Curves.easeOut);
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _cardsController, curve: Curves.easeOutCubic));

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    _heroController.forward();
    Future.delayed(
        const Duration(milliseconds: 320), () => _cardsController.forward());
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardsController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(
        children: [
          _MiniCrest(),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'HERITAGE EXPLORER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              Text(
                'Sri Lanka',
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
        Container(
          margin: const EdgeInsets.only(right: 16, top: 5, bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'EXPLORE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.41;

    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Stack(
          children: [
            // Background gradient
            Container(
              height: heroHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF001233),
                    Color(0xFF023E8A),
                    Color(0xFF0077B6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Mesh overlay
            Positioned.fill(child: CustomPaint(painter: _MeshPainter())),

            // Shimmer sweep
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) =>
                    CustomPaint(painter: _ShimmerPainter(_shimmer.value)),
              ),
            ),

            // Text content
            SizedBox(
              height: heroHeight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'DISCOVER · EXPLORE · EXPERIENCE',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Welcome to\nHeritage Explorer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Discover Sri Lanka's rich history around you\nusing smart location-based recommendations.",
                        style: TextStyle(
                          color: Color(0xFFADD8E6),
                          fontSize: 13.5,
                          height: 1.55,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom wave
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 40),
                painter: _WavePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return FadeTransition(
      opacity: _cardsFade,
      child: SlideTransition(
        position: _cardsSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              _SectionLabel(label: 'FEATURES'),
              const SizedBox(height: 12),

              // Feature cards
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.location_on_outlined,
                      title: 'Nearby\nSites',
                      accent: const Color(0xFF0077B6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.auto_stories_outlined,
                      title: 'History &\nStories',
                      accent: const Color(0xFF023E8A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.map_outlined,
                      title: 'Explore\nMap',
                      accent: const Color(0xFF001233),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _SectionLabel(label: 'GET STARTED'),
              const SizedBox(height: 14),

              // CTA button
              _CTAButton(
                onPressed: () {
                  NavigationState.selectedIndex.value = 2;
                },
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  "We'll use your GPS to find heritage sites near you",
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
      ),
    );
  }
}

// ── Components ────────────────────────────────────────────────────────────────

class _MiniCrest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: const Icon(Icons.public, size: 18, color: Color(0xFFFFD700)),
    );
  }
}

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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;

  const _FeatureCard(
      {required this.icon, required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border(top: BorderSide(color: const Color(0xFFFFD700), width: 2.5)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CTAButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CTAButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB800), Color(0xFFFFD700), Color(0xFFFFC200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.45),
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
                color: const Color(0xFF001845).withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.my_location,
                  color: Color(0xFF001845), size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Detect My Location',
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
            Offset(size.width - 30 - i * 22.0, 110 + j * 22.0), 1.8, dot);
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