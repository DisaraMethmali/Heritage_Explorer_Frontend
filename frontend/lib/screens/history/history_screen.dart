// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';
import '../../utils/constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabCtrl;

  List<HistoryRecord> _records = [];
  List<dynamic> _sessions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _filterCharacter;
  String? _searchText;
  final _searchCtrl = TextEditingController();
  int _offset = 0;
  bool _hasMore = true;

  // Light yellow & blue theme
  static const Color _pageBg     = Color(0xFFF0F8FF);
  static const Color _appBarBg   = Color(0xFF1565C0);
  static const Color _accent     = Color(0xFF1565C0);
  static const Color _gold       = Color(0xFFFFB300);
  static const Color _cardBg     = Colors.white;
  static const Color _border     = Color(0xFFBBDEFB);
  static const Color _speakBtn   = Color(0xFFFFE082); // light yellow

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadHistory();
    _loadStats();
    _loadSessions();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool reset = true}) async {
    if (reset) {
      setState(() { _isLoading = true; _offset = 0; _records = []; });
    }
    try {
      final data = await _api.getHistory(
        characterId: _filterCharacter,
        search: _searchText,
        limit: 20,
        offset: _offset,
      );

      // ✅ FIX: backend returns 'history', not 'records'
      final rawList = data['history'] as List?
          ?? data['records']  as List?
          ?? data['messages'] as List?
          ?? [];

      final newRecords = rawList
          .map((r) => HistoryRecord.fromJson(r as Map<String, dynamic>))
          .toList();

      setState(() {
        if (reset) _records = newRecords;
        else       _records.addAll(newRecords);
        _hasMore = newRecords.length == 20;
        _offset += newRecords.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final data = await _api.getHistoryStats();
      setState(() {
        _stats = data['stats'] as Map<String, dynamic>?
            ?? data as Map<String, dynamic>;
      });
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    try {
      final data = await _api.getHistorySessions();
      setState(() => _sessions = data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        title: const Text(
          'Chat History',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              _loadHistory();
              _loadStats();
              _loadSessions();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _gold,
          labelColor: _gold,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Messages'),
            Tab(text: 'Sessions'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMessagesTab(),
          _buildSessionsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // ── MESSAGES TAB ──────────────────────────────────────────────────────────
  Widget _buildMessagesTab() {
    return Column(
      children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      color: Colors.black87, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: const TextStyle(
                        color: Colors.black38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.black38, size: 20),
                    suffixIcon: _searchText != null
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.black38, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchText = null);
                              _loadHistory();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    setState(() =>
                        _searchText = v.trim().isEmpty ? null : v.trim());
                    _loadHistory();
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Character filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', null),
                    ...AppConstants.characters.entries.map((e) =>
                        _filterChip(
                          '${e.value.emoji} ${e.value.name.split(' ').first}',
                          e.key,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading && _records.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: _accent))
              : _records.isEmpty
                  ? _emptyHistory()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification &&
                            n.metrics.extentAfter < 100 &&
                            _hasMore &&
                            !_isLoading) {
                          _loadHistory(reset: false);
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: _accent,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          itemCount:
                              _records.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            if (i == _records.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                      color: _accent),
                                ),
                              );
                            }
                            return _buildCard(_records[i]);
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _emptyHistory() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
                border: Border.all(color: _border, width: 2),
              ),
              child: const Center(
                child: Text('💬', style: TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('No messages yet',
                style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Start a chat to see your history here',
                style: TextStyle(color: Colors.black45, fontSize: 13)),
          ],
        ),
      );

  Widget _filterChip(String label, String? value) {
    final selected = _filterCharacter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : _accent,
                fontSize: 12)),
        selected: selected,
        onSelected: (_) {
          setState(() => _filterCharacter = value);
          _loadHistory();
        },
        selectedColor: _accent,
        backgroundColor: const Color(0xFFE3F2FD),
        side: BorderSide(
            color: selected ? _accent : const Color(0xFF90CAF9)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ── History card ──────────────────────────────────────────────────────────
  Widget _buildCard(HistoryRecord record) {
    final char = AppConstants.characters[record.characterId];
    final dateStr = DateFormat('MMM d, HH:mm').format(record.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: char?.color.withOpacity(0.3) ?? _border),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: char?.color.withOpacity(0.1) ??
                  const Color(0xFFE3F2FD),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: char?.color.withOpacity(0.15) ??
                        Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(char?.emoji ?? '💬',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.characterName,
                        style: TextStyle(
                          color: char?.color ?? _accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$dateStr  •  ${record.topic}',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Confidence badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${(record.confidence * 100).toInt()}%',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Q&A body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question (user)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person,
                        color: Color(0xFF1565C0), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.question,
                        style: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Divider(color: _border, height: 16, thickness: 1),

                // Answer (bot) + speak button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(char?.emoji ?? '🤖',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.answer,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // ✅ FIX: use Provider, not VoiceService() directly
                    Consumer<VoiceService>(
                      builder: (ctx, voice, _) => GestureDetector(
                        onTap: () => voice.speak(record.answer),
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: _speakBtn,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.35),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.volume_up,
                            size: 17,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SESSIONS TAB ──────────────────────────────────────────────────────────
  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('📅', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No sessions yet',
                style: TextStyle(color: Colors.black45, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: _accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = _sessions[i] as Map<String, dynamic>;
          final lastMsg = s['last_message']?.toString() ?? '';
          String formattedDate = '';
          try {
            formattedDate = DateFormat('MMM d, HH:mm')
                .format(DateTime.parse(lastMsg));
          } catch (_) {}

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: const Center(
                  child: Text('💬', style: TextStyle(fontSize: 22)),
                ),
              ),
              title: Text(
                s['session_id']?.toString() ?? '',
                style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${s['message_count'] ?? 0} messages'
                '${formattedDate.isNotEmpty ? '  •  $formattedDate' : ''}',
                style: const TextStyle(
                    color: Colors.black45, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 22),
                onPressed: () async {
                  final sid = s['session_id']?.toString() ?? '';
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Session'),
                      content: const Text(
                          'Delete all messages in this session?'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await _api.deleteSession(sid);
                    _loadSessions();
                    _loadHistory();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ── STATS TAB ─────────────────────────────────────────────────────────────
  Widget _buildStatsTab() {
    if (_stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('📊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No stats yet',
                style: TextStyle(color: Colors.black45, fontSize: 15)),
          ],
        ),
      );
    }

    final totalMsgs  = _stats['total_messages'] ?? 0;
    final sessions   = _stats['sessions'] ?? _stats['total_sessions'] ?? 0;
    final avgConf    = ((_stats['avg_confidence'] ?? 0.0) as num).toDouble();
    final characters = _stats['characters'] as Map<String, dynamic>? ?? {};
    final topics     = _stats['topics']     as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: _accent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI row
            Row(
              children: [
                _statCard('💬', 'Messages', '$totalMsgs',
                    const Color(0xFF1565C0)),
                const SizedBox(width: 10),
                _statCard('📅', 'Sessions', '$sessions',
                    const Color(0xFF00897B)),
                const SizedBox(width: 10),
                _statCard('🎯', 'Avg Conf',
                    '${(avgConf * 100).toInt()}%',
                    const Color(0xFFFF8F00)),
              ],
            ),
            const SizedBox(height: 20),

            // Character usage bars
            if (characters.isNotEmpty) ...[
              _sectionHeader('Characters Used'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: characters.entries.map((e) {
                    final char = AppConstants.characters[e.key];
                    final count = (e.value as num).toInt();
                    final maxVal = characters.values
                        .map((v) => (v as num).toInt())
                        .reduce((a, b) => a > b ? a : b);
                    final pct = maxVal == 0 ? 0.0 : count / maxVal;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(char?.emoji ?? '?',
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      char?.name.split(' ').first ??
                                          e.key,
                                      style: const TextStyle(
                                          color: Color(0xFF1A237E),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '$count',
                                      style: TextStyle(
                                          color: char?.color ?? _accent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor:
                                        const Color(0xFFE3F2FD),
                                    valueColor: AlwaysStoppedAnimation(
                                        char?.color ?? _accent),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
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

            // Topics
            if (topics.isNotEmpty) ...[
              _sectionHeader('Top Topics'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topics.entries.take(12).map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF90CAF9)),
                    ),
                    child: Text(
                      '${e.key}  ${e.value}',
                      style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String emoji, String label, String value, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.black45, fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _sectionHeader(String text) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ],
      );
}