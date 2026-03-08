// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Pulse for the logo ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Shimmer sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    await context.read<AuthProvider>().initialize();
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const MainScaffold() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Deep navy base ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF001845),
                  Color(0xFF002D72),
                  Color(0xFF003399),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Decorative geometric arcs ────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _ArcPainter()),
          ),

          // ── Dot-grid texture overlay ─────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // ── Gold accent blobs ────────────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _GlowBlob(
              color: const Color(0xFFFFD700).withValues(alpha: 0.18),
              size: 280,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _GlowBlob(
              color: const Color(0xFFFFB800).withValues(alpha: 0.12),
              size: 320,
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_scaleAnimation, _pulseAnimation, _shimmerAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.scale(
                            scale: _pulseAnimation.value,
                            child: _buildLogo(_shimmerAnimation.value),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 44),

                    // Title
                    AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: child,
                        );
                      },
                      child: Column(
                        children: [
                          // Decorative divider top
                          _GoldDivider(),
                          const SizedBox(height: 20),

                          // App name with letter-spaced gold gradient
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFFFFE066),
                                Color(0xFFFFD700),
                                Color(0xFFFFA500),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'HERITAGE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'EXPLORER',
                            style: TextStyle(
                              color: Color(0xFFB8D4FF),
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 10,
                              height: 1.0,
                            ),
                          ),

                          const SizedBox(height: 20),
                          _GoldDivider(),
                          const SizedBox(height: 22),

                          // Tagline
                          const Text(
                            'Discover Sri Lanka\'s Living History',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8AABDB),
                              fontSize: 14.5,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 72),

                    // Loading indicator
                    AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.5),
                        child: child,
                      ),
                      child: _buildLoader(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(double shimmerX) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFFF0A0),
                  Color(0xFFFFD700),
                  Color(0xFF002D72),
                  Color(0xFFFFD700),
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),
          // Inner navy circle
          Container(
            width: 148,
            height: 148,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFF003399), Color(0xFF001845)],
                center: Alignment(-0.3, -0.3),
              ),
            ),
          ),
          // Shimmer overlay
          ClipOval(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                return Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment(shimmerX - 1, 0),
                      end: Alignment(shimmerX + 1, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Icon
          const Icon(
            Icons.public,
            color: Color(0xFFFFD700),
            size: 72,
          ),
          // Small star accents
          ..._buildStarDots(),
        ],
      ),
    );
  }

  List<Widget> _buildStarDots() {
    const positions = [
      Offset(24, 24),
      Offset(136, 30),
      Offset(18, 128),
      Offset(140, 132),
    ];
    return positions
        .map(
          (p) => Positioned(
            left: p.dx,
            top: p.dy,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE566),
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildLoader() {
    return Column(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFFFFD700),
            ),
            backgroundColor: const Color(0xFF003399).withValues(alpha: 0.4),
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Loading…',
          style: TextStyle(
            color: Color(0xFF6A92C4),
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ── Decorative widgets ────────────────────────────────────────────────────────

class _GoldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0xFFFFD700)],
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFD700),
          ),
        ),
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD700), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ── Custom painters ───────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Large arc – top right
    paint.color = const Color(0xFFFFD700).withValues(alpha: 0.08);
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(size.width * 0.85, size.height * 0.1),
          width: size.width * 1.1,
          height: size.width * 1.1),
      0,
      3.14 * 2,
      false,
      paint,
    );

    // Medium arc – bottom left
    paint.color = const Color(0xFF5599FF).withValues(alpha: 0.1);
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(size.width * 0.15, size.height * 0.88),
          width: size.width * 0.9,
          height: size.width * 0.9),
      0,
      3.14 * 2,
      false,
      paint,
    );

    // Horizontal rule accent
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.06);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.52, size.width, 1), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}