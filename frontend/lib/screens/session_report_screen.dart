// frontend/lib/screens/session_report_screen.dart

import 'package:flutter/material.dart';
import '../state/session_state.dart';
import 'pdf_preview_screen.dart';
import '../state/navigation_state.dart';

class SessionReportScreen extends StatelessWidget {
  const SessionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Session Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // SAFE AREA FIX (prevents overlap with system navigation bar)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Intro (no card)
              const Text(
                "Your Heritage Learning Session",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004C7A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "This summary captures the places you visited, historical events you explored, and interactions recorded during this session. "
                "These details will be used to generate a personalized learning report.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              _sectionHeader(Icons.place_outlined, "Visited Sites"),
              _visitedSites(),

              const SizedBox(height: 24),

              _sectionHeader(Icons.history_edu_outlined, "Selected Events"),
              _selectedEvents(),

              const SizedBox(height: 24),

              _sectionHeader(Icons.filter_alt_outlined, "Year Filters Applied"),
              _yearFilters(),

              const SizedBox(height: 24),

              _sectionHeader(Icons.chat_bubble_outline, "Questions Asked"),
              _questions(),

              const SizedBox(height: 36),

              // Primary Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    "Generate Personalized Report",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004C7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PDFPreviewScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Action — Back to Home
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text(
                    "Back to Home",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF004C7A),
                    side: const BorderSide(color: Color(0xFF004C7A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Switch tab FIRST
                    NavigationState.selectedIndex.value = 0;

                    // Then pop back to MainScaffold
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF004C7A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004C7A),
          ),
        ),
      ],
    );
  }

  Widget _visitedSites() {
    if (SessionState.visitedSites.isEmpty) {
      return _emptyText("No sites recorded in this session.");
    }

    return Column(
      children: SessionState.visitedSites.map((e) {
        return _listItem(
          title: e["site_name"],
          subtitle: "Visited at ${_formatTime(e["timestamp"])}",
        );
      }).toList(),
    );
  }

  Widget _selectedEvents() {
    if (SessionState.selectedEvents.isEmpty) {
      return _emptyText("No historical events selected.");
    }

    return Column(
      children: SessionState.selectedEvents.map((e) {
        return _listItem(
          title: e["event_name"],
          subtitle: "${e["year"]} · ${e["site_name"]}",
        );
      }).toList(),
    );
  }

  Widget _yearFilters() {
    if (SessionState.yearSelections.isEmpty) {
      return _emptyText("No year ranges selected.");
    }

    return Column(
      children: SessionState.yearSelections.map((e) {
        return _listItem(
          title: "Explored events from",
          subtitle: e["range"],
        );
      }).toList(),
    );
  }

  Widget _questions() {
    if (SessionState.questionsAsked.isEmpty) {
      return _emptyText("No questions asked during this session.");
    }

    return Column(
      children: SessionState.questionsAsked.map((e) {
        return _listItem(
          title: e["question"],
          subtitle: "Asked at ${_formatTime(e["timestamp"])}",
        );
      }).toList(),
    );
  }

  Widget _listItem({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
