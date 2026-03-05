// lib/screens/feedback_screen.dart
import 'package:flutter/material.dart';
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

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _loading = true;
  String? _error;
  double _avgRating = 0;

  final _queryCtrl   = TextEditingController();
  final _commentCtrl = TextEditingController();
  double _selectedRating = 5;
  String _selectedChar   = 'king';
  bool _submitting = false;

  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color _pageBg       = Color(0xFFFFFDE7);
  static const Color _cardBg       = Color(0xFFFFFBF0);
  static const Color _surfaceBg    = Color(0xFFFFF9C4);
  static const Color _deepBlue     = Color(0xFF0D47A1);
  static const Color _midBlue      = Color(0xFF1565C0);
  static const Color _hintBlue     = Color(0xFF5C7CBF);
  static const Color _accentYellow = Color(0xFFFFCA28);
  static const Color _borderYellow = Color(0xFFE6D96A);
  static const Color _appBarBg     = Color(0xFF0D47A1);

  // ── Char helpers ───────────────────────────────────────────────────────────
  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
  }

  Color _charColor(String id) => switch (id) {
        'king'    => const Color(0xFFF9A825),
        'nilame'  => const Color(0xFFE65100),
        'dutch'   => const Color(0xFF2E7D32),
        _         => const Color(0xFF0277BD),
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

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbacks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api  = ApiService();
      final data = await api.getFeedbacks();
      final list = (data['feedbacks'] as List? ??
              data['feedback'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      double sum = 0;
      for (final f in list) {
        sum += (f['rating'] as num? ?? 0).toDouble();
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a topic or query'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final api       = ApiService();
      final sessionId =
          'feedback_${DateTime.now().millisecondsSinceEpoch}';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Feedback submitted! Thank you.'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadFeedbacks();
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFE082)),
        title: const Text(
          'Feedback',
          style: TextStyle(
            color: Color(0xFFFFF9C4),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFE082)),
            onPressed: _loadFeedbacks,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: _midBlue,
                backgroundColor: _borderYellow,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_feedbacks.isNotEmpty) _buildStatsCard(),
                  const SizedBox(height: 20),
                  _buildSubmitForm(),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(_error!,
                          style: TextStyle(color: Colors.red.shade700)),
                    )
                  else if (_feedbacks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _accentYellow.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _accentYellow.withOpacity(0.4)),
                              ),
                              child: const Icon(Icons.rate_review_outlined,
                                  color: _deepBlue, size: 40),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No feedback yet. Be the first!',
                              style: TextStyle(
                                  color: _hintBlue, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      '${_feedbacks.length} review${_feedbacks.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: _hintBlue, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ..._feedbacks.map((f) => _buildFeedbackCard(f)),
                  ],
                ],
              ),
            ),
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
        gradient: LinearGradient(
          colors: [
            _accentYellow.withOpacity(0.18),
            _cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderYellow),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Average rating
          Column(
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: _deepBlue,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < _avgRating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _accentYellow,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_feedbacks.length} reviews',
                style: const TextStyle(color: _hintBlue, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Bar breakdown
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
                              color: _hintBlue, fontSize: 11)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          color: _accentYellow, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor:
                                _borderYellow.withOpacity(0.4),
                            valueColor: AlwaysStoppedAnimation(
                                _accentYellow),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('$count',
                          style: const TextStyle(
                              color: _hintBlue, fontSize: 11)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderYellow),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rate_review_outlined,
                    color: _deepBlue, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Leave Feedback',
                style: TextStyle(
                  color: _deepBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Character picker
          const Text('Character',
              style: TextStyle(color: _hintBlue, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: charOptions.entries.map((e) {
              final selected = _selectedChar == e.key;
              final cColor   = _charColor(e.key);
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedChar = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? cColor.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? cColor : _borderYellow,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Initials circle
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? cColor.withOpacity(0.15)
                                : const Color(0xFFE3F2FD),
                            border: Border.all(
                              color: selected
                                  ? cColor.withOpacity(0.5)
                                  : _borderYellow,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _charInitials(e.key),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected ? cColor : _deepBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          e.value,
                          style: TextStyle(
                            color: selected ? cColor : _hintBlue,
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
              style: TextStyle(color: _hintBlue, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = (i + 1).toDouble();
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedRating = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _accentYellow,
                    size: 34,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Topic field
          TextField(
            controller: _queryCtrl,
            style: const TextStyle(color: _deepBlue, fontSize: 14),
            decoration: _inputDeco('Topic / Question you asked'),
          ),
          const SizedBox(height: 10),

          // Comment field
          TextField(
            controller: _commentCtrl,
            style: const TextStyle(color: _deepBlue, fontSize: 14),
            maxLines: 3,
            decoration: _inputDeco('Additional comments (optional)'),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitFeedback,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _submitting ? 'Submitting...' : 'Submit Feedback',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepBlue,
                foregroundColor: const Color(0xFFFFF9C4),
                disabledBackgroundColor:
                    _deepBlue.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: _hintBlue, fontSize: 13),
        filled: true,
        fillColor: _surfaceBg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderYellow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderYellow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: _deepBlue, width: 2),
        ),
      );

  // ── Feedback card ──────────────────────────────────────────────────────────

  Widget _buildFeedbackCard(Map<String, dynamic> f) {
    final rating      = (f['rating'] as num? ?? 0).toDouble();
    final query       = f['query'] ?? f['question'] ?? '';
    final comment     = f['comment'] ?? '';
    final characterId =
        f['character_id'] ?? f['character'] ?? '';
    final ts = f['timestamp'] != null
        ? DateTime.tryParse(f['timestamp'].toString())
        : null;
    final cColor = characterId.isNotEmpty
        ? _charColor(characterId)
        : _midBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderYellow),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: stars + char badge + date
          Row(
            children: [
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _accentYellow,
                    size: 16,
                  ),
                ),
              ),
              const Spacer(),
              // Character badge
              if (characterId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cColor.withOpacity(0.15),
                        ),
                        child: Center(
                          child: Text(
                            _charInitials(characterId),
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: cColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _charLabel(characterId),
                        style: TextStyle(
                            color: cColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              if (ts != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d').format(ts),
                  style: const TextStyle(
                      color: _hintBlue, fontSize: 11),
                ),
              ],
            ],
          ),

          // Query
          if (query.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _surfaceBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _borderYellow.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: _hintBlue, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      query,
                      style: const TextStyle(
                        color: _deepBlue,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                  color: _hintBlue, fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}