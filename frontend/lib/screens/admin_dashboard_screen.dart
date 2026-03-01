// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  String? _error;

  // Metrics data
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _feedbacks = [];
  List<Map<String, dynamic>> _recentChats = [];
  Map<String, dynamic> _systemStats = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.adminGetMetrics(),
        api.adminGetUsers(),
        api.adminGetFeedbacks(),
        api.adminGetRecentChats(),
      ]);

      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        final userResult = results[1] as Map<String, dynamic>;
        _users = (userResult['users'] as List? ?? []).cast<Map<String, dynamic>>();
        final fbResult = results[2] as Map<String, dynamic>;
        _feedbacks = (fbResult['feedbacks'] as List? ?? fbResult['feedback'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final chatResult = results[3] as Map<String, dynamic>;
        _recentChats = (chatResult['chats'] as List? ?? chatResult['history'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _systemStats = _overview['system'] as Map<String, dynamic>? ?? {};
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _logout() {
    ApiService().setAdminToken(null);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('ADMIN',
                  style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('Dashboard'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.purple.shade400,
          labelColor: Colors.purple.shade300,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.star, size: 18), text: 'Feedback'),
            Tab(icon: Icon(Icons.chat, size: 18), text: 'Chats'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildOverviewTab(),
                    _buildUsersTab(),
                    _buildFeedbackTab(),
                    _buildChatsTab(),
                  ],
                ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAll,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  // ── OVERVIEW TAB ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final totalUsers = _overview['total_users'] ?? _users.length;
    final totalSessions = _overview['total_sessions'] ?? 0;
    final totalMessages = _overview['total_messages'] ?? _overview['total_chats'] ?? 0;
    final avgConfidence = (_overview['avg_confidence'] as num?)?.toDouble() ?? 0;
    final avgRating = (_overview['avg_rating'] as num?)?.toDouble() ?? _calcAvgRating();
    final totalFeedback = _overview['total_feedback'] ?? _feedbacks.length;

    // Character usage
    final charUsage = _overview['character_usage'] as Map<String, dynamic>?
        ?? _overview['characters'] as Map<String, dynamic>? ?? {};
    // Top topics
    final topics = _overview['top_topics'] as List? ?? _overview['topics'] as List? ?? [];
    // Anomalies
    final anomaliesDetected = _overview['anomalies_detected'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: Colors.purple,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _kpiCard('Total Users', totalUsers.toString(), Icons.people, Colors.blue),
              _kpiCard('Total Sessions', totalSessions.toString(), Icons.calendar_today, Colors.orange),
              _kpiCard('Total Messages', totalMessages.toString(), Icons.chat_bubble, Colors.teal),
              _kpiCard('Avg Confidence', '${(avgConfidence * 100).toStringAsFixed(1)}%',
                  Icons.psychology, Colors.green),
              _kpiCard('Avg Rating', avgRating.toStringAsFixed(1), Icons.star, AppTheme.primaryGold),
              _kpiCard('Anomalies Found', anomaliesDetected.toString(), Icons.warning, Colors.red),
            ],
          ),
          const SizedBox(height: 20),

          // Character Usage
          if (charUsage.isNotEmpty) ...[
            _sectionHeader('📊 Character Usage'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDeco(),
              child: Column(
                children: charUsage.entries.map((e) {
                  final count = (e.value as num?)?.toInt() ?? 0;
                  final total = charUsage.values.fold(0, (sum, v) => sum + ((v as num?)?.toInt() ?? 0));
                  final pct = total == 0 ? 0.0 : count / total;
                  final color = _charColor(e.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_charEmoji(e.key), style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(_charName(e.key),
                                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('$count (${(pct * 100).toStringAsFixed(1)}%)',
                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Top topics
          if (topics.isNotEmpty) ...[
            _sectionHeader('🏷️ Top Topics'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDeco(),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topics.take(20).map((t) {
                  final name = t is Map ? (t['topic'] ?? t['name'] ?? t.toString()) : t.toString();
                  final count = t is Map ? (t['count'] ?? '') : '';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.withOpacity(0.4)),
                    ),
                    child: Text(
                      count != '' ? '$name ($count)' : name,
                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── USERS TAB ────────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: Colors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('${_users.length} registered users',
                  style: const TextStyle(color: Colors.white38, fontSize: 13)),
            );
          }
          final u = _users[i - 1];
          final username = u['username'] ?? '';
          final email = u['email'] ?? '';
          final fullName = u['full_name'] ?? '';
          final expertise = u['expertise_level'] ?? 'tourist';
          final sessions = u['total_sessions'] ?? 0;
          final lastLogin = u['last_login'] != null
              ? DateTime.tryParse(u['last_login'].toString())
              : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _cardDeco(),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            fullName.isNotEmpty ? fullName : username,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _expertiseColor(expertise).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(expertise,
                                style: TextStyle(color: _expertiseColor(expertise), fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('@$username',
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      if (email.isNotEmpty)
                        Text(email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$sessions sessions',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    if (lastLogin != null)
                      Text(
                        DateFormat('MMM d').format(lastLogin),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── FEEDBACK TAB ─────────────────────────────────────────────────────────

  Widget _buildFeedbackTab() {
    if (_feedbacks.isEmpty) {
      return const Center(child: Text('No feedback yet', style: TextStyle(color: Colors.white54)));
    }

    final avgRating = _calcAvgRating();
    final starCounts = List.generate(5, (i) {
      final star = 5 - i;
      return _feedbacks.where((f) => (f['rating'] as num? ?? 0).round() == star).length;
    });

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: Colors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedbacks.length + 2,
        itemBuilder: (_, i) {
          if (i == 0) {
            // Summary stats
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGold.withOpacity(0.12), AppTheme.cardDark],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(avgRating.toStringAsFixed(1),
                          style: const TextStyle(color: AppTheme.primaryGold, fontSize: 44, fontWeight: FontWeight.bold)),
                      Row(children: List.generate(5, (i) => Icon(
                        i < avgRating.round() ? Icons.star : Icons.star_border,
                        color: AppTheme.primaryGold, size: 16))),
                      Text('${_feedbacks.length} total',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 16),
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
                              Text('$star★',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: Colors.white10,
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
          if (i == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('All feedback entries:',
                  style: const TextStyle(color: Colors.white38, fontSize: 13)),
            );
          }
          final f = _feedbacks[i - 2];
          return _buildFeedbackItem(f);
        },
      ),
    );
  }

  Widget _buildFeedbackItem(Map<String, dynamic> f) {
    final rating = (f['rating'] as num? ?? 0).toDouble();
    final query = f['query'] ?? f['question'] ?? '';
    final comment = f['comment'] ?? '';
    final username = f['username'] ?? f['user'] ?? '';
    final characterId = f['character_id'] ?? '';
    final ts = f['timestamp'] != null ? DateTime.tryParse(f['timestamp'].toString()) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(children: List.generate(5, (i) => Icon(
                i < rating.round() ? Icons.star : Icons.star_border,
                color: AppTheme.primaryGold, size: 16))),
              const SizedBox(width: 8),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (username.isNotEmpty)
                Text('@$username',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              if (ts != null) ...[
                const SizedBox(width: 8),
                Text(DateFormat('MMM d, HH:mm').format(ts),
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ],
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (characterId.isNotEmpty) ...[
                  Text(_charEmoji(characterId)),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text('"$query"',
                      style: const TextStyle(color: Colors.white70, fontSize: 13,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  // ── CHATS TAB ────────────────────────────────────────────────────────────

  Widget _buildChatsTab() {
    if (_recentChats.isEmpty) {
      return const Center(child: Text('No chats found', style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: Colors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentChats.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('${_recentChats.length} recent conversations',
                  style: const TextStyle(color: Colors.white38, fontSize: 13)),
            );
          }
          final chat = _recentChats[i - 1];
          final characterId = chat['character_id'] ?? chat['character'] ?? '';
          final question = chat['question'] ?? chat['query'] ?? '';
          final answer = chat['answer'] ?? '';
          final username = chat['username'] ?? chat['user'] ?? '';
          final confidence = (chat['confidence'] as num?)?.toDouble() ?? 0;
          final ts = chat['timestamp'] != null ? DateTime.tryParse(chat['timestamp'].toString()) : null;
          final charColor = _charColor(characterId);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: charColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_charEmoji(characterId), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(_charName(characterId),
                        style: TextStyle(color: charColor, fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    if (username.isNotEmpty)
                      Text('@$username', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    if (ts != null) ...[
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM d').format(ts),
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ],
                ),
                if (question.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Q: ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                        Expanded(child: Text(question,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
                if (answer.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: charColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('A: ', style: TextStyle(color: charColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        Expanded(child: Text(answer,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            maxLines: 3, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
                if (confidence > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  double _calcAvgRating() {
    if (_feedbacks.isEmpty) return 0;
    final sum = _feedbacks.fold(0.0, (s, f) => s + (f['rating'] as num? ?? 0).toDouble());
    return sum / _feedbacks.length;
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(value,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      );

  Widget _sectionHeader(String title) => Text(title,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));

  BoxDecoration _cardDeco() => BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      );

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
  Color _expertiseColor(String level) => switch (level) {
        'researcher' => Colors.purple,
        'student' => Colors.blue,
        'child' => Colors.orange,
        _ => Colors.teal,
      };
}