// lib/screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/gradient_button.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final ApiService   _api   = ApiService();
  final VoiceService _voice = VoiceService();
  late TabController _tabCtrl;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _navy     = Color(0xFF001233);
  static const Color _navyMid  = Color(0xFF002D72);
  static const Color _blue     = Color(0xFF023E8A);
  static const Color _blueMid  = Color(0xFF0077B6);
  static const Color _gold     = Color(0xFFFFD700);
  static const Color _goldDeep = Color(0xFFFFB800);
  static const Color _pageBg   = Color(0xFFF5F8FF);
  static const Color _cardBg   = Color(0xFFFFFFFF);
  static const Color _inputBg  = Color(0xFFF0F6FF);
  static const Color _textMain = Color(0xFF001845);
  static const Color _textSub  = Color(0xFF445577);
  static const Color _textMute = Color(0xFF90A4C4);
  static const Color _saffron  = Color(0xFFE65100);
  static const Color _jade     = Color(0xFF00695C);

  // State
  Map<String, dynamic> _allLegends   = {};
  bool _loadingLegends = false;

  final _causalCtrl = TextEditingController();
  Map<String, dynamic>? _causalResult;
  bool _loadingCausal = false;

  final _anomalyCtrl = TextEditingController();
  Map<String, dynamic>? _anomalyResult;
  bool _loadingAnomaly = false;

  Map<String, dynamic> _vrSites = {};
  bool _loadingVr = false;

  // Animations
  late AnimationController _shimmerController;
  late Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    _loadLegends();
    _loadVrSites();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _causalCtrl.dispose();
    _anomalyCtrl.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _loadLegends() async {
    setState(() => _loadingLegends = true);
    try {
      final data = await _api.getAllFolklore();
      setState(() {
        _allLegends = data['legends'] as Map<String, dynamic>? ?? {};
        _loadingLegends = false;
      });
    } catch (_) {
      setState(() => _loadingLegends = false);
    }
  }

  Future<void> _loadVrSites() async {
    setState(() => _loadingVr = true);
    try {
      final data = await _api.discoverVrSites(
        sessionId: 'explore',
        currentTopic: 'general',
        characterId: 'citizen',
      );
      setState(() {
        _vrSites = {'suggestions': data['suggestions'] ?? []};
        _loadingVr = false;
      });
    } catch (_) {
      setState(() => _loadingVr = false);
    }
  }

  Future<void> _fetchCausalChain(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loadingCausal = true; _causalResult = null; });
    try {
      final data = await _api.getCausalChain(query);
      setState(() { _causalResult = data; _loadingCausal = false; });
    } catch (_) {
      setState(() => _loadingCausal = false);
    }
  }

  Future<void> _checkAnomaly(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loadingAnomaly = true; _anomalyResult = null; });
    try {
      final data = await _api.checkAnomaly(query);
      setState(() { _anomalyResult = data; _loadingAnomaly = false; });
    } catch (_) {
      setState(() => _loadingAnomaly = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHero(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLegendsTab(),
                _buildCausalTab(),
                _buildAnomalyTab(),
                _buildVrTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 1.5),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.explore_outlined, size: 17, color: _gold),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'EXPLORE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'Heritage Knowledge',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.6),
            border: const Border(
              bottom: BorderSide(color: Color(0x44FFD700), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: _gold, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 12),
            ),
            labelColor: _gold,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            isScrollable: true,
            tabs: const [
              Tab(text: '📖  LEGENDS'),
              Tab(text: '⛓  CAUSAL CHAINS'),
              Tab(text: '⚠  FACT CHECK'),
              Tab(text: '🏛  VR SITES'),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              height: 130,
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
            Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
            Positioned.fill(
                child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 28),
                painter: _WavePainter(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── LEGENDS TAB ────────────────────────────────────────────────────────────

  Widget _buildLegendsTab() {
    if (_loadingLegends) return _buildLoadingCenter();
    if (_allLegends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        tag: 'FOLKLORE',
        title: 'No Legends Loaded',
        subtitle: 'Unable to retrieve folklore data.',
        action: TextButton(
          onPressed: _loadLegends,
          child: const Text('Retry', style: TextStyle(color: _navyMid, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _allLegends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final key    = _allLegends.keys.elementAt(i);
        final legend = _allLegends[key] as Map<String, dynamic>;
        return _legendCard(legend);
      },
    );
  }

  Widget _legendCard(Map<String, dynamic> legend) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: const Border(top: BorderSide(color: _gold, width: 2.5)),
        boxShadow: [
          BoxShadow(
            color: _navyMid.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _navyMid.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_stories_outlined, color: _navyMid, size: 20),
          ),
          title: Text(
            legend['title']?.toString() ?? '',
            style: const TextStyle(
                color: _textMain, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              'Keywords: ${(legend['keywords'] as List?)?.take(2).join(', ') ?? ''}',
              style: const TextStyle(color: _textMute, fontSize: 11),
            ),
          ),
          iconColor: _navyMid,
          collapsedIconColor: _textMute,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: _navyMid.withValues(alpha: 0.08),
                    margin: const EdgeInsets.only(bottom: 14),
                  ),
                  _expandedSection('✨  LEGEND',
                      legend['legend']?.toString() ?? '', _saffron),
                  const SizedBox(height: 14),
                  _expandedSection('📚  HISTORICAL FACT',
                      legend['historical_fact']?.toString() ?? '', _jade),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _voice.speak(
                      '${legend['legend']} Historical fact: ${legend['historical_fact']}',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _navyMid.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _navyMid.withValues(alpha: 0.15), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _navyMid.withValues(alpha: 0.10),
                            ),
                            child: const Icon(Icons.volume_up_outlined,
                                color: _navyMid, size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text('Listen',
                              style: TextStyle(
                                  color: _navyMid,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedSection(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3, height: 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 7),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.8)),
          ],
        ),
        const SizedBox(height: 8),
        Text(content,
            style: const TextStyle(
                color: _textSub, height: 1.6, fontSize: 13.5)),
      ],
    );
  }

  // ── CAUSAL CHAINS TAB ──────────────────────────────────────────────────────

  Widget _buildCausalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(
            icon: Icons.account_tree_outlined,
            tag: 'CAUSE & EFFECT',
            title: 'Historical Chain of Events',
            subtitle:
                'Understand WHY things happened — step-by-step cause and effect',
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'TRY ASKING'),
          const SizedBox(height: 10),
          ...[
            'Why did Kandy remain independent?',
            'How did cinnamon trade develop?',
            'Why was the Tooth Relic important for kingship?',
          ].map((q) => _SuggestionRow(
                question: q,
                accentColor: const Color(0xFFB8860B),
                bgColor: _gold.withValues(alpha: 0.07),
                borderColor: _gold.withValues(alpha: 0.3),
                icon: Icons.lightbulb_outline,
                onTap: () { _causalCtrl.text = q; _fetchCausalChain(q); },
              )),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _causalCtrl,
            hint: 'Enter your historical question...',
            icon: Icons.history_edu_outlined,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Get Causal Chain',
            icon: Icons.account_tree_outlined,
            isLoading: _loadingCausal,
            onPressed: () => _fetchCausalChain(_causalCtrl.text),
          ),
          if (_causalResult != null) ...[
            const SizedBox(height: 22),
            _buildCausalResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildCausalResult() {
    final found = _causalResult!['chain_found'] == true;
    if (!found) {
      return _buildAlertBox(
        color: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
        icon: Icons.warning_amber_outlined,
        text: 'No causal chain found for this query. Try the suggested questions above.',
      );
    }
    final chain = _causalResult!['chain'] as Map<String, dynamic>;
    final steps = chain['chain'] as List? ?? [];
    final title = chain['title']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: title.toUpperCase()),
        const SizedBox(height: 14),
        ...steps.asMap().entries.map((e) =>
            _chainStep(e.key + 1, e.value as Map<String, dynamic>,
                e.key == steps.length - 1)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () =>
              _voice.speak(_causalResult!['formatted']?.toString() ?? ''),
          child: _listenButton(),
        ),
      ],
    );
  }

  Widget _chainStep(int num, Map<String, dynamic> step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_navyMid, _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _navyMid.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text('$num',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _navyMid.withValues(alpha: 0.3),
                      _navyMid.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _navyMid.withValues(alpha: 0.10), width: 1),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step['event']} (${step['year']})',
                  style: const TextStyle(
                      color: _textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                _causeEffectRow('→  CAUSE',
                    step['cause']?.toString() ?? '', _saffron),
                const SizedBox(height: 5),
                _causeEffectRow('⬇  EFFECT',
                    step['effect']?.toString() ?? '', _jade),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _causeEffectRow(String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  ',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.0)),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: _textSub, fontSize: 12, height: 1.5)),
        ),
      ],
    );
  }

  // ── ANOMALY / FACT CHECK TAB ───────────────────────────────────────────────

  Widget _buildAnomalyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(
            icon: Icons.fact_check_outlined,
            tag: 'MISCONCEPTIONS',
            title: 'Historical Fact Checker',
            subtitle:
                'Detects common misconceptions about Sri Lankan history',
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'COMMON MYTHS'),
          const SizedBox(height: 10),
          ...[
            'The Portuguese conquered Kandy',
            'The actual Tooth Relic is carried in the Perahera',
            'Dutch built Galle Fort from scratch',
            'Sri Lanka was always Buddhist',
          ].map((q) => _SuggestionRow(
                question: q,
                accentColor: const Color(0xFFC62828),
                bgColor: const Color(0xFFC62828).withValues(alpha: 0.05),
                borderColor:
                    const Color(0xFFC62828).withValues(alpha: 0.20),
                icon: Icons.help_outline,
                onTap: () { _anomalyCtrl.text = q; _checkAnomaly(q); },
              )),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _anomalyCtrl,
            hint: 'Enter a historical statement...',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Check Facts',
            icon: Icons.search_outlined,
            isLoading: _loadingAnomaly,
            onPressed: () => _checkAnomaly(_anomalyCtrl.text),
          ),
          if (_anomalyResult != null) ...[
            const SizedBox(height: 22),
            _buildAnomalyResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomalyResult() {
    final detected   = _anomalyResult!['misconception_detected'] == true;
    final result     = _anomalyResult!['result'] as Map<String, dynamic>?;
    final correction = result?['correction']?.toString() ?? '';
    final severity   = result?['severity']?.toString() ?? '';

    final Color fg = detected ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    final Color bg = detected
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE8F5E9);
    final IconData iconData = detected
        ? Icons.warning_amber_outlined
        : Icons.check_circle_outline;
    final String title = detected
        ? 'Misconception Detected  ·  Severity: $severity'
        : 'No Misconceptions Found';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fg.withValues(alpha: 0.12),
                ),
                child: Icon(iconData, color: fg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
          if (correction.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: fg.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(correction,
                style: const TextStyle(
                    color: _textSub, height: 1.6, fontSize: 13.5)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _voice.speak(correction),
              child: _listenButton(),
            ),
          ],
        ],
      ),
    );
  }

  // ── VR SITES TAB ───────────────────────────────────────────────────────────

  Widget _buildVrTab() {
    final sites =
        (_vrSites['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: _buildTabHeader(
            icon: Icons.vrpano_outlined,
            tag: 'IMMERSIVE',
            title: 'VR Historical Sites',
            subtitle:
                'Immersive virtual reality experiences at historical locations',
          ),
        ),
        Expanded(
          child: _loadingVr
              ? _buildLoadingCenter()
              : sites.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.vrpano_outlined,
                      tag: 'VR SITES',
                      title: 'No Sites Available',
                      subtitle:
                          'Virtual reality sites could not be loaded.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: sites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _vrSiteCard(sites[i]),
                    ),
        ),
      ],
    );
  }

  Widget _vrSiteCard(Map<String, dynamic> site) {
    final typeColors = {
      'sacred_site':   const Color(0xFFB71C1C),
      'colonial_site': _navyMid,
      'cultural_site': const Color(0xFF00695C),
      'royal_site':    const Color(0xFF6A0080),
      'trade_site':    const Color(0xFF803600),
      'ancient_site':  const Color(0xFF004040),
    };
    final Color color = typeColors[site['type']] ?? _blue;
    final String typeLabel =
        (site['type']?.toString() ?? '').replaceAll('_', ' ').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          top: BorderSide(color: color, width: 2.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withValues(alpha: 0.12),
                  ),
                  child:
                      const Icon(Icons.account_balance_outlined, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site['name']?.toString() ?? '',
                        style: const TextStyle(
                            color: _textMain,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 3, height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(typeLabel,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site['description']?.toString() ?? '',
                  style: const TextStyle(
                      color: _textSub, height: 1.55, fontSize: 13),
                ),
                const SizedBox(height: 12),

                // VR experience box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.vrpano_outlined,
                            color: Color(0xFFB8860B), size: 15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VR EXPERIENCE',
                                style: TextStyle(
                                    color: Color(0xFFB8860B),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(
                              site['vr_experience']?.toString() ?? '',
                              style: const TextStyle(
                                  color: _textSub,
                                  fontSize: 12.5,
                                  height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Discovery trigger
                Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        size: 13, color: _textMute),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        site['discovery_trigger']?.toString() ?? '',
                        style: const TextStyle(
                            color: _textMute,
                            fontSize: 11,
                            height: 1.4),
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

  // ── Shared components ──────────────────────────────────────────────────────

  Widget _buildTabHeader({
    required IconData icon,
    required String tag,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _navyMid.withValues(alpha: 0.08),
          ),
          child: Icon(icon, color: _navyMid, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: _gold.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        color: Color(0xFFB8860B),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8)),
              ),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(
                      color: _textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                      color: _textMute, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _navyMid.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: _textMain, fontSize: 14),
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMute, fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: _textMute, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [_goldDeep, _gold, Color(0xFFFFC200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isLoading ? const Color(0xFFDDE6F0) : null,
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _navyMid))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _navy.withValues(alpha: 0.10),
                      ),
                      child: Icon(icon, color: _navy, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Text(label,
                        style: const TextStyle(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _listenButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _navyMid.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: _navyMid.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _navyMid.withValues(alpha: 0.10),
            ),
            child: const Icon(Icons.volume_up_outlined,
                color: _navyMid, size: 13),
          ),
          const SizedBox(width: 8),
          const Text('Listen',
              style: TextStyle(
                  color: _navyMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAlertBox({
    required Color color,
    required Color bg,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCenter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _gold.withValues(alpha: 0.25), width: 1),
                ),
              ),
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF0A4FA3), _navy],
                    center: Alignment(-0.3, -0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: _gold.withValues(alpha: 0.2), blurRadius: 14),
                  ],
                ),
                child: const Icon(Icons.hourglass_empty,
                    color: _gold, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: _gold, strokeWidth: 2),
          const SizedBox(height: 12),
          const Text('Loading...',
              style: TextStyle(color: _textMute, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String tag,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.15), width: 1),
                  ),
                ),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.40), width: 1.5),
                  ),
                ),
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF0A4FA3), _navy],
                      center: Alignment(-0.3, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: _gold.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2),
                    ],
                  ),
                  child: Icon(icon, color: _gold, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: _gold.withValues(alpha: 0.4), width: 1),
              ),
              child: Text(tag,
                  style: const TextStyle(
                      color: Color(0xFFB8860B),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0)),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textMain),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: _textMute, height: 1.5)),
            if (action != null) ...[
              const SizedBox(height: 14),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Suggestion row ────────────────────────────────────────────────────────────

class _SuggestionRow extends StatelessWidget {
  final String question;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.question,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.10),
              ),
              child: Icon(icon, color: accentColor, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(question,
                  style: const TextStyle(
                      color: Color(0xFF001845),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.arrow_forward_ios,
                color: const Color(0xFF90A4C4).withValues(alpha: 0.7),
                size: 12),
          ],
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
          width: 3, height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
              color: Color(0xFF002D72),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            )),
      ],
    );
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
    canvas.drawCircle(Offset(-20, size.height * 1.2), size.width * 0.45, p);
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.03);
    p.strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x + 40, size.height), p);
    }
    final dot = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
            Offset(size.width - 20 - i * 18.0, 16 + j * 18.0), 1.5, dot);
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
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
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
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}