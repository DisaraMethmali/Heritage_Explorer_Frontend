// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {

  List<Map<String, dynamic>> _feedbacks = [];
  bool _loading = true;
  String? _error;
  double _avgRating = 0;

  final _queryCtrl   = TextEditingController();
  final _commentCtrl = TextEditingController();
  double _selectedRating = 5;
  String _selectedChar   = 'king';
  bool _submitting = false;

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
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _contentController, curve: Curves.easeOutCubic));

    _loadFeedbacks();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _commentCtrl.dispose();
    _shimmerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Char helpers (unchanged) ───────────────────────────────────────────────

  Color _charColor(String id) => switch (id) {
        'king'   => const Color(0xFFF9A825),
        'nilame' => const Color(0xFFE65100),
        'dutch'  => const Color(0xFF2E7D32),
        _        => const Color(0xFF0277BD),
      };

  String _charLabel(String id) => switch (id) {
        'king'   => 'King',
        'nilame' => 'Nilame',
        'dutch'  => 'Dutch',
        _        => 'Guide',
      };

  String _charInitials(String id) => switch (id) {
        'king'   => 'KG',
        'nilame' => 'NL',
        'dutch'  => 'DU',
        _        => 'GD',
      };

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _loadFeedbacks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api  = ApiService();
      final data = await api.getFeedbacks();
      final list = (data['feedbacks'] as List? ??
              data['feedback'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      double sum = 0;
      for (final f in list) sum += (f['rating'] as num? ?? 0).toDouble();
      setState(() {
        _feedbacks = list;
        _avgRating = list.isEmpty ? 0 : sum / list.length;
        _loading   = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _submitFeedback() async {
    if (_queryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a topic or query'),
        backgroundColor: const Color(0xFFE65100),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      final api       = ApiService();
      final sessionId = 'feedback_${DateTime.now().millisecondsSinceEpoch}';
      await api.submitFeedback(
        query:       _queryCtrl.text.trim(),
        rating:      _selectedRating,
        characterId: _selectedChar,
        sessionId:   sessionId,
        comment:     _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      _queryCtrl.clear();
      _commentCtrl.clear();
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Feedback submitted! Thank you.'),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await _loadFeedbacks();
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      body: _loading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: Column(
                  children: [
                    _buildHero(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_feedbacks.isNotEmpty) ...[
                              _buildStatsCard(),
                              const SizedBox(height: 16),
                            ],
                            _buildSubmitForm(),
                            const SizedBox(height: 20),
                            if (_error != null)
                              _buildErrorBanner()
                            else if (_feedbacks.isEmpty)
                              _buildEmptyState()
                            else ...[
                              _SectionLabel(
                                label:
                                    '${_feedbacks.length} REVIEW${_feedbacks.length != 1 ? 'S' : ''}',
                              ),
                              const SizedBox(height: 12),
                              ..._feedbacks.map((f) => _buildFeedbackCard(f)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _navy,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 14),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 1.5),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.rate_review_outlined,
                size: 16, color: _gold),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('FEEDBACK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0)),
              Text('Share your experience',
                  style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2)),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _loadFeedbacks,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: _gold, size: 13),
                SizedBox(width: 5),
                Text('REFRESH',
                    style: TextStyle(
                        color: _gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [_gold, Color(0xFFFFA500), _gold]),
          ),
        ),
      ),
    );
  }

  // ── Hero — fixed 110px ────────────────────────────────────────────────────

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return SizedBox(
          height: 110,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_navy, _blue, _blueMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
              Positioned.fill(
                  child: CustomPaint(
                      painter: _ShimmerPainter(_shimmer.value))),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: CustomPaint(
                  size: const Size(double.infinity, 28),
                  painter: _WavePainter(),
                ),
              ),
              Positioned(
                left: 20, right: 20, bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _gold.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        _feedbacks.isEmpty
                            ? 'SHARE YOUR THOUGHTS'
                            : '${_feedbacks.length} REVIEWS · ${_avgRating.toStringAsFixed(1)} ★',
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Community Feedback',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Loading state ──────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _gold.withValues(alpha: 0.25), width: 1),
              ),
            ),
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                    colors: [Color(0xFF0A4FA3), _navy],
                    center: Alignment(-0.3, -0.3)),
                boxShadow: [
                  BoxShadow(
                      color: _gold.withValues(alpha: 0.2), blurRadius: 16)
                ],
              ),
              child: const Icon(Icons.rate_review_outlined,
                  color: _gold, size: 26),
            ),
          ]),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: _gold, strokeWidth: 2),
          const SizedBox(height: 16),
          const Text('Loading feedback...',
              style: TextStyle(
                  color: _textSub, fontSize: 13, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Stack(alignment: Alignment.center, children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.15), width: 1)),
              ),
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.35), width: 1.5)),
              ),
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [Color(0xFF0A4FA3), _navy],
                      center: Alignment(-0.3, -0.3)),
                  boxShadow: [
                    BoxShadow(
                        color: _gold.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.rate_review_outlined,
                    size: 30, color: _gold),
              ),
            ]),
            const SizedBox(height: 20),
            const Text('No feedback yet.',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textMain)),
            const SizedBox(height: 8),
            const Text('Be the first to share your experience!',
                style: TextStyle(fontSize: 13, color: _textSub)),
          ],
        ),
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline,
            color: Color(0xFFC62828), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_error!,
              style: const TextStyle(
                  color: Color(0xFFC62828), fontSize: 13)),
        ),
      ]),
    );
  }

  // ── Stats card ─────────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    final starCounts = List.generate(5, (i) {
      final star = 5 - i;
      return _feedbacks
          .where((f) => (f['rating'] as num? ?? 0).round() == star)
          .length;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
            top: BorderSide(color: _gold, width: 2.5)),
        boxShadow: [
          BoxShadow(
              color: _navyMid.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Average
          Column(
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: const TextStyle(
                    color: _navyMid,
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < _avgRating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _gold, size: 17,
                )),
              ),
              const SizedBox(height: 4),
              Text('${_feedbacks.length} reviews',
                  style: const TextStyle(
                      color: _textSub, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 20),

          // Bar chart
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star  = 5 - i;
                final count = starCounts[i];
                final pct   = _feedbacks.isEmpty
                    ? 0.0
                    : count / _feedbacks.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Text('$star',
                          style: const TextStyle(
                              color: _textSub, fontSize: 11)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          color: _gold, size: 11),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor:
                                _textSub.withValues(alpha: 0.15),
                            valueColor:
                                const AlwaysStoppedAnimation(_gold),
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('$count',
                          style: const TextStyle(
                              color: _textSub, fontSize: 11)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit form ────────────────────────────────────────────────────────────

  Widget _buildSubmitForm() {
    final charOptions = {
      'king':    'King',
      'nilame':  'Nilame',
      'dutch':   'Dutch',
      'citizen': 'Guide',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
            top: BorderSide(color: _gold, width: 2.5)),
        boxShadow: [
          BoxShadow(
              color: _navyMid.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const _SectionLabel(label: 'LEAVE FEEDBACK'),
          const SizedBox(height: 16),

          // Character picker
          const Text('Character',
              style: TextStyle(
                  color: _textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: charOptions.entries.map((e) {
              final selected = _selectedChar == e.key;
              final cColor   = _charColor(e.key);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChar = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? cColor.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? cColor
                            : _textSub.withValues(alpha: 0.2),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? cColor.withValues(alpha: 0.15)
                                : _textSub.withValues(alpha: 0.08),
                            border: Border.all(
                              color: selected
                                  ? cColor.withValues(alpha: 0.5)
                                  : _textSub.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _charInitials(e.key),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected ? cColor : _textSub,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          e.value,
                          style: TextStyle(
                            color: selected ? cColor : _textSub,
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Star rating
          const Text('Rating',
              style: TextStyle(
                  color: _textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = (i + 1).toDouble();
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _gold,
                    size: 34,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Topic field
          _buildInput(_queryCtrl, 'Topic / Question you asked'),
          const SizedBox(height: 10),

          // Comment field
          _buildInput(_commentCtrl, 'Additional comments (optional)',
              maxLines: 3),
          const SizedBox(height: 16),

          // Submit button
          GestureDetector(
            onTap: _submitting ? null : _submitFeedback,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: _submitting
                    ? null
                    : const LinearGradient(
                        colors: [_goldDeep, _gold, Color(0xFFFFC200)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                color: _submitting
                    ? _textSub.withValues(alpha: 0.2)
                    : null,
                boxShadow: _submitting
                    ? []
                    : [
                        BoxShadow(
                            color: _gold.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _navy.withValues(alpha: 0.12)),
                    child: _submitting
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _navy),
                          )
                        : const Icon(Icons.send_rounded,
                            color: _navy, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _submitting ? 'Submitting...' : 'Submit Feedback',
                    style: TextStyle(
                        color: _submitting ? _textSub : _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _navyMid,
          selectionHandleColor: _navyMid,
          selectionColor: Color(0xFFB3D1FF),
        ),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(
            color: _textMain, fontSize: 13, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textSub, fontSize: 12),
          filled: true,
          fillColor: _inputBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: _textSub.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: _textSub.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: _navyMid, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Feedback card ──────────────────────────────────────────────────────────

  Widget _buildFeedbackCard(Map<String, dynamic> f) {
    final rating      = (f['rating'] as num? ?? 0).toDouble();
    final query       = f['query'] ?? f['question'] ?? '';
    final comment     = f['comment'] ?? '';
    final characterId = f['character_id'] ?? f['character'] ?? '';
    final ts = f['timestamp'] != null
        ? DateTime.tryParse(f['timestamp'].toString())
        : null;
    final cColor = characterId.isNotEmpty
        ? _charColor(characterId)
        : _navyMid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            top: BorderSide(color: _gold.withValues(alpha: 0.7), width: 2)),
        boxShadow: [
          BoxShadow(
              color: _navyMid.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars + char badge + date
          Row(
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _gold, size: 16,
                )),
              ),
              const Spacer(),
              if (characterId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cColor.withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Text(
                            _charInitials(characterId),
                            style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: cColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(_charLabel(characterId),
                          style: TextStyle(
                              color: cColor, fontSize: 11)),
                    ],
                  ),
                ),
              if (ts != null) ...[
                const SizedBox(width: 8),
                Text(DateFormat('MMM d').format(ts),
                    style: const TextStyle(
                        color: _textSub, fontSize: 11)),
              ],
            ],
          ),

          // Query
          if (query.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _textSub.withValues(alpha: 0.15), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: _textSub, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(query,
                        style: const TextStyle(
                            color: _textMain,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],

          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment,
                style: const TextStyle(
                    color: _textSub, fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3, height: 13,
        decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              color: Color(0xFF002D72),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5)),
    ]);
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;
    p.color = const Color(0xFFFFD700).withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 1.05, -10), size.width * 0.55, p);
    p.color = const Color(0xFF48CAE4).withValues(alpha: 0.09);
    canvas.drawCircle(Offset(-20, size.height * 1.5), size.width * 0.5, p);
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.03);
    p.strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0),
          Offset(size.width * i / 6 + 40, size.height), p);
    }
    final dot = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
            Offset(size.width - 20 - i * 20.0, 12 + j * 20.0), 1.6, dot);
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
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.30);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.6, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}