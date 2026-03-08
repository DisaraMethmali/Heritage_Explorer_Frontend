// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabCtrl;

  List<HistoryRecord> _records  = [];
  List<dynamic>       _sessions = [];
  Map<String, dynamic> _stats  = {};
  bool    _isLoading       = false;
  String? _filterCharacter;
  String? _searchText;
  final   _searchCtrl      = TextEditingController();
  int     _offset          = 0;
  bool    _hasMore         = true;

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
  late Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    _loadHistory();
    _loadStats();
    _loadSessions();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _loadHistory({bool reset = true}) async {
    if (reset) {
      setState(() { _isLoading = true; _offset = 0; _records = []; });
    }
    try {
      final data = await _api.getHistory(
        characterId: _filterCharacter,
        search:      _searchText,
        limit:       20,
        offset:      _offset,
      );
      final rawList = data['history']  as List?
          ?? data['records']   as List?
          ?? data['messages']  as List?
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load history: $e'),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      body: Column(children: [
        _buildHero(),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildMessagesTab(),
              _buildSessionsTab(),
              _buildStatsTab(),
            ],
          ),
        ),
      ]),
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
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
        ),
      ),
      title: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 1.5),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.history_edu, size: 16, color: _gold),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('CHAT HISTORY',
                style: TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w800, letterSpacing: 2.0)),
            Text('Past conversations',
                style: TextStyle(color: _gold, fontSize: 10,
                    fontWeight: FontWeight.w400, letterSpacing: 1.2)),
          ],
        ),
      ]),
      actions: [
        GestureDetector(
          onTap: () { _loadHistory(); _loadStats(); _loadSessions(); },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, color: _gold, size: 13),
              SizedBox(width: 5),
              Text('REFRESH', style: TextStyle(color: _gold, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ]),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(51),
        child: Column(children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_gold, Color(0xFFFFA500), _gold]),
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            indicatorColor: _gold,
            indicatorWeight: 3,
            labelColor: _gold,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
            tabs: const [
              Tab(text: 'MESSAGES'),
              Tab(text: 'SESSIONS'),
              Tab(text: 'STATS'),
            ],
          ),
        ]),
      ),
    );
  }

  // ── Hero — fixed 90 px ────────────────────────────────────────────────────

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) => SizedBox(
        height: 90,
        child: Stack(children: [
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
          Positioned.fill(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(size: const Size(double.infinity, 24), painter: _WavePainter()),
          ),
          Positioned(
            left: 20, right: 20, bottom: 14,
            child: Text(
              _records.isEmpty ? 'Your full conversation history' : '${_records.length} messages loaded',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 12),
            ),
          ),
        ]),
      ),
    );
  }

  // ── MESSAGES TAB ──────────────────────────────────────────────────────────

  Widget _buildMessagesTab() {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(children: [
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.5), width: 1.5)),
              boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: _textSub, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: _textMain, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(color: _textSub, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (v) {
                    setState(() => _searchText = v.trim().isEmpty ? null : v.trim());
                    _loadHistory();
                  },
                ),
              ),
              if (_searchText != null)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchText = null);
                    _loadHistory();
                  },
                  child: Container(
                    width: 26, height: 26,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _textSub.withValues(alpha: 0.12)),
                    child: const Icon(Icons.close, color: _textSub, size: 13),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          // Character filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('All', null),
              ...AppConstants.characters.entries.map((e) =>
                  _filterChip('${e.value.emoji} ${e.value.name.split(' ').first}', e.key)),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: _isLoading && _records.isEmpty
            ? _buildLoadingState()
            : _records.isEmpty
                ? _buildEmptyState(Icons.chat_bubble_outline, 'No messages yet', 'Start a chat to see your history here')
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification &&
                          n.metrics.extentAfter < 100 &&
                          _hasMore && !_isLoading) {
                        _loadHistory(reset: false);
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: _gold,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: _records.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          if (i == _records.length) {
                            return const Center(
                              child: Padding(padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: _gold, strokeWidth: 2)),
                            );
                          }
                          return _buildCard(_records[i]);
                        },
                      ),
                    ),
                  ),
      ),
    ]);
  }

  Widget _filterChip(String label, String? value) {
    final selected = _filterCharacter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () { setState(() => _filterCharacter = value); _loadHistory(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _navyMid : _inputBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _navyMid : _textSub.withValues(alpha: 0.25),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : _textSub,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        ),
      ),
    );
  }

  // ── History card ──────────────────────────────────────────────────────────

  Widget _buildCard(HistoryRecord record) {
    final char     = AppConstants.characters[record.characterId];
    final dateStr  = DateFormat('MMM d, HH:mm').format(record.timestamp);
    final topColor = char?.color ?? _gold;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: topColor.withValues(alpha: 0.7), width: 2.5)),
        boxShadow: [BoxShadow(color: _navyMid.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: topColor.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: topColor.withValues(alpha: 0.12),
                border: Border.all(color: topColor.withValues(alpha: 0.35), width: 1),
              ),
              child: Center(child: Text(char?.emoji ?? '💬', style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(record.characterName,
                    style: TextStyle(color: topColor, fontWeight: FontWeight.w700, fontSize: 13)),
                Text('$dateStr  •  ${record.topic}',
                    style: const TextStyle(color: _textSub, fontSize: 11)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
              ),
              child: Text('${(record.confidence * 100).toInt()}%',
                  style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.person_outline, color: _navyMid, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(record.question,
                    style: const TextStyle(color: _textMain, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: _textSub.withValues(alpha: 0.2), height: 1, thickness: 1),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(char?.emoji ?? '🤖', style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(record.answer,
                    style: const TextStyle(color: _textSub, fontSize: 13, height: 1.5),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
              Consumer<VoiceService>(
                builder: (ctx, voice, _) => GestureDetector(
                  onTap: () => voice.speak(record.answer),
                  child: Container(
                    width: 34, height: 34,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [_goldDeep, _gold],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.volume_up, size: 16, color: _navy),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── SESSIONS TAB ──────────────────────────────────────────────────────────

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return _buildEmptyState(Icons.calendar_today_outlined, 'No sessions yet', '');
    }
    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: _gold,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = _sessions[i] as Map<String, dynamic>;
          final lastMsg = s['last_message']?.toString() ?? '';
          String formattedDate = '';
          try {
            formattedDate = DateFormat('MMM d, HH:mm').format(DateTime.parse(lastMsg));
          } catch (_) {}

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.6), width: 2)),
              boxShadow: [BoxShadow(color: _navyMid.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [Color(0xFF0A4FA3), _navy], center: Alignment(-0.3, -0.3)),
                  border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1),
                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.15), blurRadius: 8)],
                ),
                child: const Icon(Icons.chat_bubble_outline, size: 18, color: _gold),
              ),
              title: Text(s['session_id']?.toString() ?? '',
                  style: const TextStyle(color: _textMain, fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${s['message_count'] ?? 0} messages'
                '${formattedDate.isNotEmpty ? '  ·  $formattedDate' : ''}',
                style: const TextStyle(color: _textSub, fontSize: 11),
              ),
              trailing: GestureDetector(
                onTap: () async {
                  final sid = s['session_id']?.toString() ?? '';
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Session',
                          style: TextStyle(color: _textMain, fontWeight: FontWeight.w700)),
                      content: const Text('Delete all messages in this session?',
                          style: TextStyle(color: _textSub)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: _navyMid))),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Color(0xFFC62828))),
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
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFEBEE),
                    border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFC62828), size: 16),
                ),
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
      return _buildEmptyState(Icons.bar_chart_rounded, 'No stats yet', '');
    }
    final totalMsgs  = _stats['total_messages'] ?? 0;
    final sessions   = _stats['sessions'] ?? _stats['total_sessions'] ?? 0;
    final avgConf    = ((_stats['avg_confidence'] ?? 0.0) as num).toDouble();
    final characters = _stats['characters'] as Map<String, dynamic>? ?? {};
    final topics     = _stats['topics']     as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: _gold,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _statKpi(Icons.chat_bubble_outline, 'Messages', '$totalMsgs', const Color(0xFF1565C0)),
            const SizedBox(width: 10),
            _statKpi(Icons.calendar_today_outlined, 'Sessions', '$sessions', const Color(0xFF00897B)),
            const SizedBox(width: 10),
            _statKpi(Icons.gps_fixed_outlined, 'Avg Conf', '${(avgConf * 100).toInt()}%', const Color(0xFFFF8F00)),
          ]),
          const SizedBox(height: 20),

          if (characters.isNotEmpty) ...[
            const _SectionLabel(label: 'CHARACTERS USED'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: const Border(top: BorderSide(color: _gold, width: 2.5)),
                boxShadow: [BoxShadow(color: _navyMid.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: characters.entries.map((e) {
                  final char   = AppConstants.characters[e.key];
                  final count  = (e.value as num).toInt();
                  final maxVal = characters.values.map((v) => (v as num).toInt()).reduce((a, b) => a > b ? a : b);
                  final pct    = maxVal == 0 ? 0.0 : count / maxVal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Text(char?.emoji ?? '?', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(char?.name.split(' ').first ?? e.key,
                                  style: const TextStyle(color: _textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('$count',
                                  style: TextStyle(color: char?.color ?? _navyMid, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: _textSub.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(char?.color ?? _navyMid),
                              minHeight: 7,
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (topics.isNotEmpty) ...[
            const _SectionLabel(label: 'TOP TOPICS'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: topics.entries.take(12).map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1),
                ),
                child: Text('${e.key}  ${e.value}',
                    style: const TextStyle(color: _textMain, fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _statKpi(IconData icon, String label, String value, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(top: BorderSide(color: color.withValues(alpha: 0.7), width: 2.5)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label, style: const TextStyle(color: _textSub, fontSize: 10)),
          ]),
        ),
      );

  // ── Shared states ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(alignment: Alignment.center, children: [
            Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: _gold.withValues(alpha: 0.25), width: 1))),
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF0A4FA3), _navy], center: Alignment(-0.3, -0.3)),
                boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.2), blurRadius: 16)],
              ),
              child: const Icon(Icons.history_edu, color: _gold, size: 26),
            ),
          ]),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: _gold, strokeWidth: 2),
          const SizedBox(height: 16),
          const Text('Loading history...', style: TextStyle(color: _textSub, fontSize: 13, letterSpacing: 0.3)),
        ]),
      );

  Widget _buildEmptyState(IconData icon, String title, String subtitle) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: _gold.withValues(alpha: 0.15), width: 1))),
              Container(width: 88, height: 88,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.5))),
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [Color(0xFF0A4FA3), _navy], center: Alignment(-0.3, -0.3)),
                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 18, spreadRadius: 2)],
                ),
                child: Icon(icon, size: 28, color: _gold),
              ),
            ]),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textMain)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: _textSub)),
            ],
          ]),
        ),
      );
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 3, height: 13,
            decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF002D72), fontSize: 10,
            fontWeight: FontWeight.w800, letterSpacing: 2.5)),
      ]);
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
      canvas.drawLine(Offset(size.width * i / 6, 0), Offset(size.width * i / 6 + 40, size.height), p);
    }
    final dot = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(Offset(size.width - 20 - i * 20.0, 12 + j * 20.0), 1.6, dot);
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
      begin: Alignment(progress - 1, 0), end: Alignment(progress, 0),
      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.04), Colors.transparent],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF5F8FF)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.30);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}