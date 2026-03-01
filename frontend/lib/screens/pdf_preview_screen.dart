// frontend/lib/screens/pdf_preview_screen.dart

import 'package:flutter/material.dart';
import '../state/session_state.dart';

class PDFPreviewScreen extends StatelessWidget {
  const PDFPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C7A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Report Preview",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: "Download PDF (Coming Soon)",
            visualDensity: const VisualDensity(horizontal: -2),
            padding: EdgeInsets.zero,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("PDF download will be implemented later."),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            tooltip: "Email Report (Coming Soon)",
            visualDensity: const VisualDensity(horizontal: -2),
            padding: EdgeInsets.zero,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Email delivery will be implemented in the next phase."),
                ),
              );
            },
          ),
        ],
      ),

      // Document-like container
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header
                  const Text(
                    "Personalized Heritage Learning Report",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004C7A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Generated on ${_formatNow()}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  // Introduction
                  const Text(
                    "Overview",
                    style: _sectionTitleStyle,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "This report summarizes the heritage sites you visited, historical events you explored, and interactions recorded during this learning session. "
                    "It is generated to help you retain and reflect on your cultural exploration experience.",
                    style: _bodyStyle,
                  ),

                  const SizedBox(height: 24),

                  _section(
                    title: "Visited Heritage Sites",
                    items: SessionState.visitedSites
                        .map((e) => e["site_name"]?.toString() ?? "")
                        .toList(),
                    emptyText: "No heritage sites were recorded.",
                  ),

                  _section(
                    title: "Historical Events Explored",
                    items: SessionState.selectedEvents.map((e) {
                      return "${e["event_name"]} (${e["year"]})";
                    }).toList(),
                    emptyText: "No historical events were selected.",
                  ),

                  _section(
                    title: "Year Ranges Explored",
                    items: SessionState.yearSelections
                        .map((e) => e["range"]?.toString() ?? "")
                        .toList(),
                    emptyText: "No year ranges were applied.",
                  ),

                  _section(
                    title: "Questions Asked",
                    items: SessionState.questionsAsked
                        .map((e) => e["question"]?.toString() ?? "")
                        .toList(),
                    emptyText: "No questions were asked during this session.",
                  ),

                  const SizedBox(height: 32),
                  const Divider(),

                  // Footer
                  const Text(
                    "Generated using an AI-assisted heritage learning system.\n"
                    "This report is intended for educational purposes.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Helpers ----------

  static const TextStyle _sectionTitleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: Color(0xFF004C7A),
  );

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
    height: 1.5,
  );

  static Widget _section({
    required String title,
    required List<String> items,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _sectionTitleStyle),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            children: items.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• "),
                    Expanded(
                      child: Text(
                        e,
                        style: _bodyStyle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  static String _formatNow() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}
