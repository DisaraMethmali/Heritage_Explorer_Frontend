// lib/widgets/report_generator_widget.dart
// ============================================================
// RAG Report Generator Widget
// Add this to the ProfileScreen to let users download their
// historical journey PDF reports (Full / Temple / Galle Fort)
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';        // open_filex: ^4.3.4
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import 'package:flutter/foundation.dart';
/// Preview data returned by  GET /report/preview
class ReportPreview {
  final int totalMessages;
  final int templeMessages;
  final int galleMessages;
  final int generalMessages;
  final double avgConfidencePct;
  final int uniqueSessions;
  final bool hasTempleReport;
  final bool hasGalleReport;
  final Map<String, dynamic> charactersUsed;
  final Map<String, dynamic> topTopics;

  const ReportPreview({
    required this.totalMessages,
    required this.templeMessages,
    required this.galleMessages,
    required this.generalMessages,
    required this.avgConfidencePct,
    required this.uniqueSessions,
    required this.hasTempleReport,
    required this.hasGalleReport,
    required this.charactersUsed,
    required this.topTopics,
  });

  factory ReportPreview.fromJson(Map<String, dynamic> j) => ReportPreview(
        totalMessages:    j['total_messages']    ?? 0,
        templeMessages:   j['temple_messages']   ?? 0,
        galleMessages:    j['galle_messages']    ?? 0,
        generalMessages:  j['general_messages']  ?? 0,
        avgConfidencePct: (j['avg_confidence_pct'] as num?)?.toDouble() ?? 0,
        uniqueSessions:   j['unique_sessions']   ?? 0,
        hasTempleReport:  j['has_temple_report'] ?? false,
        hasGalleReport:   j['has_galle_report']  ?? false,
        charactersUsed:   Map<String, dynamic>.from(j['characters_used'] ?? {}),
        topTopics:        Map<String, dynamic>.from(j['top_topics']      ?? {}),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class ReportGeneratorWidget extends StatefulWidget {
  final String authToken;
  final String username;

  const ReportGeneratorWidget({
    super.key,
    required this.authToken,
    required this.username,
  });

  @override
  State<ReportGeneratorWidget> createState() => _ReportGeneratorWidgetState();
}

class _ReportGeneratorWidgetState extends State<ReportGeneratorWidget> {
  ReportPreview? _preview;
  bool _loadingPreview = false;
  String? _previewError;

  /// Which report is currently downloading: 'all' | 'temple' | 'galle' | null
  String? _downloading;

  final String _baseUrl = AppConstants.apiBaseUrl; // e.g. "http://192.168.x.x:5000"

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  // ── Network ────────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type':  'application/json',
      };

  Future<void> _fetchPreview() async {
    setState(() { _loadingPreview = true; _previewError = null; });
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/report/preview'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() => _preview = ReportPreview.fromJson(data['preview']));
        } else {
          setState(() => _previewError = data['error'] ?? 'Unknown error');
        }
      } else if (res.statusCode == 404) {
        setState(() => _previewError = 'no_history');
      } else {
        setState(() => _previewError = 'Server error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _previewError = e.toString());
    } finally {
      setState(() => _loadingPreview = false);
    }
  }

  Future<void> _downloadReport(String location) async {
  if (_downloading != null) return;
  setState(() => _downloading = location);

 final url = '$_baseUrl/report/user?location=$location';

  final filename = location == 'all'
      ? 'full_report_${widget.username}.pdf'
      : '${location}_report_${widget.username}.pdf';

  try {
    final res = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      _showSnack(body['error'] ?? 'Download failed', isError: true);
      return;
    }

    // ================= WEB =================
    if (kIsWeb) {
      final bytes = res.bodyBytes;
      final blob = html.Blob([bytes], 'application/pdf');
      final urlBlob = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: urlBlob)
        ..setAttribute('download', filename)
        ..click();

      html.Url.revokeObjectUrl(urlBlob);

      _showSnack('Download started', isError: false);
      return;
    }

    // ================= MOBILE =================
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(res.bodyBytes);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done && mounted) {
      _showSnack('PDF saved to ${file.path}', isError: false);
    }
  } catch (e) {
    _showSnack('Error: $e', isError: true);
  } finally {
    if (mounted) setState(() => _downloading = null);
  }
}

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: AppTheme.primaryGold, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Historical Journey Report',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text('Download your personalised PDF report',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              // Refresh preview
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white38, size: 18),
                tooltip: 'Refresh',
                onPressed: _loadingPreview ? null : _fetchPreview,
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_loadingPreview)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppTheme.primaryGold),
              ),
            )
          else if (_previewError == 'no_history')
            _noHistoryBanner()
          else if (_previewError != null)
            _errorBanner(_previewError!)
          else if (_preview != null)
            _previewContent(_preview!)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ── Preview content ────────────────────────────────────────────────────────

  Widget _previewContent(ReportPreview p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          children: [
            _statChip('${p.totalMessages}', 'Total Chats', AppTheme.primaryGold),
            const SizedBox(width: 8),
            _statChip('${p.uniqueSessions}', 'Sessions', AppTheme.jade),
            const SizedBox(width: 8),
            _statChip('${p.avgConfidencePct.toStringAsFixed(0)}%',
                'Avg Confidence', Colors.blueAccent),
          ],
        ),
        const SizedBox(height: 14),

        // Location cards row
        Row(
          children: [
            Expanded(
              child: _locationCard(
                emoji:    '🛕',
                title:    'Temple of the\nSacred Tooth Relic',
                subtitle: 'Kandy',
                count:    p.templeMessages,
                color:    const Color(0xFFA855F7),
                location: 'temple',
                enabled:  p.hasTempleReport,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _locationCard(
                emoji:    '🏰',
                title:    'Galle Fort\n',
                subtitle: 'Southern Coast',
                count:    p.galleMessages,
                color:    const Color(0xFF3B82F6),
                location: 'galle',
                enabled:  p.hasGalleReport,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Full report button
        SizedBox(
          width: double.infinity,
          child: _downloadButton(
            label:    'Download Full Report (All Locations)',
            icon:     Icons.file_download_outlined,
            location: 'all',
            color:    AppTheme.primaryGold,
            enabled:  p.totalMessages > 0,
          ),
        ),

        // Characters used chips
        if (p.charactersUsed.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Characters in your report:',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: p.charactersUsed.entries.map((e) {
              final col = _charColor(e.key);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: col.withOpacity(0.5)),
                ),
                child: Text(
                  '${_charEmoji(e.key)} ${_charShortName(e.key)} (${e.value})',
                  style: TextStyle(color: col, fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Location card ──────────────────────────────────────────────────────────

  Widget _locationCard({
    required String emoji,
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required String location,
    required bool enabled,
  }) {
    final isDownloading = _downloading == location;
    return GestureDetector(
      onTap: (enabled && !isDownloading && _downloading == null)
          ? () => _downloadReport(location)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.12)
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? color.withOpacity(0.6) : AppTheme.borderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (enabled && !isDownloading)
                  Icon(Icons.file_download_outlined,
                      color: color, size: 18),
                if (isDownloading)
                  SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.3)),
            Text(subtitle,
                style: TextStyle(
                    color: enabled ? color : Colors.white24,
                    fontSize: 10)),
            const SizedBox(height: 6),
            Text(
              enabled ? '$count conversations' : 'No conversations yet',
              style: TextStyle(
                color: enabled ? color.withOpacity(0.8) : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (enabled) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isDownloading ? 'Generating…' : 'Download PDF',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Download button ────────────────────────────────────────────────────────

  Widget _downloadButton({
    required String label,
    required IconData icon,
    required String location,
    required Color color,
    required bool enabled,
  }) {
    final isDownloading = _downloading == location;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.5),
              ])
            : null,
        color: enabled ? null : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? color : AppTheme.borderColor,
        ),
      ),
      child: InkWell(
        onTap: (enabled && !isDownloading && _downloading == null)
            ? () => _downloadReport(location)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDownloading)
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(icon, color: enabled ? Colors.white : Colors.white24,
                    size: 18),
              const SizedBox(width: 8),
              Text(
                isDownloading ? 'Generating PDF…' : label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white24,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty / error states ───────────────────────────────────────────────────

  Widget _noHistoryBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Column(
          children: [
            Text('📭', style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text('No conversations yet',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text(
              'Chat with the historical characters first,\nthen come back to generate your report!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _errorBanner(String error) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade700.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error,
                  style: const TextStyle(color: Colors.redAccent,
                      fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.redAccent,
                  size: 16),
              onPressed: _fetchPreview,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _statChip(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 9),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Color _charColor(String charId) {
    return {
      'king':    AppTheme.primaryGold,
      'nilame':  const Color(0xFFA855F7),
      'dutch':   const Color(0xFF3B82F6),
      'citizen': AppTheme.jade,
    }[charId] ?? Colors.white38;
  }

  String _charEmoji(String charId) {
    return {'king': '👑', 'nilame': '🛕', 'dutch': '⚓', 'citizen': '📚'}[charId] ?? '🎭';
  }

  String _charShortName(String charId) {
    return {
      'king':    'King',
      'nilame':  'Nilame',
      'dutch':   'Dutch Capt.',
      'citizen': 'Historian',
    }[charId] ?? charId;
  }
}