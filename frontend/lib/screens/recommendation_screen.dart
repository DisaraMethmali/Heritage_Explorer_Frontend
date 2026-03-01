// frontend/lib/screens/recommendation_screen.dart

import 'package:flutter/material.dart';
import '../state/recommendation_state.dart';
import '../services/location_monitor.dart';
import '../state/user_location_state.dart';
import 'map_route_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {

  // Pull-to-refresh handler
  Future<void> _onRefresh() async {
    await LocationMonitor.checkOnce();
    setState(() {}); // rebuild UI with updated recommendation
  }

  @override
  Widget build(BuildContext context) {
    final hasData = RecommendationState.hasRecommendation;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),

      appBar: AppBar(
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        title: const Text(
          "Recommended for You",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: hasData
              ? _buildRecommendationContent()
              : _buildEmptyState(),
        ),
      ),
    );
  }

  // EMPTY STATE (No recommendation)
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.travel_explore,
                      size: 80,
                      color: Color(0xFF004C7A),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No recommendations yet",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004C7A),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Pull to refresh or move closer to a heritage site to discover ancient events around you.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
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

  // SAFETY BADGE
  Widget _buildSafetyBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case "SAFE":
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case "CAUTION":
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case "UNSAFE":
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // MAIN CONTENT (TOP 3 SITES)
  Widget _buildRecommendationContent() {
    final sites = RecommendationState.recommendedSites;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          // Recommendation Message Banner
          if (RecommendationState.recommendationMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        RecommendationState.recommendationMessage!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

          // TOP 3 CARDS
          ...sites.map((site) {
            final List<Map<String, dynamic>> events =
                List<Map<String, dynamic>>.from(site["events"] ?? []);

            final bool isHighlighted =
                site["site_id"] == RecommendationState.highlightSiteId;

            return Card(
              elevation: 8,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              // Highlight Background
              color: isHighlighted
                  ? const Color(0xFFE8F5E9)
                  : Colors.white,

              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // SITE NAME 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site["site_name"],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004C7A),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Safety Badge
                        if (site["safety_status"] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _buildSafetyBadge(site["safety_status"]),
                          ),

                        // DISTANCE
                        if (site["road_distance_km"] != null)
                          Text(
                            "Distance: ${site["road_distance_km"]} km",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),

                        // WEATHER SECTION
                        if (site["weather"] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [

                                if (site["weather"]["icon"] != null)
                                  Image.network(
                                    "https:${site["weather"]["icon"]}",
                                    width: 40,
                                    height: 40,
                                  ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${site["weather"]["condition"]}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "${site["weather"]["temperature_c"] ?? "--"}°C • "
                                        "Humidity ${site["weather"]["humidity"] ?? "--"}% • "
                                        "Wind ${site["weather"]["wind_kph"] ?? "--"} km/h",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // DISASTER STATUS SECTION
                        if (site["disaster"] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  site["disaster"]["has_alert"] == true
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  color: site["disaster"]["has_alert"] == true
                                      ? (site["disaster"]["risk_level"] == "High"
                                          ? Colors.red
                                          : Colors.orange)
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    site["disaster"]["has_alert"] == true
                                        ? (site["disaster"]["message"] ?? "Weather Alert")
                                        : "No active disaster alerts",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: site["disaster"]["has_alert"] == true
                                          ? (site["disaster"]["risk_level"] == "High"
                                              ? Colors.red.shade800
                                              : Colors.orange.shade800)
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // STATIC DESCRIPTION
                    const Text(
                      "A historically significant landmark rich in cultural and architectural heritage.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // EVENTS HEADER
                    const Text(
                      "Ancient Events",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8860B),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // EVENTS LIST
                    if (events.isEmpty)
                      const Text(
                        "No recorded events for this site.",
                        style: TextStyle(color: Colors.black54),
                      )
                    else
                      Column(
                        children: events.map((e) {
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // EVENT TITLE
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.history_edu,
                                        color: Color(0xFF004C7A),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          e["event_name"] ?? "Untitled Event",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF004C7A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (e["year"] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        e["year"].toString(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 8),

                                  // EVENT DESCRIPTION
                                  Text(
                                    e["description"] ??
                                        "No description available for this event.",
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // ROUTE BUTTON AT BOTTOM CENTER
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004C7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.directions, size: 20),
                        label: const Text(
                          "View Route",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (UserLocationState.userLat == null ||
                              UserLocationState.userLon == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("User location not available."),
                              ),
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
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Alternative Suggestion (Full Alternative Card)
          if (RecommendationState.alternativeSite != null) ...[

            const SizedBox(height: 30),

            const Divider(thickness: 1.2),

            const SizedBox(height: 12),

            const Text(
              "Safer Alternative Recommendation",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),

            const SizedBox(height: 16),

            _buildAlternativeFullCard(
              RecommendationState.alternativeSite!,
            ),
          ],
        ]
      ),
    );
  }

  Widget _buildAlternativeFullCard(Map<String, dynamic> site) {
    final List<Map<String, dynamic>> events =
        List<Map<String, dynamic>>.from(site["events"] ?? []);

    return Card(
      elevation: 10,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.green.shade700,
          width: 2,
        ),
      ),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title
            Text(
              site["site_name"],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0000FF),
              ),
            ),

            const SizedBox(height: 6),

            // Safety Badge
            if (site["safety_status"] != null)
              _buildSafetyBadge(site["safety_status"]),

            const SizedBox(height: 8),

            // Distance
            Text(
              "Distance: ${site["road_distance_km"]} km",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 10),

            // Weather
            if (site["weather"] != null)
              Row(
                children: [
                  if (site["weather"]["icon"] != null)
                    Image.network(
                      "https:${site["weather"]["icon"]}",
                      width: 40,
                      height: 40,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${site["weather"]["condition"]} • "
                      "${site["weather"]["temperature_c"] ?? "--"}°C • "
                      "Humidity ${site["weather"]["humidity"] ?? "--"}% • "
                      "Wind ${site["weather"]["wind_kph"] ?? "--"} km/h",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Disaster
            if (site["disaster"] != null)
              Text(
                site["disaster"]["has_alert"] == true
                    ? site["disaster"]["message"] ?? "Weather Alert"
                    : "No active disaster alerts",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: site["disaster"]["has_alert"] == true
                      ? (site["disaster"]["risk_level"] == "High"
                          ? Colors.red
                          : Colors.orange)
                      : Colors.green,
                ),
              ),

            const SizedBox(height: 16),

            const Text(
              "Ancient Events",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8860B),
              ),
            ),

            const SizedBox(height: 8),

            if (events.isEmpty)
              const Text(
                "No recorded events.",
                style: TextStyle(color: Colors.black54),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: events.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Event Name + Year
                        Text(
                          e["year"] != null
                              ? "${e["event_name"]} (${e["year"]})"
                              : e["event_name"] ?? "Untitled Event",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Description
                        Text(
                          e["description"] ?? "",
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // View Route Button
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0000FF),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.directions),
                label: const Text("View Route"),
                onPressed: () {
                  if (UserLocationState.userLat == null ||
                      UserLocationState.userLon == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("User location not available."),
                      ),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
