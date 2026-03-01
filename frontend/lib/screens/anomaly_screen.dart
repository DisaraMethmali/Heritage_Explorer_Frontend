// lib/screens/anomaly_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class AnomalyScreen extends StatefulWidget {
  const AnomalyScreen({super.key});

  @override
  State<AnomalyScreen> createState() => _AnomalyScreenState();
}

class _AnomalyScreenState extends State<AnomalyScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final _examples = [
    'The Tooth Relic temple was built by the British',
    'Esala Perahera happens in December',
    'Sigiriya was built by King Kassapa I',
    'Sri Lanka gained independence in 1952',
    'The Dutch built Galle Fort in 1663',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _loading = true; _result = null; _error = null; });
    try {
      final api = ApiService();
      final data = await api.checkAnomaly(text);
      setState(() { _result = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('🔍 Fact Checker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGold.withOpacity(0.15),
                    AppTheme.primaryGold.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Historical Fact Checker',
                            style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Check if a historical statement about Sri Lanka is accurate.',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input
            TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type a historical statement to verify...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Check button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _check,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.search),
                label: Text(_loading ? 'Checking...' : 'Check Statement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Examples
            const Text('Try these examples:', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examples.map((e) => InkWell(
                    onTap: () { _ctrl.text = e; setState(() {}); },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(e,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 24),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade700),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),

            // Result
            if (_result != null) _buildResult(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> result) {
    final detected = result['anomaly_detected'] ?? result['detected'] ?? false;
    final correction = result['correction'] ?? result['message'] ?? '';
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final originalText = result['text'] ?? _ctrl.text;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: detected
                  ? Colors.red.shade900.withOpacity(0.3)
                  : Colors.green.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: detected ? Colors.red.shade700 : Colors.green.shade600,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: detected
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      detected ? '❌' : '✅',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detected ? 'Historical Inaccuracy Detected' : 'Statement Appears Accurate',
                        style: TextStyle(
                          color: detected ? Colors.red.shade300 : Colors.green.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (confidence > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // What was checked
          _resultSection(
            icon: '📝',
            title: 'Statement Checked',
            content: originalText,
            borderColor: Colors.white24,
            bgColor: Colors.white.withOpacity(0.04),
          ),

          if (correction.isNotEmpty) ...[
            const SizedBox(height: 12),
            _resultSection(
              icon: detected ? '🔧' : '📚',
              title: detected ? 'Historical Correction' : 'Additional Context',
              content: correction,
              borderColor: detected ? Colors.orange.shade700 : Colors.teal.shade700,
              bgColor: detected
                  ? Colors.orange.withOpacity(0.07)
                  : Colors.teal.withOpacity(0.07),
              textColor: Colors.white.withOpacity(0.87),
            ),
          ],

          // Raw data collapsible
          if (result.containsKey('details') || result.length > 3) ...[
            const SizedBox(height: 12),
            _RawDataToggle(data: result),
          ],
        ],
      ),
    );
  }

  Widget _resultSection({
    required String icon,
    required String title,
    required String content,
    required Color borderColor,
    required Color bgColor,
    Color textColor = Colors.white70,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$icon $title',
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Text(content,
                style: TextStyle(color: textColor, fontSize: 14, height: 1.6)),
          ],
        ),
      );
}

class _RawDataToggle extends StatefulWidget {
  final Map<String, dynamic> data;
  const _RawDataToggle({required this.data});

  @override
  State<_RawDataToggle> createState() => _RawDataToggleState();
}

class _RawDataToggleState extends State<_RawDataToggle> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _show = !_show),
          child: Text(
            _show ? '▲ Hide raw data' : '▼ Show raw API response',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        if (_show)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.data.toString(),
              style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
      ],
    );
  }
}