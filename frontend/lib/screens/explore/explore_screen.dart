import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';
import '../../utils/theme.dart';
import '../../widgets/gradient_button.dart';

// ── Light-mode colour constants (replaces AppTheme dark tokens inline) ──────
// Primary blues
const _blue900 = Color(0xFF0D47A1);
const _blue800 = Color(0xFF1565C0);
// Light yellow accents
const _yellowLight = Color(0xFFFFF9C4); // very light yellow background tint
const _yellowMid   = Color(0xFFFFF176); // slightly richer yellow for accents
const _yellowDeep  = Color(0xFFF9A825); // amber-ish for "gold" replacements
// Surfaces
const _bgLight      = Color(0xFFF5F7FF); // near-white with a hint of blue
const _cardLight    = Color(0xFFFFFFFF);
const _surfaceLight = Color(0xFFEEF2FF);
const _borderColor  = Color(0xFFBBCEF5);
// Text
const _textPrimary   = Color(0xFF0D2150);
const _textSecondary = Color(0xFF3D5A99);
const _textHint      = Color(0xFF8DA5CC);
// Semantic
const _saffron = Color(0xFFE65100);   // kept for cause/effect labels
const _jade    = Color(0xFF00695C);   // kept for historical fact labels

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final VoiceService _voice = VoiceService();
  late TabController _tabCtrl;

  // Folklore
  Map<String, dynamic> _allLegends = {};
  bool _loadingLegends = false;

  // Causal chain
  final _causalCtrl = TextEditingController();
  Map<String, dynamic>? _causalResult;
  bool _loadingCausal = false;

  // Anomaly
  final _anomalyCtrl = TextEditingController();
  Map<String, dynamic>? _anomalyResult;
  bool _loadingAnomaly = false;

  // VR Sites
  Map<String, dynamic> _vrSites = {};
  bool _loadingVr = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadLegends();
    _loadVrSites();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _causalCtrl.dispose();
    _anomalyCtrl.dispose();
    super.dispose();
  }

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
        _vrSites = {
          'suggestions': data['suggestions'] ?? [],
        };
        _loadingVr = false;
      });
    } catch (_) {
      setState(() => _loadingVr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bgLight,
        colorScheme: const ColorScheme.light(
          primary: _blue800,
          secondary: _blue900,
          surface: _cardLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _blue900,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceLight,
          hintStyle: const TextStyle(color: _textHint),
          prefixIconColor: _blue800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _blue800, width: 2),
          ),
        ),
        dividerColor: _borderColor,
      ),
      child: Scaffold(
        backgroundColor: _bgLight,
        appBar: AppBar(
          title: const Text(
            'Explore',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: _yellowDeep,
            labelColor: _yellowMid,
            unselectedLabelColor: Colors.white60,
            isScrollable: true,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '📖 Legends'),
              Tab(text: '⛓️ Causal Chains'),
              Tab(text: '⚠️ Fact Check'),
              Tab(text: '🏛️ VR Sites'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildLegendsTab(),
            _buildCausalTab(),
            _buildAnomalyTab(),
            _buildVrTab(),
          ],
        ),
      ),
    );
  }

  // ── LEGENDS ────────────────────────────────────────────────────────────────

  Widget _buildLegendsTab() {
    if (_loadingLegends) {
      return const Center(
          child: CircularProgressIndicator(color: _blue800));
    }
    if (_allLegends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('No legends loaded',
                style: TextStyle(color: _textHint)),
            TextButton(
              onPressed: _loadLegends,
              style: TextButton.styleFrom(foregroundColor: _blue800),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _allLegends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final key = _allLegends.keys.elementAt(i);
        final legend = _allLegends[key] as Map<String, dynamic>;
        return _legendCard(legend);
      },
    );
  }

  Widget _legendCard(Map<String, dynamic> legend) {
    return Container(
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue800.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _blue900.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: _borderColor),
        child: ExpansionTile(
          leading: const Text('📜', style: TextStyle(fontSize: 28)),
          title: Text(
            legend['title']?.toString() ?? '',
            style: const TextStyle(
                color: _textPrimary, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Keywords: ${(legend['keywords'] as List?)?.take(2).join(', ') ?? ''}',
            style: const TextStyle(color: _textHint, fontSize: 11),
          ),
          iconColor: _blue800,
          collapsedIconColor: _textHint,
          backgroundColor: _yellowLight.withOpacity(0.3),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _expandedSection(
                      '✨ Legend', legend['legend']?.toString() ?? '',
                      _saffron),
                  const SizedBox(height: 12),
                  _expandedSection(
                      '📚 Historical Fact',
                      legend['historical_fact']?.toString() ?? '',
                      _jade),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: _blue800),
                        onPressed: () => _voice.speak(
                          '${legend['legend']} Historical fact: ${legend['historical_fact']}',
                        ),
                        tooltip: 'Listen',
                      ),
                      const Text('Listen',
                          style: TextStyle(
                              color: _blue800, fontSize: 13)),
                    ],
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
        Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        Text(content,
            style: const TextStyle(color: _textSecondary, height: 1.5)),
      ],
    );
  }

  // ── CAUSAL CHAINS ──────────────────────────────────────────────────────────

  Widget _buildCausalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historical Chain of Events',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Understand WHY things happened — step-by-step cause and effect',
            style: TextStyle(color: _textHint, fontSize: 13),
          ),
          const SizedBox(height: 16),

          const Text('Try asking:',
              style: TextStyle(color: _textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          ...[
            'Why did Kandy remain independent?',
            'How did cinnamon trade develop?',
            'Why was the Tooth Relic important for kingship?',
          ].map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    _causalCtrl.text = q;
                    _fetchCausalChain(q);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _yellowLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _yellowDeep.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: _yellowDeep, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(q,
                              style: const TextStyle(color: _textPrimary)),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: _textHint, size: 14),
                      ],
                    ),
                  ),
                ),
              )),

          const SizedBox(height: 16),
          TextField(
            controller: _causalCtrl,
            style: const TextStyle(color: _textPrimary),
            decoration: const InputDecoration(
              hintText: 'Enter your historical question...',
              prefixIcon: Icon(Icons.history_edu),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Get Causal Chain',
            icon: Icons.account_tree,
            isLoading: _loadingCausal,
            onPressed: () => _fetchCausalChain(_causalCtrl.text),
          ),

          if (_causalResult != null) ...[
            const SizedBox(height: 20),
            _buildCausalResult(),
          ],
        ],
      ),
    );
  }

  Future<void> _fetchCausalChain(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loadingCausal = true;
      _causalResult = null;
    });
    try {
      final data = await _api.getCausalChain(query);
      setState(() {
        _causalResult = data;
        _loadingCausal = false;
      });
    } catch (e) {
      setState(() => _loadingCausal = false);
    }
  }

  Widget _buildCausalResult() {
    final found = _causalResult!['chain_found'] == true;
    if (!found) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: const Text(
          'No causal chain found for this query. Try the suggested questions above.',
          style: TextStyle(color: Colors.deepOrange),
        ),
      );
    }

    final chain = _causalResult!['chain'] as Map<String, dynamic>;
    final steps = chain['chain'] as List? ?? [];
    final title = chain['title']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: _blue900,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) {
          final step = e.value as Map<String, dynamic>;
          return _chainStep(e.key + 1, step, e.key == steps.length - 1);
        }),
        const SizedBox(height: 10),
        IconButton(
          icon: const Icon(Icons.volume_up, color: _blue800),
          onPressed: () => _voice.speak(
              _causalResult!['formatted']?.toString() ?? ''),
          tooltip: 'Read aloud',
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
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _blue800,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$num',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: _blue800.withOpacity(0.25),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: _blue900.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${step['event']} (${step['year']})',
                    style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  _causeEffect(
                      '→ Cause', step['cause']?.toString() ?? '',
                      _saffron),
                  const SizedBox(height: 4),
                  _causeEffect(
                      '⬇ Effect', step['effect']?.toString() ?? '',
                      _jade),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _causeEffect(String label, String text, Color color) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: _textSecondary, fontSize: 12)),
          ),
        ],
      );

  // ── ANOMALY / FACT CHECK ───────────────────────────────────────────────────

  Widget _buildAnomalyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historical Fact Checker',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Detects common misconceptions about Sri Lankan history',
            style: TextStyle(color: _textHint, fontSize: 13),
          ),
          const SizedBox(height: 16),

          ...[
            'The Portuguese conquered Kandy',
            'The actual Tooth Relic is carried in the Perahera',
            'Dutch built Galle Fort from scratch',
            'Sri Lanka was always Buddhist',
          ].map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    _anomalyCtrl.text = q;
                    _checkAnomaly(q);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Text('❓',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(q,
                              style: const TextStyle(color: _textPrimary)),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: _textHint, size: 14),
                      ],
                    ),
                  ),
                ),
              )),

          const SizedBox(height: 8),
          TextField(
            controller: _anomalyCtrl,
            style: const TextStyle(color: _textPrimary),
            decoration: const InputDecoration(
              hintText: 'Enter a historical statement...',
              prefixIcon: Icon(Icons.fact_check_outlined),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Check Facts',
            icon: Icons.search,
            isLoading: _loadingAnomaly,
            onPressed: () => _checkAnomaly(_anomalyCtrl.text),
          ),

          if (_anomalyResult != null) ...[
            const SizedBox(height: 20),
            _buildAnomalyResult(),
          ],
        ],
      ),
    );
  }

  Future<void> _checkAnomaly(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loadingAnomaly = true;
      _anomalyResult = null;
    });
    try {
      final data = await _api.checkAnomaly(query);
      setState(() {
        _anomalyResult = data;
        _loadingAnomaly = false;
      });
    } catch (e) {
      setState(() => _loadingAnomaly = false);
    }
  }

  Widget _buildAnomalyResult() {
    final detected = _anomalyResult!['misconception_detected'] == true;
    final result = _anomalyResult!['result'] as Map<String, dynamic>?;
    final correction = result?['correction']?.toString() ?? '';
    final severity = result?['severity']?.toString() ?? '';

    Color color = detected ? Colors.orange : Colors.green;
    String icon = detected ? '⚠️' : '✅';
    String title = detected
        ? 'Misconception Detected! (Severity: $severity)'
        : 'No Misconceptions Found';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (correction.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              correction,
              style: const TextStyle(color: _textSecondary, height: 1.5),
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.volume_up, color: _blue800),
              onPressed: () => _voice.speak(correction),
            ),
          ],
        ],
      ),
    );
  }

  // ── VR SITES ───────────────────────────────────────────────────────────────

  Widget _buildVrTab() {
    final sites =
        (_vrSites['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('VR Historical Sites',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Immersive virtual reality experiences at historical locations',
                style: TextStyle(color: _textHint, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingVr
              ? const Center(
                  child: CircularProgressIndicator(color: _blue800))
              : sites.isEmpty
                  ? const Center(
                      child: Text('No sites available',
                          style: TextStyle(color: _textHint)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      itemCount: sites.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _vrSiteCard(sites[i]),
                    ),
        ),
      ],
    );
  }

  Widget _vrSiteCard(Map<String, dynamic> site) {
    // Remapped type colours to light-mode equivalents
    final typeColors = {
      'sacred_site':   const Color(0xFFB71C1C), // deep red
      'colonial_site': _blue900,
      'cultural_site': const Color(0xFF00695C), // jade
      'royal_site':    const Color(0xFF6A0080), // purple
      'trade_site':    const Color(0xFF803600), // brown
      'ancient_site':  const Color(0xFF004040), // dark teal
    };
    final color = typeColors[site['type']] ?? _blue800;

    return Container(
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site['name']?.toString() ?? '',
                        style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        (site['type']?.toString() ?? '')
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site['description']?.toString() ?? '',
                  style: const TextStyle(color: _textSecondary, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _yellowLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _yellowDeep.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Text('🥽 VR: ',
                          style: TextStyle(
                              color: _saffron,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                      Expanded(
                        child: Text(
                          site['vr_experience']?.toString() ?? '',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 ${site['discovery_trigger']}',
                  style: const TextStyle(color: _textHint, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}