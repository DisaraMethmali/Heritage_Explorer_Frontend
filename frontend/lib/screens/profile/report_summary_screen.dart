// lib/screens/profile/report_summary_screen.dart
//
// Enhanced RAG Report Viewer
// Addresses panel comments on usability & accessibility:
//   Topic cards with server-generated key points (highlighted)
//   Live keyword search with inline match highlighting
//   TTS speaker with pause/resume/speed controls (flutter_tts)
//   PDF download per location (temple / galle / all)
//   Confidence badge, session count, character chips
//   Empty / loading / error states
//
// pubspec.yaml — add these if not present:
//   flutter_tts: ^4.0.2
//   http: ^1.2.1          (already in your project)
//   path_provider: ^2.1.3 (already in your project)
//   open_filex: ^4.3.4    (already in your project)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/constants.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _TopicSummary {
  final String location; // "temple" | "galle" | "general"
  final int count;
  final String summary;
  final List<String> keyPoints;

  const _TopicSummary({
    required this.location,
    required this.count,
    required this.summary,
    required this.keyPoints,
  });

  factory _TopicSummary.fromJson(String loc, Map<String, dynamic> j) =>
      _TopicSummary(
        location:  loc,
        count:     j['count']   as int? ?? 0,
        summary:   j['summary'] as String? ?? '',
        keyPoints: List<String>.from(j['key_points'] ?? []),
      );
}

class _PreviewData {
  final int totalMessages;
  final int templeMessages;
  final int galleMessages;
  final int generalMessages;
  final double avgConfidencePct;
  final int uniqueSessions;
  final bool hasTempleReport;
  final bool hasGalleReport;
  final Map<String, int> charactersUsed;
  final Map<String, _TopicSummary> topicSummaries;

  const _PreviewData({
    required this.totalMessages,
    required this.templeMessages,
    required this.galleMessages,
    required this.generalMessages,
    required this.avgConfidencePct,
    required this.uniqueSessions,
    required this.hasTempleReport,
    required this.hasGalleReport,
    required this.charactersUsed,
    required this.topicSummaries,
  });

  factory _PreviewData.fromJson(Map<String, dynamic> j) {
    final raw = Map<String, dynamic>.from(j['topic_summaries'] ?? {});
    final summaries = <String, _TopicSummary>{};
    raw.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        summaries[k] = _TopicSummary.fromJson(k, v);
      }
    });
    return _PreviewData(
      totalMessages:    j['total_messages']    as int?    ?? 0,
      templeMessages:   j['temple_messages']   as int?    ?? 0,
      galleMessages:    j['galle_messages']    as int?    ?? 0,
      generalMessages:  j['general_messages']  as int?    ?? 0,
      avgConfidencePct: (j['avg_confidence_pct'] as num?) ?.toDouble() ?? 0,
      uniqueSessions:   j['unique_sessions']   as int?    ?? 0,
      hasTempleReport:  j['has_temple_report'] as bool?   ?? false,
      hasGalleReport:   j['has_galle_report']  as bool?   ?? false,
      charactersUsed:   Map<String, int>.from(
          (j['characters_used'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt())) ?? {}),
      topicSummaries: summaries,
    );
  }

  // Collect all key points across all topics for TTS & search
  List<String> get allKeyPoints => topicSummaries.values
      .expand((s) => s.keyPoints)
      .toList();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportSummaryScreen extends StatefulWidget {
  final String authToken;
  final String username;

  const ReportSummaryScreen({
    super.key,
    required this.authToken,
    required this.username,
  });

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen>
    with TickerProviderStateMixin {

  // ── Design tokens (match ProfileScreen) ──────────────────────────────────
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

  static const Map<String, Color> _topicColors = {
    'temple':  Color(0xFFA855F7),
    'galle':   Color(0xFF3B82F6),
    'general': Color(0xFF10B981),
  };
  static const Map<String, String> _topicEmoji = {
    'temple':  '🛕',
    'galle':   '🏰',
    'general': '📖',
  };
  static const Map<String, String> _topicLabel = {
    'temple':  'Temple of the Sacred Tooth',
    'galle':   'Galle Fort',
    'general': 'General History',
  };

  // ── State ─────────────────────────────────────────────────────────────────
  _PreviewData? _preview;
  bool   _loading      = true;
  String? _error;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool   _ttsPlaying = false;
  bool   _ttsPaused  = false;
  double _ttsSpeed   = 0.5;
  int    _ttsIndex   = 0;   // which key point is being read

  // Download
  String? _downloadingLocation;

  // Animations
  late AnimationController _shimmerCtrl;
  late Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });

    _initTts();
    _fetchPreview();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _searchCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  // ── TTS setup ────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_ttsSpeed);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      final points = _allVisiblePoints(); // use filtered list
      if (_ttsIndex + 1 < points.length) {
        setState(() => _ttsIndex++);
        _tts.speak(points[_ttsIndex]);
      } else {
        setState(() {
          _ttsPlaying = false;
          _ttsPaused  = false;
          _ttsIndex   = 0;
        });
      }
    });

    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() { _ttsPlaying = false; _ttsPaused = false; });
    });
  }

  /// Returns all currently-visible key points across all topics in order.
  /// Respects search filter so TTS only reads matching points.
  List<String> _allVisiblePoints() {
    if (_preview == null) return [];
    final result = <String>[];
    for (final loc in ['temple', 'galle', 'general']) {
      final summary = _preview!.topicSummaries[loc];
      if (summary == null) continue;
      for (final point in summary.keyPoints) {
        if (_pointMatchesSearch(point)) {
          result.add(point);
        }
      }
    }
    return result;
  }

  Future<void> _toggleTts() async {
    final points = _allVisiblePoints();
    if (points.isEmpty) return;

    if (_ttsPlaying && !_ttsPaused) {
      await _tts.pause();
      setState(() => _ttsPaused = true);
    } else if (_ttsPaused) {
      await _tts.speak(points[_ttsIndex]);
      setState(() => _ttsPaused = false);
    } else {
      setState(() {
        _ttsPlaying = true;
        _ttsPaused  = false;
        _ttsIndex   = 0;
      });
      await _tts.speak(points[0]);
    }
  }

  Future<void> _stopTts() async {
    await _tts.stop();
    setState(() { _ttsPlaying = false; _ttsPaused = false; _ttsIndex = 0; });
  }

  Future<void> _setTtsSpeed(double v) async {
    setState(() => _ttsSpeed = v);
    await _tts.setSpeechRate(v);
  }

  // ── Network ───────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.authToken}',
    'Content-Type': 'application/json',
  };

  Future<void> _fetchPreview() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/report/preview'),
               headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          setState(() => _preview = _PreviewData.fromJson(body));
        } else {
          setState(() => _error = body['error'] ?? 'Unknown error');
        }
      } else if (res.statusCode == 404) {
        setState(() => _error = 'no_history');
      } else {
        setState(() => _error = 'Server error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadPdf(String location) async {
    if (_downloadingLocation != null) return;
    setState(() => _downloadingLocation = location);

    final filename = location == 'all'
        ? 'full_report_${widget.username}.pdf'
        : '${location}_report_${widget.username}.pdf';

    try {
      final res = await http
          .get(
            Uri.parse(
                '${AppConstants.baseUrl}/report/user?location=$location'),
            headers: _headers)
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _snack(body['error'] ?? 'Download failed', isError: true);
        return;
      }
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(res.bodyBytes);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _snack('PDF saved to ${file.path}');
      } else if (mounted) {
        _snack('Report opened');
      }
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _downloadingLocation = null);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ── Search highlight helper ───────────────────────────────────────────────

  /// Returns a TextSpan with query occurrences highlighted in gold.
  TextSpan _highlightText(String text, {TextStyle? base}) {
    if (_searchQuery.isEmpty) {
      return TextSpan(text: text, style: base);
    }
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lower.indexOf(_searchQuery, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + _searchQuery.length),
        style: (base ?? const TextStyle()).copyWith(
          backgroundColor: _gold.withValues(alpha: 0.4),
          color: _navy,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + _searchQuery.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: base));
    }
    return TextSpan(children: spans);
  }

  bool _pointMatchesSearch(String point) =>
      _searchQuery.isEmpty ||
      point.toLowerCase().contains(_searchQuery);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      body: Column(children: [
        // _buildHeroStats(),
        _buildSearchBar(),
        _buildTtsBar(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
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
    title: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _gold, width: 1.5),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: const Icon(Icons.auto_stories_outlined, size: 16, color: _gold),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('JOURNEY REPORT',
              style: TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w800, letterSpacing: 2.0)),
          Text('Historical knowledge summary',
              style: TextStyle(color: _gold, fontSize: 10,
                  fontWeight: FontWeight.w400, letterSpacing: 1.2)),
        ],
      ),
    ]),
    actions: [
      // Refresh button
      GestureDetector(
        onTap: _loading ? null : _fetchPreview,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Icon(
            _loading ? Icons.hourglass_top : Icons.refresh_rounded,
            color: _gold, size: 16,
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

  // ── Hero stats strip ──────────────────────────────────────────────────────

  Widget _buildHeroStats() {
    if (_loading || _preview == null) return const SizedBox.shrink();
    final p = _preview!;
    return Container(
      color: _navy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(children: [
        _statPill('${p.totalMessages}', 'conversations'),
        const SizedBox(width: 10),
        _statPill('${p.uniqueSessions}', 'sessions'),
        const SizedBox(width: 10),
        _statPill('${p.avgConfidencePct.toStringAsFixed(0)}%', 'confidence'),
        if (p.charactersUsed.isNotEmpty) ...[
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: p.charactersUsed.keys.map((id) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _charChip(id),
                    )).toList(),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _statPill(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _gold.withValues(alpha: 0.3)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(
          color: _gold, fontSize: 14, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(
          color: Colors.white54, fontSize: 9, letterSpacing: 0.5)),
    ]),
  );

  Widget _charChip(String id) {
    const emojis = {
      'king': '👑', 'nilame': '🛕', 'dutch': '⚓', 'citizen': '📚'
    };
    const names = {
      'king': 'King', 'nilame': 'Nilame',
      'dutch': 'Dutch', 'citizen': 'Historian'
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '${emojis[id] ?? '🎭'} ${names[id] ?? id}',
        style: const TextStyle(
            color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: _textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search key points…',
        hintStyle: TextStyle(color: _textSub.withValues(alpha: 0.7), fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: _navyMid, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                child: Icon(Icons.close_rounded, color: _textSub, size: 18))
            : null,
        filled: true,
        fillColor: _inputBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: _textSub.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: _textSub.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: _navyMid, width: 1.5)),
      ),
    ),
  );

  // ── TTS control bar ───────────────────────────────────────────────────────

  Widget _buildTtsBar() {
    if (_preview == null || _preview!.allKeyPoints.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _navy.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          // Play / Pause
          GestureDetector(
            onTap: _toggleTts,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [_goldDeep, _gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                boxShadow: [BoxShadow(
                    color: _gold.withValues(alpha: 0.3), blurRadius: 6)],
              ),
              child: Icon(
                _ttsPlaying && !_ttsPaused
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: _navy, size: 20,
              ),
            ),
          ),
          // Stop
          if (_ttsPlaying || _ttsPaused) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _stopTts,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _textSub.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.stop_rounded, color: _textSub, size: 16),
              ),
            ),
          ],
          const SizedBox(width: 12),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _ttsPlaying && !_ttsPaused
                      ? 'Reading point ${_ttsIndex + 1} of ${_preview!.allKeyPoints.length}'
                      : _ttsPaused
                          ? 'Paused — tap to resume'
                          : 'Listen to key points',
                  style: const TextStyle(
                      color: _textMain, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                // Speed slider
                Row(children: [
                  const Text('Speed', style: TextStyle(color: _textSub, fontSize: 10)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: _navyMid,
                        inactiveTrackColor: _textSub.withValues(alpha: 0.2),
                        thumbColor: _navyMid,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: _ttsSpeed,
                        min: 0.3, max: 1.0, divisions: 7,
                        onChanged: _setTtsSpeed,
                      ),
                    ),
                  ),
                  Text('${(_ttsSpeed * 100).toInt()}%',
                      style: const TextStyle(color: _textSub, fontSize: 10)),
                ]),
              ],
            ),
          ),
          // Speaker icon badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _navyMid.withValues(alpha: 0.08),
            ),
            child: Icon(
              _ttsPlaying && !_ttsPaused
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _ttsPlaying ? _navyMid : _textSub, size: 18,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Body (loading / error / content) ─────────────────────────────────────

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error == 'no_history') return _buildNoHistory();
    if (_error != null) return _buildError(_error!);
    if (_preview == null) return const SizedBox.shrink();
    return _buildContent(_preview!);
  }

  Widget _buildSkeleton() => ListView(
    padding: const EdgeInsets.all(16),
    children: List.generate(3, (_) => _skeletonCard()),
  );

  Widget _skeletonCard() => AnimatedBuilder(
    animation: _shimmer,
    builder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment(_shimmer.value - 1, 0),
          end: Alignment(_shimmer.value, 0),
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.5),
          ],
        ),
      ),
    ),
  );

  Widget _buildNoHistory() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _navyMid.withValues(alpha: 0.08),
            border: Border.all(color: _navyMid.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              size: 36, color: _navyMid),
        ),
        const SizedBox(height: 20),
        const Text('No conversations yet',
            style: TextStyle(color: _textMain, fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'Chat with the historical characters first,\nthen come back to view your report.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSub, fontSize: 13, height: 1.5),
        ),
      ]),
    ),
  );

  Widget _buildError(String err) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFC62828)),
        const SizedBox(height: 16),
        Text(err, textAlign: TextAlign.center,
            style: const TextStyle(color: _textSub, fontSize: 13)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _fetchPreview,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _navyMid,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildContent(_PreviewData p) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    children: [
      // ── Topic cards ─────────────────────────────────────────────────────
      for (final loc in ['temple', 'galle'])
        if (p.topicSummaries.containsKey(loc))
          _buildTopicCard(p.topicSummaries[loc]!, loc),

      const SizedBox(height: 8),

      // ── Download section ─────────────────────────────────────────────────
      _buildDownloadSection(p),
    ],
  );

  // ── Topic card ────────────────────────────────────────────────────────────

  Widget _buildTopicCard(_TopicSummary topic, String loc) {
    final color = _topicColors[loc] ?? _navyMid;
    final emoji = _topicEmoji[loc] ?? '📖';
    final label = _topicLabel[loc] ?? loc;

    // Filter key points by search
    final visiblePoints = topic.keyPoints
        .where(_pointMatchesSearch)
        .toList();

    // Dim the whole card if search is active and no points match
    final dimmed = _searchQuery.isNotEmpty && visiblePoints.isEmpty;

    return AnimatedOpacity(
      opacity: dimmed ? 0.35 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(top: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header ─────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: _textMain, fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      RichText(
                        text: _highlightText(
                          topic.summary,
                          base: const TextStyle(
                              color: _textSub, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                // Conversation count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${topic.count}',
                    style: TextStyle(
                        color: color, fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ]),

              if (visiblePoints.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFFFB800), size: 14),
                  const SizedBox(width: 6),
                  const Text('Key Historical Points',
                      style: TextStyle(
                          color: _textSub, fontSize: 11,
                          letterSpacing: 0.8, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                ...visiblePoints.asMap().entries.map((e) =>
                    _buildKeyPoint(e.value, color, e.key)),
              ] else if (_searchQuery.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'No matches for "$_searchQuery" in this topic',
                    style: TextStyle(
                        color: _textSub.withValues(alpha: 0.6),
                        fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _inputBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No key points could be extracted from this topic yet. '
                      'Continue chatting to build up your history summary.',
                      style: TextStyle(color: _textSub, fontSize: 12, height: 1.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPoint(String point, Color color, int index) {
    // Use _allVisiblePoints() so index is consistent with TTS
    final allPoints = _allVisiblePoints();
    final globalIdx = allPoints.indexOf(point);
    final isActive  = _ttsPlaying && !_ttsPaused && globalIdx == _ttsIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.12)
            : _inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color : _textSub.withValues(alpha: 0.15),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet
          Container(
            margin: const EdgeInsets.only(top: 3, right: 10),
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : _textSub.withValues(alpha: 0.5),
            ),
          ),
          Expanded(
            child: RichText(
              text: _highlightText(
                point,
                base: TextStyle(
                  color: isActive ? _navy : _textMain,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          // TTS play-this-point button
          GestureDetector(
            onTap: () async {
              await _stopTts();
              final allPoints = _allVisiblePoints(); // use this instead of _preview?.allKeyPoints
              final idx = allPoints.indexOf(point);
              if (idx >= 0) {
                setState(() {
                  _ttsPlaying = true;
                  _ttsPaused  = false;
                  _ttsIndex   = idx;
                });
                await _tts.speak(point);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                isActive
                    ? Icons.volume_up_rounded
                    : Icons.play_circle_outline_rounded,
                color: isActive ? color : _textSub.withValues(alpha: 0.4),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Download section ──────────────────────────────────────────────────────

  Widget _buildDownloadSection(_PreviewData p) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: const Border(top: BorderSide(color: _gold, width: 3)),
      boxShadow: [
        BoxShadow(
          color: _navyMid.withValues(alpha: 0.07),
          blurRadius: 14, offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: 0.12),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: _goldDeep, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Download Report',
                    style: TextStyle(color: _textMain, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text('Get your personalised history PDF',
                    style: TextStyle(color: _textSub, fontSize: 11)),
              ],
            ),
          ),
        ]),

        const SizedBox(height: 14),

        // Location buttons row (temple, galle if available)
        if (p.hasTempleReport || p.hasGalleReport)
          Row(children: [
            if (p.hasTempleReport)
              Expanded(child: _downloadChip(
                  '🛕 Temple', 'temple',
                  const Color(0xFFA855F7))),
            if (p.hasTempleReport && p.hasGalleReport)
              const SizedBox(width: 8),
            if (p.hasGalleReport)
              Expanded(child: _downloadChip(
                  '🏰 Galle', 'galle',
                  const Color(0xFF3B82F6))),
          ]),

        if (p.hasTempleReport || p.hasGalleReport)
          const SizedBox(height: 8),

        // Full report button
        _fullDownloadButton(p),
      ],
    ),
  );

  Widget _downloadChip(String label, String loc, Color color) {
    final loading = _downloadingLocation == loc;
    final disabled = _downloadingLocation != null && !loading;
    return GestureDetector(
      onTap: (disabled || loading) ? null : () => _downloadPdf(loc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        decoration: BoxDecoration(
          color: disabled ? _inputBg : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? _textSub.withValues(alpha: 0.2) : color.withValues(alpha: 0.5),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color))
          else
            Icon(Icons.download_for_offline_outlined,
                color: disabled ? _textSub : color, size: 16),
          const SizedBox(width: 6),
          Text(loading ? 'Generating…' : label,
              style: TextStyle(
                color: disabled ? _textSub : color,
                fontSize: 12, fontWeight: FontWeight.w700,
              )),
        ]),
      ),
    );
  }

  Widget _fullDownloadButton(_PreviewData p) {
    final loading  = _downloadingLocation == 'all';
    final disabled = _downloadingLocation != null && !loading;
    return GestureDetector(
      onTap: (disabled || loading) ? null : () => _downloadPdf('all'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: disabled ? null : const LinearGradient(
            colors: [_goldDeep, _gold, Color(0xFFFFC200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: disabled ? _textSub.withValues(alpha: 0.15) : null,
          boxShadow: disabled ? [] : [
            BoxShadow(
              color: _gold.withValues(alpha: 0.35),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _navy.withValues(alpha: 0.12)),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _navy))
                : Icon(Icons.download_for_offline_outlined,
                    color: disabled ? _textSub : _navy, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            loading ? 'Generating Full Report…' : 'Download Full Report  (All Locations)',
            style: TextStyle(
              color: disabled ? _textSub : _navy,
              fontWeight: FontWeight.w700, fontSize: 13,
            ),
          ),
        ]),
      ),
    );
  }
}