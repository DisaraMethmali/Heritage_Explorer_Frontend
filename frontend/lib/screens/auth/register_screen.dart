// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _fullNameCtrl  = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscure        = true;
  String _ageGroup     = 'adult';
  String _expertiseLevel = 'tourist';

  final _ageGroups       = ['child', 'teen', 'adult', 'senior'];
  final _expertiseLevels = ['child', 'student', 'tourist', 'researcher'];

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

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late AnimationController _contentController;
  late Animation<double>   _shimmer;
  late Animation<double>   _contentFade;
  late Animation<Offset>   _contentSlide;

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
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _contentController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _shimmerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await context.read<AuthProvider>().register(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          ageGroup: _ageGroup,
          expertiseLevel: _expertiseLevel,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created! Please sign in.'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    final isLoading      = context.watch<AuthProvider>().isLoading;
    final screenHeight   = MediaQuery.of(context).size.height;
    final heroHeight     = screenHeight * 0.30;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          // ── Background layers ──────────────────────────────────────────
          Column(
            children: [
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) => Stack(
                  children: [
                    Container(
                      height: heroHeight,
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
                ),
              ),
              Expanded(child: Container(color: _pageBg)),
            ],
          ),

          // Wave transition
          Positioned(
            top: heroHeight - 32,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 48),
              painter: _WavePainter(),
            ),
          ),

          // ── Scrollable content ─────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _gold.withValues(alpha: 0.6),
                                  width: 1),
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 14),
                          ),
                        ),

                        SizedBox(height: heroHeight * 0.14),

                        // Hero identity pill + title
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: _gold.withValues(alpha: 0.4), width: 1),
                          ),
                          child: const Text(
                            'HERITAGE EXPLORER',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Join the heritage exploration community',
                          style: TextStyle(
                            color: Color(0xFFADD8E6),
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                          ),
                        ),

                        SizedBox(height: heroHeight * 0.28),

                        // ── Form card ────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: const Border(
                              top: BorderSide(color: _gold, width: 2.5),
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
                              // ── Account details ──────────────────────
                              const _SectionLabel(label: 'ACCOUNT DETAILS'),
                              const SizedBox(height: 16),

                              _buildField(
                                controller: _usernameCtrl,
                                label: 'Username',
                                icon: Icons.person_outline,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length < 3) return 'Min 3 characters';
                                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v))
                                    return 'Only letters, numbers, underscore';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildField(
                                controller: _fullNameCtrl,
                                label: 'Full Name',
                                icon: Icons.badge_outlined,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),

                              _buildField(
                                controller: _emailCtrl,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (!v.contains('@')) return 'Enter valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

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
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length < 6) return 'Min 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildField(
                                controller: _confirmCtrl,
                                label: 'Confirm Password',
                                icon: Icons.lock_outline,
                                obscure: _obscure,
                                validator: (v) =>
                                    v != _passwordCtrl.text
                                        ? 'Passwords do not match'
                                        : null,
                              ),

                              const SizedBox(height: 22),

                              // ── Age group ────────────────────────────
                              const _SectionLabel(label: 'AGE GROUP'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _ageGroups.map((ag) {
                                  final selected = _ageGroup == ag;
                                  return _ChoiceChip(
                                    label: ag,
                                    selected: selected,
                                    onTap: () =>
                                        setState(() => _ageGroup = ag),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 20),

                              // ── Expertise level ──────────────────────
                              const _SectionLabel(label: 'EXPERTISE LEVEL'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _expertiseLevels.map((el) {
                                  final selected = _expertiseLevel == el;
                                  return _ChoiceChip(
                                    label: el,
                                    selected: selected,
                                    onTap: () =>
                                        setState(() => _expertiseLevel = el),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 26),

                              // ── Create Account CTA ───────────────────
                              GestureDetector(
                                onTap: isLoading ? null : _register,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
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
                                                    Icons.person_add_outlined,
                                                    color: _navy,
                                                    size: 16),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  color: _navy,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?  ',
                              style:
                                  TextStyle(color: _textSub, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              ),
                              child: const Text(
                                'Sign In',
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

  // ── Text field ─────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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
          borderSide: const BorderSide(color: _navyMid, width: 1.5),
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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        isDense: true,
      ),
    );
  }
}

// ── Choice chip ───────────────────────────────────────────────────────────────

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF002D72)
              : const Color(0xFFF0F6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                : const Color(0xFF002D72).withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF002D72).withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFFFD700) : const Color(0xFF90A4C4),
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

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