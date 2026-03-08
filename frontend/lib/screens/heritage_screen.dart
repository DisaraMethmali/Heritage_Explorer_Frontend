// frontend/lib/screens/heritage_screen.dart (Heritage site details page + year/era filter)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart';
import '../state/geo_state.dart';
import 'vr_screen.dart';
import '../state/session_state.dart';
// import 'session_report_screen.dart';

class HeritageScreen extends StatefulWidget {
  final String siteName;
  final int siteId; // required to fetch filters from backend
  final List<Map<String, dynamic>> events;

  const HeritageScreen({
    super.key,
    required this.siteName,
    required this.siteId,
    required this.events,
  });

  @override
  State<HeritageScreen> createState() => _HeritageScreenState();
}

class _HeritageScreenState extends State<HeritageScreen>
    with TickerProviderStateMixin {

  late List<Map<String, dynamic>> displayedEvents;
  bool isLoading = false;
  String selectedRange = "All Eras";
  bool isExpanded = false; // controls open/close of dropdown

  // Experience mode states
  bool geoSyncEnabled = false;
  bool demoModeEnabled = true;

  // ── Design tokens (from profile_screen) ───────────────────────────────────
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

  // Year/Era dropdown options
  final List<Map<String, dynamic>> yearRanges = [
    {"label": "All Eras", "min": -9999, "max": 9999},
    {"label": "Before 0 AD", "min": -9999, "max": -1},
    {"label": "1–500 AD", "min": 1, "max": 500},
    {"label": "501–1500 AD", "min": 501, "max": 1500},
    {"label": "After 1500 AD", "min": 1501, "max": 9999},
  ];

  @override
  void initState() {
    super.initState();
    displayedEvents = widget.events;

    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    // SESSION LOGGING — site visit
    SessionState.visitedSites.add({
      "site_id": widget.siteId,
      "site_name": widget.siteName,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // SHARED POPUP (logic unchanged)
  void _showUnifiedPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final bool canStartExperience =
                demoModeEnabled ||
                (geoSyncEnabled && GeoState.isUserNearSite);

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withValues(alpha: 0.12),
                      border: Border.all(color: _gold.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.settings_outlined, color: _goldDeep, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Experience Settings",
                    style: TextStyle(
                      color: _textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GeoSync toggle
                  Container(
                    decoration: BoxDecoration(
                      color: _inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _textSub.withValues(alpha: 0.2)),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        "GeoSync",
                        style: TextStyle(color: _textMain, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        "Require physical presence at site",
                        style: TextStyle(color: _textSub, fontSize: 12),
                      ),
                      value: geoSyncEnabled,
                      activeColor: _navyMid,
                      onChanged: (val) => setPopupState(() => geoSyncEnabled = val),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Demo Mode toggle
                  Container(
                    decoration: BoxDecoration(
                      color: _inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _textSub.withValues(alpha: 0.2)),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        "Demo Mode",
                        style: TextStyle(color: _textMain, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        "Allow experience anywhere",
                        style: TextStyle(color: _textSub, fontSize: 12),
                      ),
                      value: demoModeEnabled,
                      activeColor: _navyMid,
                      onChanged: (val) => setPopupState(() => demoModeEnabled = val),
                    ),
                  ),

                  if (geoSyncEnabled && !demoModeEnabled && !GeoState.isUserNearSite)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.location_off_outlined, color: Color(0xFFC62828), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "You are not near the heritage site.",
                                style: TextStyle(color: Color(0xFFC62828), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Start Experience button
                  GestureDetector(
                    onTap: canStartExperience
                        ? () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VRScreen(
                                  geoSyncEnabled: geoSyncEnabled,
                                  demoModeEnabled: demoModeEnabled,
                                  siteName: widget.siteName,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: canStartExperience
                            ? const LinearGradient(
                                colors: [_goldDeep, _gold, Color(0xFFFFC200)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)
                            : null,
                        color: canStartExperience ? null : _textSub.withValues(alpha: 0.15),
                        boxShadow: canStartExperience
                            ? [BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.play_circle_outline,
                            color: canStartExperience ? _navy : _textSub, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Start Experience",
                          style: TextStyle(
                            color: canStartExperience ? _navy : _textSub,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Function to call backend /events/filter (logic unchanged)
  Future<void> _filterEvents(int minYear, int maxYear) async {
    setState(() => isLoading = true);

    // SESSION LOGGING — year range selection
    final selectedLabel = yearRanges
        .firstWhere((r) => r["min"] == minYear && r["max"] == maxYear)["label"];

    SessionState.yearSelections.add({
      "site_id": widget.siteId,
      "range": selectedLabel,
      "timestamp": DateTime.now().toIso8601String(),
    });

    const backendUrl = "$baseUrl/events/filter";

    try {
      final res = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "site_id": widget.siteId,
          "year_min": minYear,
          "year_max": maxYear,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == "success") {
          setState(() {
            displayedEvents =
                List<Map<String, dynamic>>.from(data["filtered_events"]);
          });
        }
      }
    } catch (e) {
      debugPrint("Error filtering events: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Styled filter dropdown
  Widget _buildFilterDropdown() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpanded ? _navyMid : _textSub.withValues(alpha: 0.2),
                width: isExpanded ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _navyMid.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.filter_list_rounded, color: _goldDeep, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedRange,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down, color: _navyMid, size: 22),
                ),
              ],
            ),
          ),
        ),

        // Expanded dropdown list
        if (isExpanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _textSub.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: _navyMid.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: yearRanges.map((range) {
                final label = range["label"] as String;
                final isSelected = selectedRange == label;
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedRange = label;
                      isExpanded = false;
                    });
                    _filterEvents(range["min"], range["max"]);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? _navyMid.withValues(alpha: 0.07) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border(left: BorderSide(color: _navyMid, width: 3))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? _navyMid : _textMain,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _navyMid),
                            child: const Icon(Icons.check, color: Colors.white, size: 13),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Hero header (matches profile_screen hero style) ────────────────────────
  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) => SizedBox(
        height: 220,
        child: Stack(children: [
          // Site image
          Positioned.fill(
            child: ClipRRect(
              child: Image.asset(
                "assets/images/${widget.siteName.toLowerCase().replaceAll(' ', '_')}.jpg",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_navy, _blue, _blueMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.account_balance, size: 60, color: _gold),
                  ),
                ),
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, _navy.withValues(alpha: 0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Shimmer overlay
          Positioned.fill(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
          // Wave at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(size: const Size(double.infinity, 30), painter: _WavePainter()),
          ),
          // Text content
          Positioned(
            left: 20, right: 20, bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.siteName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    "Sri Lanka Cultural Heritage",
                    style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
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
            child: const Icon(Icons.account_balance_outlined, size: 16, color: _gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.siteName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Text(
                  'Heritage Site',
                  style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ]),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.description_outlined),
        //     tooltip: "Session Report",
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (_) => const SessionReportScreen(),
        //         ),
        //       );
        //     },
        //   ),
        // ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_gold, Color(0xFFFFA500), _gold]),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero image / header ──────────────────────────────────────
              _buildHero(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Site description card ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: const Border(top: BorderSide(color: _gold, width: 2.5)),
                        boxShadow: [
                          BoxShadow(
                            color: _navyMid.withValues(alpha: 0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _navyMid.withValues(alpha: 0.08),
                            border: Border.all(color: _navyMid.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.info_outline, color: _navyMid, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "A treasured landmark of Sri Lanka's cultural and spiritual heritage.",
                            style: TextStyle(fontSize: 14, color: _textSub, height: 1.5),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // ── View Present-Day Site button ───────────────────────
                    GestureDetector(
                      onTap: _showUnifiedPopup,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [_navy, _navyMid, _blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _navyMid.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: const Icon(Icons.visibility_outlined, color: _gold, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "View Present-Day Site",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Ancient Events header ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: const Border(top: BorderSide(color: _gold, width: 2.5)),
                        boxShadow: [
                          BoxShadow(
                            color: _navyMid.withValues(alpha: 0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _gold.withValues(alpha: 0.12),
                                border: Border.all(color: _gold.withValues(alpha: 0.4)),
                              ),
                              child: const Icon(Icons.history_edu_rounded, color: _goldDeep, size: 17),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ancient Events',
                                  style: TextStyle(
                                    color: _textMain,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Filter by historical era',
                                  style: TextStyle(color: _textSub, fontSize: 11),
                                ),
                              ],
                            ),
                          ]),

                          const SizedBox(height: 14),

                          // Filter dropdown
                          _buildFilterDropdown(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Event list ─────────────────────────────────────────
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _goldDeep,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (displayedEvents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _textSub.withValues(alpha: 0.15)),
                        ),
                        child: Column(children: [
                          Icon(Icons.search_off_rounded, size: 40, color: _textSub.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          const Text(
                            "No ancient events found for this era.",
                            style: TextStyle(fontSize: 14, color: _textSub),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      )
                    else
                      Column(
                        children: displayedEvents.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                // SESSION LOGGING — event click
                                SessionState.selectedEvents.add({
                                  "event_name": e["event_name"],
                                  "year": e["year"],
                                  "site_name": widget.siteName,
                                  "timestamp": DateTime.now().toIso8601String(),
                                });

                                // EXISTING BEHAVIOR
                                _showUnifiedPopup();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: const Border(
                                    left: BorderSide(color: _gold, width: 3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _navyMid.withValues(alpha: 0.07),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _navyMid.withValues(alpha: 0.08),
                                          border: Border.all(color: _navyMid.withValues(alpha: 0.2)),
                                        ),
                                        child: const Icon(
                                          Icons.history_edu_rounded,
                                          color: _navyMid,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e["event_name"] ?? "Untitled Event",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: _textMain,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: _textSub, size: 18),
                                    ]),
                                    if (e["year"] != null && e["year"].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _gold.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: _gold.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            e["year"].toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _goldDeep,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      e["description"] ?? "No description available.",
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _textSub,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painters (from profile_screen) ────────────────────────────────────────────

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