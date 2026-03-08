// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'register_screen.dart';
import '../admin_login_screen.dart';
import '../main_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late AnimationController _contentController;
  late Animation<double>   _shimmer;
  late Animation<double>   _contentFade;
  late Animation<Offset>   _contentSlide;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _navy     = Color(0xFF001233);
  static const Color _navyMid  = Color(0xFF002D72);
  static const Color _blue     = Color(0xFF023E8A);
  static const Color _blueMid  = Color(0xFF0077B6);
  static const Color _gold     = Color(0xFFFFD700);
  static const Color _goldDeep = Color(0xFFFFB800);
  static const Color _pageBg   = Color(0xFFF5F8FF);
  static const Color _textMain = Color(0xFF001845);
  static const Color _textSub  = Color(0xFF90A4C4);
  static const Color _inputBg  = Color(0xFFF0F6FF);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _contentController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _shimmerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await context.read<AuthProvider>().login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final userId = context.read<AuthProvider>().user?.userId;
      if (userId != null) {
        context.read<ChatProvider>().setUserId(userId);
        await context.read<ChatProvider>().loadHistoryFromServer();
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScaffold()),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    final isLoading = context.watch<AuthProvider>().isLoading;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          // ── Full page background ─────────────────────────────────────
          Column(
            children: [
              // Hero gradient top
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Container(
                        height: screenHeight * 0.42,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_navy, _blue, _blueMid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Positioned.fill(
                          child: CustomPaint(painter: _MeshPainter())),
                      Positioned.fill(
                          child: CustomPaint(
                              painter: _ShimmerPainter(_shimmer.value))),
                    ],
                  );
                },
              ),
              // Light body bottom
              Expanded(child: Container(color: _pageBg)),
            ],
          ),

          // ── Wave transition ──────────────────────────────────────────
          Positioned(
            top: screenHeight * 0.42 - 36,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 52),
              painter: _WavePainter(),
            ),
          ),

          // ── Scrollable content ───────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.06),

                        // ── Medallion ──────────────────────────────────
                        _buildMedallion(),

                        SizedBox(height: screenHeight * 0.03),

                        // ── App name ───────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: _gold.withValues(alpha: 0.4),
                                width: 1),
                          ),
                          child: const Text(
                            'HERITAGE EXPLORER',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Sign in to continue exploring',
                          style: TextStyle(
                            color: Color(0xFFADD8E6),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.055),

                        // ── Form card ──────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border(
                              top: BorderSide(
                                  color: _gold.withValues(alpha: 0.6),
                                  width: 2.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withValues(alpha: 0.10),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section label
                              _SectionLabel(label: 'YOUR CREDENTIALS'),
                              const SizedBox(height: 18),

                              // Username field
                              _buildField(
                                controller: _usernameCtrl,
                                label: 'Username',
                                icon: Icons.person_outline,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter username'
                                    : null,
                              ),

                              const SizedBox(height: 14),

                              // Password field
                              _buildField(
                                controller: _passwordCtrl,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscure: _obscure,
                                suffixIcon: GestureDetector(
                                  onTap: () =>
                                      setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _textSub,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter password'
                                    : null,
                              ),

                              const SizedBox(height: 24),

                              // Sign in button (gold CTA)
                              GestureDetector(
                                onTap: isLoading ? null : _login,
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    gradient: isLoading
                                        ? null
                                        : const LinearGradient(
                                            colors: [
                                              _goldDeep,
                                              _gold,
                                              Color(0xFFFFC200),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    color: isLoading
                                        ? const Color(0xFFDDE6F0)
                                        : null,
                                    boxShadow: isLoading
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: _gold.withValues(
                                                  alpha: 0.45),
                                              blurRadius: 20,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _navyMid,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _navy.withValues(
                                                      alpha: 0.12),
                                                ),
                                                child: const Icon(
                                                    Icons.login_rounded,
                                                    color: _navy,
                                                    size: 16),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  color: _navy,
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                              // Gold shimmer underline
                              const SizedBox(height: 5),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _gold,
                                      Color(0xFFFFA500),
                                      _gold,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Admin login (navy outlined)
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminLoginScreen()),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: _navyMid.withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _navy.withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _navyMid.withValues(
                                              alpha: 0.08),
                                        ),
                                        child: const Icon(
                                            Icons.admin_panel_settings_outlined,
                                            color: _navyMid,
                                            size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Admin Login',
                                        style: TextStyle(
                                          color: _navyMid,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?  ",
                              style:
                                  TextStyle(color: _textSub, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: _navyMid,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Medallion ──────────────────────────────────────────────────────────────

  Widget _buildMedallion() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: _gold.withValues(alpha: 0.18), width: 1),
          ),
        ),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: _gold.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF0A4FA3), _navy],
              center: Alignment(-0.3, -0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.30),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.public, size: 38, color: _gold),
        ),
      ],
    );
  }

  // ── Text field ─────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
          color: _textMain, fontSize: 14, fontWeight: FontWeight.w500),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSub, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _textSub, size: 20),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: _navyMid.withValues(alpha: 0.12), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _navyMid, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC62828)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFC62828), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
      ),
    );
  }
}

// ── Section label (shared design token) ──────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
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
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
      ],
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
            Offset(size.width - 30 - i * 22.0, 40 + j * 22.0), 1.8, dot);
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
    path.moveTo(0, size.height * 0.55);
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