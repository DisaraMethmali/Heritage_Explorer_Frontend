// frontend/lib/screens/recommendation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/recommendation_state.dart';
import '../services/location_monitor.dart';
import '../state/user_location_state.dart';
import 'map_route_screen.dart';
import 'area_search_result_screen.dart';
import 'site_search_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with TickerProviderStateMixin {
  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late AnimationController _contentController;
  late Animation<double> _shimmer;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _contentController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    await LocationMonitor.checkOnce();
    setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    final hasData = RecommendationState.hasRecommendation;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _contentFade,
        child: SlideTransition(
          position: _contentSlide,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFFFFD700),
              backgroundColor: const Color(0xFF002D72),
              child: hasData
                  ? _buildRecommendationContent()
                  : _buildEmptyState(),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF001233),
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
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 16, color: Color(0xFFFFD700)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'RECOMMENDED FOR YOU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'Heritage Sites',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _AppBarIconBtn(
          icon: Icons.location_on_outlined,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AreaSearchResultScreen())),
        ),
        _AppBarIconBtn(
          icon: Icons.account_balance_outlined,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SiteSearchScreen())),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Medallion
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.15),
                                width: 1),
                          ),
                        ),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.35),
                                width: 1.5),
                          ),
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF0A4FA3), Color(0xFF001845)],
                              center: Alignment(-0.3, -0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.travel_explore,
                              size: 34, color: Color(0xFFFFD700)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Gold pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.4),
                            width: 1),
                      ),
                      child: const Text(
                        'NO RECOMMENDATIONS YET',
                        style: TextStyle(
                          color: Color(0xFFB8860B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Nothing to show yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF002D72),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Pull to refresh or move closer to a heritage site to discover ancient events around you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF90A4C4),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Safety Badge ───────────────────────────────────────────────────────────
  Widget _buildSafetyBadge(String status) {
    Color bg, fg;
    IconData icon;
    switch (status) {
      case "SAFE":
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.shield_outlined;
        break;
      case "CAUTION":
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        icon = Icons.warning_amber_outlined;
        break;
      case "UNSAFE":
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.dangerous_outlined;
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
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

  // ── Main Content ───────────────────────────────────────────────────────────
  Widget _buildRecommendationContent() {
    final sites = RecommendationState.recommendedSites;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Recommendation message banner ────────────────────────────
          if (RecommendationState.recommendationMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF002D72).withValues(alpha: 0.15),
                    width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF002D72).withValues(alpha: 0.08),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Color(0xFF002D72), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      RecommendationState.recommendationMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF223355),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Section label ────────────────────────────────────────────
          _SectionLabel(label: 'TOP HERITAGE SITES'),
          const SizedBox(height: 14),

          // ── Site cards ───────────────────────────────────────────────
          ...sites.map((site) {
            final List<Map<String, dynamic>> events =
                List<Map<String, dynamic>>.from(site["events"] ?? []);
            final bool isHighlighted =
                site["site_id"] == RecommendationState.highlightSiteId;

            return _SiteCard(
              site: site,
              events: events,
              isHighlighted: isHighlighted,
              safetyBadgeBuilder: _buildSafetyBadge,
              onRoute: () => _navigateToRoute(context, site),
            );
          }),

          // ── Alternative site ─────────────────────────────────────────
          if (RecommendationState.alternativeSite != null) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Color(0xFF2E7D32),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: const Text(
                      'SAFER ALTERNATIVE',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFF2E7D32),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildAlternativeFullCard(RecommendationState.alternativeSite!),
          ],
        ],
      ),
    );
  }

  void _navigateToRoute(BuildContext context, Map<String, dynamic> site) {
    if (UserLocationState.userLat == null || UserLocationState.userLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User location not available.")),
      );
      return;
    }
    Navigator.push(
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
    );
  }

  // ── Alternative full card ──────────────────────────────────────────────────
  Widget _buildAlternativeFullCard(Map<String, dynamic> site) {
    final List<Map<String, dynamic>> events =
        List<Map<String, dynamic>>.from(site["events"] ?? []);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green top bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site name
                Text(
                  site["site_name"],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF002D72),
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    if (site["safety_status"] != null)
                      _buildSafetyBadge(site["safety_status"]),
                    const SizedBox(width: 10),
                    if (site["road_distance_km"] != null)
                      Text(
                        "${site["road_distance_km"]} km away",
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF90A4C4)),
                      ),
                  ],
                ),

                // Weather
                if (site["weather"] != null) ...[
                  const SizedBox(height: 14),
                  _WeatherRow(weather: site["weather"]),
                ],

                // Disaster
                if (site["disaster"] != null) ...[
                  const SizedBox(height: 10),
                  _DisasterRow(disaster: site["disaster"]),
                ],

                const SizedBox(height: 18),
                _SectionLabel(label: 'ANCIENT EVENTS'),
                const SizedBox(height: 12),

                if (events.isEmpty)
                  const Text("No recorded events.",
                      style: TextStyle(color: Color(0xFF90A4C4)))
                else
                  Column(
                    children: events
                        .map((e) => _EventTile(event: e, accentColor: const Color(0xFF002D72)))
                        .toList(),
                  ),

                const SizedBox(height: 16),

                // View Route button
                _RouteButton(
                  label: 'View Route',
                  color: const Color(0xFF002D72),
                  onTap: () => _navigateToRoute(context, site),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Site Card ─────────────────────────────────────────────────────────────────

class _SiteCard extends StatelessWidget {
  final Map<String, dynamic> site;
  final List<Map<String, dynamic>> events;
  final bool isHighlighted;
  final Widget Function(String) safetyBadgeBuilder;
  final VoidCallback onRoute;

  const _SiteCard({
    required this.site,
    required this.events,
    required this.isHighlighted,
    required this.safetyBadgeBuilder,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isHighlighted
            ? Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002D72).withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: isHighlighted
                    ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                    : [const Color(0xFF002D72), const Color(0xFF0077B6)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site name + highlighted badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        site["site_name"],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF002D72),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                              width: 1),
                        ),
                        child: const Text(
                          'BEST',
                          style: TextStyle(
                            color: Color(0xFFB8860B),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Safety + distance row
                Row(
                  children: [
                    if (site["safety_status"] != null)
                      safetyBadgeBuilder(site["safety_status"]),
                    const SizedBox(width: 10),
                    if (site["road_distance_km"] != null)
                      Text(
                        "${site["road_distance_km"]} km away",
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF90A4C4)),
                      ),
                  ],
                ),

                // Weather
                if (site["weather"] != null) ...[
                  const SizedBox(height: 12),
                  _WeatherRow(weather: site["weather"]),
                ],

                // Disaster
                if (site["disaster"] != null) ...[
                  const SizedBox(height: 10),
                  _DisasterRow(disaster: site["disaster"]),
                ],

                const SizedBox(height: 14),

                // Static description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "A historically significant landmark rich in cultural and architectural heritage.",
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF445577),
                        height: 1.5),
                  ),
                ),

                const SizedBox(height: 20),

                _SectionLabel(label: 'ANCIENT EVENTS'),
                const SizedBox(height: 12),

                if (events.isEmpty)
                  const Text("No recorded events for this site.",
                      style: TextStyle(color: Color(0xFF90A4C4)))
                else
                  Column(
                    children: events
                        .map((e) => _EventTile(
                            event: e, accentColor: const Color(0xFF002D72)))
                        .toList(),
                  ),

                const SizedBox(height: 20),

                _RouteButton(
                  label: 'View Route',
                  color: const Color(0xFF002D72),
                  onTap: onRoute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
              color: Color(0xFF002D72),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            )),
      ],
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8, top: 10, bottom: 10),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.45), width: 1),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700), size: 17),
      ),
    );
  }
}

class _WeatherRow extends StatelessWidget {
  final Map<String, dynamic> weather;
  const _WeatherRow({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (weather["icon"] != null)
            Image.network("https:${weather["icon"]}", width: 36, height: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather["condition"] ?? "",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF223355)),
                ),
                const SizedBox(height: 2),
                Text(
                  "${weather["temperature_c"] ?? "--"}°C  ·  "
                  "Humidity ${weather["humidity"] ?? "--"}%  ·  "
                  "Wind ${weather["wind_kph"] ?? "--"} km/h",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF90A4C4)),
                ),
              ],
            ),
          ),
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
    final isHigh = disaster["risk_level"] == "High";
    final Color color = hasAlert
        ? (isHigh ? const Color(0xFFC62828) : const Color(0xFFE65100))
        : const Color(0xFF2E7D32);
    final Color bg = hasAlert
        ? (isHigh ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1))
        : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            hasAlert ? Icons.warning_amber_outlined : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hasAlert
                  ? disaster["message"] ?? "Weather Alert"
                  : "No active disaster alerts",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final Color accentColor;
  const _EventTile({required this.event, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF002D72).withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history_edu, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event["event_name"] ?? "Untitled Event",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    if (event["year"] != null)
                      Text(
                        event["year"].toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF90A4C4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event["description"] ?? "No description available for this event.",
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF445577),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _RouteButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.directions_outlined,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}