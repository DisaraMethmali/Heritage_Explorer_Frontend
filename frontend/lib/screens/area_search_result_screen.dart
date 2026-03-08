// frontend/lib/screens/area_search_result_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../state/user_location_state.dart';
import '../utils/config.dart';
import 'map_route_screen.dart';

class AreaSearchResultScreen extends StatefulWidget {
  const AreaSearchResultScreen({super.key});

  @override
  State<AreaSearchResultScreen> createState() => _AreaSearchResultScreenState();
}

class _AreaSearchResultScreenState extends State<AreaSearchResultScreen>
    with TickerProviderStateMixin {

  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;
  String? searchedArea;
  List<Map<String, dynamic>> results = [];

  // ── Design tokens (unchanged) ──────────────────────────────────────────────
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _shimmerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _fetchAreaResults(String area) async {
    if (area.isEmpty) return;
    setState(() { isLoading = true; searchedArea = area; });

    final res = await http.post(
      Uri.parse("$baseUrl/search-area"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "area": area,
        "user_lat": UserLocationState.userLat,
        "user_lon": UserLocationState.userLon,
      }),
    );

    if (!mounted) return;
    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      results = List<Map<String, dynamic>>.from(data["results"] ?? []);
    } else if (res.statusCode == 404) {
      results.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Area not found. Please check the spelling and try again."),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Something went wrong. Please try again."),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }

    setState(() => isLoading = false);
  }

  String _shortPlace(String address) {
    List<String> parts = address.split(",");
    if (parts.isEmpty) return address;
    if (parts[0].contains("+")) {
      if (parts.length >= 3) return "${parts[1].trim()}, ${parts[2].trim()}";
      if (parts.length >= 2) return parts[1].trim();
      return address;
    }
    if (parts.length >= 2) return "${parts[0].trim()}, ${parts[1].trim()}";
    return parts[0].trim();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: _pageBg,
      // FIX 1: removed extendBodyBehindAppBar — AppBar is solid navy now,
      //         so body starts cleanly below it with no overlap.
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _contentFade,
        child: SlideTransition(
          position: _contentSlide,
          child: Column(
            children: [
              // FIX 2: Hero is a fixed 110px SizedBox — no longer uses
              //         screenHeight * 0.18 which caused overflow on small screens.
              _buildHero(),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _buildSearchBar(),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : results.isEmpty
                        ? _buildEmptyState()
                        : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar — solid navy (no transparency + no extendBodyBehindAppBar) ───────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _navy,   // FIX 3: solid, not transparent
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 1.5),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.location_on_outlined, size: 16, color: _gold),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('SEARCH BY AREA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0)),
              Text('Heritage Sites',
                  style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.4)),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_gold, Color(0xFFFFA500), _gold]),
          ),
        ),
      ),
    );
  }

  // ── Hero — fixed 110px, uses SizedBox so height is predictable ────────────

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return SizedBox(
          height: 110,   // FIX 4: fixed px instead of screenHeight fraction
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
                  child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: CustomPaint(
                  size: const Size(double.infinity, 28),
                  painter: _WavePainter(),
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
            top: BorderSide(color: _gold.withValues(alpha: 0.6), width: 2)),
        boxShadow: [
          BoxShadow(
              color: _navy.withValues(alpha: 0.09),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: _textSub, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: _navyMid,
                  selectionHandleColor: _navyMid,
                  selectionColor: Color(0xFFB3D1FF),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                    color: _textMain, fontSize: 13, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: "Search area (Eg: Matara, Galle...)",
                  hintStyle: TextStyle(color: _textSub, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (v) => _fetchAreaResults(v.trim()),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _fetchAreaResults(_searchController.text.trim()),
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [_navyMid, _blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 15),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _searchController.clear();
              results.clear();
              searchedArea = null;
            }),
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _textSub.withValues(alpha: 0.12)),
              child: const Icon(Icons.close, color: _textSub, size: 14),
            ),
          ),
        ],
      ),
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
                  BoxShadow(color: _gold.withValues(alpha: 0.2), blurRadius: 16)
                ],
              ),
              child: const Icon(Icons.travel_explore, color: _gold, size: 28),
            ),
          ]),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: _gold, strokeWidth: 2),
          const SizedBox(height: 16),
          const Text('Searching heritage sites...',
              style: TextStyle(color: _textSub, fontSize: 13, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      child: const Icon(Icons.travel_explore, size: 32, color: _gold),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1),
                    ),
                    child: const Text('READY TO EXPLORE',
                        style: TextStyle(
                            color: Color(0xFFB8860B),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Search for a Heritage Area',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textMain,
                          letterSpacing: -0.2),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter an area name above to explore nearby heritage sites with events, weather updates, safety status, and route information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: _textSub, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Results list ───────────────────────────────────────────────────────────

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: results.length,
      itemBuilder: (_, index) {
        final site   = results[index];
        final events = List<Map<String, dynamic>>.from(site["events"] ?? []);
        return _SiteResultCard(
          site: site,
          events: events,
          searchedArea: searchedArea,
          shortPlace: _shortPlace,
          onRoute: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapRouteScreen(
                userLat: UserLocationState.userLat!,
                userLon: UserLocationState.userLon!,
                destLat: site["lat"],
                destLon: site["lon"],
                siteName: site["site_name"],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Site result card ──────────────────────────────────────────────────────────

class _SiteResultCard extends StatelessWidget {
  final Map<String, dynamic> site;
  final List<Map<String, dynamic>> events;
  final String? searchedArea;
  final String Function(String) shortPlace;
  final VoidCallback onRoute;

  const _SiteResultCard({
    required this.site,
    required this.events,
    required this.searchedArea,
    required this.shortPlace,
    required this.onRoute,
  });

  Widget _safetyBadge(String status) {
    Color bg, fg;
    IconData icon;
    switch (status) {
      case "SAFE":
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32);
        icon = Icons.shield_outlined; break;
      case "CAUTION":
        bg = const Color(0xFFFFF8E1); fg = const Color(0xFFE65100);
        icon = Icons.warning_amber_outlined; break;
      case "UNSAFE":
        bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828);
        icon = Icons.dangerous_outlined; break;
      default:
        bg = const Color(0xFFF5F5F5); fg = const Color(0xFF616161);
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(top: BorderSide(color: Color(0xFFFFD700), width: 2.5)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF002D72).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              site["site_name"] ?? "",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF002D72),
                  letterSpacing: -0.2),
            ),
            const SizedBox(height: 6),

            if (site["place_name"] != null)
              Row(children: [
                const Icon(Icons.place_outlined, size: 14, color: Color(0xFF90A4C4)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(shortPlace(site["place_name"]),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF90A4C4))),
                ),
              ]),

            const SizedBox(height: 10),

            // FIX 6: crossAxisAlignment.start so badge doesn't stretch
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (site["safety_status"] != null)
                  _safetyBadge(site["safety_status"]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (searchedArea != null)
                        Text(
                          "From $searchedArea: ${site["distance_from_area_km"]} km",
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF90A4C4)),
                        ),
                      Text(
                        "From you: ${site["distance_from_user_km"]} km",
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF90A4C4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (site["weather"] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  if (site["weather"]["icon"] != null)
                    Image.network("https:${site["weather"]["icon"]}",
                        width: 36, height: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site["weather"]["condition"] ?? "",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF223355))),
                        const SizedBox(height: 2),
                        Text(
                          "${site["weather"]["temperature_c"] ?? "--"}°C  ·  "
                          "Humidity ${site["weather"]["humidity"] ?? "--"}%  ·  "
                          "Wind ${site["weather"]["wind_kph"] ?? "--"} km/h",
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF90A4C4)),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],

            if (site["disaster"] != null) ...[
              const SizedBox(height: 10),
              _DisasterRow(disaster: site["disaster"]),
            ],

            if (events.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: 'ANCIENT EVENTS'),
              const SizedBox(height: 10),
              ...events.map((e) => _EventTile(event: e)),
            ],

            const SizedBox(height: 16),

            GestureDetector(
              onTap: onRoute,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF001845), Color(0xFF023E8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF002D72).withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12)),
                      child: const Icon(Icons.directions_outlined,
                          color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 10),
                    const Text('View Route',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF002D72).withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: const Color(0xFF002D72).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.history_edu,
                  color: Color(0xFF002D72), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event["year"] != null
                    ? "${event["event_name"]} (${event["year"]})"
                    : event["event_name"] ?? "Untitled Event",
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF002D72)),
              ),
            ),
          ]),
          if ((event["description"] ?? "").isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(event["description"] ?? "",
                textAlign: TextAlign.justify,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.5, color: Color(0xFF445577))),
          ],
        ],
      ),
    );
  }
}

class _DisasterRow extends StatelessWidget {
  final Map<String, dynamic> disaster;
  const _DisasterRow({required this.disaster});

  @override
  Widget build(BuildContext context) {
    final hasAlert = disaster["has_alert"] == true;
    final isHigh   = disaster["risk_level"] == "High";
    final Color color = hasAlert
        ? (isHigh ? const Color(0xFFC62828) : const Color(0xFFE65100))
        : const Color(0xFF2E7D32);
    final Color bg = hasAlert
        ? (isHigh ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1))
        : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(
          hasAlert ? Icons.warning_amber_outlined : Icons.check_circle_outline,
          size: 17, color: color,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            hasAlert
                ? disaster["message"] ?? "Weather Alert"
                : "No active disaster alerts",
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ]),
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
    canvas.drawCircle(Offset(-20, size.height * 1.5), size.width * 0.5, p);
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.03);
    p.strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      canvas.drawLine(
          Offset(size.width * i / 6, 0), Offset(size.width * i / 6 + 40, size.height), p);
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