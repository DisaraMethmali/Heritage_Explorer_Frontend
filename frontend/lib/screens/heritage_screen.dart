// frontend/lib/screens/heritage_screen.dart (Heritage site details page + year/era filter)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/unity_service.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart';
import '../state/geo_state.dart';
import 'vr_screen.dart';
import '../state/session_state.dart';
import 'session_report_screen.dart';

class HeritageScreen extends StatefulWidget {
  final String siteName;
  final int siteId; // required to fetch filters from backend
  final List<Map<String, dynamic>> events;
  final double? currentLat; // Add this
  final double? currentLon; // Add this

  const HeritageScreen({
    super.key,
    required this.siteName,
    required this.siteId,
    required this.events,
    this.currentLat, // Add this
    this.currentLon, // Add this
  });

  @override
  State<HeritageScreen> createState() => _HeritageScreenState();
}

class _HeritageScreenState extends State<HeritageScreen> {
  late List<Map<String, dynamic>> displayedEvents;
  bool isLoading = false;
  String selectedRange = "All Eras";
  bool isExpanded = false; // controls open/close of dropdown

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  // Experience mode states
  bool geoSyncEnabled = false;
  bool demoModeEnabled = true;

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

    // SESSION LOGGING — site visit
    SessionState.visitedSites.add({
      "site_id": widget.siteId,
      "site_name": widget.siteName,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  // SHARED POPUP
  // SHARED POPUP
  void _showUnifiedPopup() {
    bool isSyncing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final bool hasAtLeastOneToggle = geoSyncEnabled || demoModeEnabled;

            final bool canStartExperience = hasAtLeastOneToggle;

            final bool isBothTogglesOn = geoSyncEnabled && demoModeEnabled;

            return AlertDialog(
              title: const Text("Experience Settings"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text("GeoSync"),
                      subtitle: const Text("Require physical presence"),
                      value: geoSyncEnabled,
                      onChanged: (val) =>
                          setPopupState(() => geoSyncEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Demo Mode"),
                      subtitle: const Text("Allow experience anywhere"),
                      value: demoModeEnabled,
                      onChanged: (val) =>
                          setPopupState(() => demoModeEnabled = val),
                    ),

                    if (isBothTogglesOn) ...[
                      const Divider(),
                      const Text(
                        "Manual GPS Offset (Optional)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: "Fake Latitude",
                          hintText: "e.g. 7.29",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: _lonController,
                        decoration: const InputDecoration(
                          labelText: "Fake Longitude",
                          hintText: "e.g. 80.64",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],

                    // Validation Message: Shown if both are off
                    if (!hasAtLeastOneToggle)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "Please enable at least one mode to start.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    if (geoSyncEnabled &&
                        !demoModeEnabled &&
                        !GeoState.isUserNearSite)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "You are not near the heritage site.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (isSyncing)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF004C7A)),
                          SizedBox(height: 10),
                          Text(
                            "Configuring VR Environment...",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          // The button is now disabled (null) if no toggles are selected
                          onPressed: canStartExperience
                              ? () async {
                                  setPopupState(() => isSyncing = true);

                                  try {
                                    String targetLoc =
                                        widget.siteName.contains("Galle")
                                        ? "Galle"
                                        : "TempleOfTooth";
                                    String targetEra =
                                        selectedRange == "All Eras"
                                        ? "Modern"
                                        : "Historical";

                                    double? latToSend;
                                    double? lonToSend;

                                    if (geoSyncEnabled && !demoModeEnabled) {
                                      latToSend = widget.currentLat;
                                      lonToSend = widget.currentLon;
                                    } else if (geoSyncEnabled &&
                                        demoModeEnabled) {
                                      latToSend = double.tryParse(
                                        _latController.text,
                                      );
                                      lonToSend = double.tryParse(
                                        _lonController.text,
                                      );
                                    }

                                    String? currentUnityLocation;
                                    try {
                                      final statusRes = await http
                                          .post(
                                            Uri.parse(UnityService.unityUrl),
                                          )
                                          .timeout(const Duration(seconds: 2));
                                      if (statusRes.statusCode == 200) {
                                        currentUnityLocation = jsonDecode(
                                          statusRes.body,
                                        )['currentLoc'];
                                      }
                                    } catch (_) {}

                                    await UnityService.post({
                                      "type": "SWITCH_LOCATION",
                                      "location": targetLoc,
                                      "era": targetEra,
                                    });
                                    await UnityService.post({
                                      "type": "SET_GEOSYNC",
                                      "value": geoSyncEnabled,
                                    });
                                    await UnityService.post({
                                      "type": "SET_DEMO",
                                      "value": true,
                                    });

                                    if (currentUnityLocation != targetLoc) {
                                      await Future.delayed(
                                        const Duration(seconds: 6),
                                      );
                                    }

                                    if (latToSend != null &&
                                        lonToSend != null) {
                                      await UnityService.post({
                                        "type": "SYNC_GPS",
                                        "lat": latToSend,
                                        "lon": lonToSend,
                                      });
                                    }

                                    if (!mounted) return;
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
                                  } catch (e) {
                                    setPopupState(() => isSyncing = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error: $e"),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004C7A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors
                                .grey
                                .shade400, // Visual feedback for disabled state
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Start Experience"),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to call backend /events/filter
  Future<void> _filterEvents(int minYear, int maxYear) async {
    setState(() => isLoading = true);

    // SESSION LOGGING — year range selection
    final selectedLabel = yearRanges.firstWhere(
      (r) => r["min"] == minYear && r["max"] == maxYear,
    )["label"];

    SessionState.yearSelections.add({
      "site_id": widget.siteId,
      "range": selectedLabel,
      "timestamp": DateTime.now().toIso8601String(),
    });

    // const backendUrl = "$baseUrl/events/filter";
    const backendUrl = "http://10.0.2.2:5000/events/filter";

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
            displayedEvents = List<Map<String, dynamic>>.from(
              data["filtered_events"],
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error filtering events: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // custom UI for the dropdown area
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
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedRange,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF004C7A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF004C7A),
                  size: 26,
                ),
              ],
            ),
          ),
        ),

        // Expanded dropdown list (shows below)
        if (isExpanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFECEFF1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected
                                ? const Color(0xFF004C7A)
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Color(0xFF004C7A),
                            size: 20,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.siteName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: "Session Report",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SessionReportScreen()),
              );
            },
          ),
        ],
      ),

      // SafeArea prevents bottom-bar overlapping UI
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Heritage Site Overview Card
              Card(
                elevation: 8,
                color: Colors.white,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        "assets/images/${widget.siteName.toLowerCase().replaceAll(' ', '_')}.jpg",
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.siteName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004C7A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "A treasured landmark of Sri Lanka’s cultural and spiritual heritage.",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // VIEW PRESENT-DAY SITE BUTTON
              ElevatedButton.icon(
                onPressed: _showUnifiedPopup,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text("View Present-Day Site"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004C7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Ancient Events Section Header
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Ancient Events",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB8860B),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Filter dropdown section (expands below)
              _buildFilterDropdown(),

              const SizedBox(height: 20),

              // Event list (filtered + styled)
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB8860B)),
                )
              else if (displayedEvents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      "No ancient events found for this era.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                )
              else
                Column(
                  children: displayedEvents.map((e) {
                    return InkWell(
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
                      borderRadius: BorderRadius.circular(15),
                      child: Card(
                        elevation: 5,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        shadowColor: Colors.black12,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.history_edu_rounded,
                                    color: Color(0xFF004C7A),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      e["event_name"] ?? "Untitled Event",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF004C7A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (e["year"] != null &&
                                  e["year"].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    e["year"].toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                e["description"] ?? "No description available.",
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.5,
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
      ),
    );
  }
}
