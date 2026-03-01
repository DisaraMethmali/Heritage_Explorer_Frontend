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

  // Submit new feedback form
  final _queryCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  double _selectedRating = 5;
  String _selectedChar = 'king';
  bool _submitting = false;

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
      final api = ApiService();
      final data = await api.getFeedbacks();
      final list = (data['feedbacks'] as List? ?? data['feedback'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      double sum = 0;
      for (final f in list) {
        sum += (f['rating'] as num? ?? 0).toDouble();
      }
      setState(() {
        _feedbacks = list;
        _avgRating = list.isEmpty ? 0 : sum / list.length;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _submitFeedback() async {
    if (_queryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic or query'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ApiService();
      final sessionId = 'feedback_${DateTime.now().millisecondsSinceEpoch}';
      await api.submitFeedback(
        query: _queryCtrl.text.trim(),
        rating: _selectedRating,
        characterId: _selectedChar,
        sessionId: sessionId,
        comment: _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      _queryCtrl.clear();
      _commentCtrl.clear();
      setState(() { _submitting = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Feedback submitted! Thank you.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadFeedbacks();
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('⭐ Feedback'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFeedbacks)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats card
                  if (_feedbacks.isNotEmpty) _buildStatsCard(),
                  const SizedBox(height: 20),

                  // Submit new feedback
                  _buildSubmitForm(),
                  const SizedBox(height: 24),

                  // Feedback list
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    )
                  else if (_feedbacks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: const [
                            Text('⭐', style: TextStyle(fontSize: 48)),
                            SizedBox(width: 10,height: 12),
                            Text('No feedback yet. Be the first!',
                                style: TextStyle(color: Colors.white54, fontSize: 15)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      '${_feedbacks.length} review${_feedbacks.length != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(width: 10,height: 12),
                    ..._feedbacks.map((f) => _buildFeedbackCard(f)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    final starCounts = List.generate(5, (i) {
      final star = 5 - i;
      return _feedbacks.where((f) => (f['rating'] as num? ?? 0).round() == star).length;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGold.withOpacity(0.15), AppTheme.cardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < _avgRating.round() ? Icons.star : Icons.star_border,
                  color: AppTheme.primaryGold,
                  size: 18,
                )),
              ),
              const SizedBox(width: 10,height: 4),
              Text('${_feedbacks.length} reviews',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = starCounts[i];
                final pct = _feedbacks.isEmpty ? 0.0 : count / _feedbacks.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppTheme.primaryGold, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGold),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('$count', style: const TextStyle(color: Colors.white38, fontSize: 11)),
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

  Widget _buildSubmitForm() {
    final charOptions = {
      'king': ('👑', 'King'),
      'nilame': ('🏛️', 'Nilame'),
      'dutch': ('⚓', 'Dutch'),
      'citizen': ('📚', 'Guide'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✍️ Leave Feedback',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 10,height: 14),

          // Character picker
          const Text('Character', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 10,height: 6),
          Row(
            children: charOptions.entries.map((e) {
              final selected = _selectedChar == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChar = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryGold.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppTheme.primaryGold : Colors.white24,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(e.value.$1, style: const TextStyle(fontSize: 18)),
                        Text(e.value.$2,
                            style: TextStyle(
                              color: selected ? AppTheme.primaryGold : Colors.white38,
                              fontSize: 10,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 10,height: 14),

          // Star rating
          const Text('Rating', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 10,height: 6),
          Row(
            children: List.generate(5, (i) {
              final star = (i + 1).toDouble();
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    star <= _selectedRating ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryGold,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 10,height: 14),

          // Query/topic
          TextField(
            controller: _queryCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco('Topic / Question you asked'),
          ),
          const SizedBox(width: 10,height: 10),

          // Comment
          TextField(
            controller: _commentCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: _inputDeco('Additional comments (optional)'),
          ),
          const SizedBox(width: 10,height: 14),

          SizedBox(
            width: 10,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitFeedback,
              icon: _submitting
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Submitting...' : 'Submit Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: AppTheme.backgroundDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryGold),
        ),
      );

  Widget _buildFeedbackCard(Map<String, dynamic> f) {
    final rating = (f['rating'] as num? ?? 0).toDouble();
    final query = f['query'] ?? f['question'] ?? '';
    final comment = f['comment'] ?? '';
    final characterId = f['character_id'] ?? f['character'] ?? '';
    final ts = f['timestamp'] != null
        ? DateTime.tryParse(f['timestamp'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating.round() ? Icons.star : Icons.star_border,
                  color: AppTheme.primaryGold,
                  size: 16,
                )),
              ),
              const Spacer(),
              if (characterId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _charColor(characterId).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _charColor(characterId).withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_charEmoji(characterId)} ${_charName(characterId)}',
                    style: TextStyle(color: _charColor(characterId), fontSize: 11),
                  ),
                ),
              if (ts != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d').format(ts),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"$query"',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Color _charColor(String id) => switch (id) {
        'king' => const Color(0xFFFFD700),
        'nilame' => const Color(0xFFFFAB40),
        'dutch' => const Color(0xFF4CAF50),
        _ => const Color(0xFF00BCD4),
      };

  String _charEmoji(String id) => switch (id) {
        'king' => '👑', 'nilame' => '🏛️', 'dutch' => '⚓', _ => '📚',
      };

  String _charName(String id) => switch (id) {
        'king' => 'King', 'nilame' => 'Nilame', 'dutch' => 'Dutch', _ => 'Guide',
      };
}