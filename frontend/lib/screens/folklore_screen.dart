// lib/screens/folklore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class FolkloreScreen extends StatefulWidget {
  const FolkloreScreen({super.key});

  @override
  State<FolkloreScreen> createState() => _FolkloreScreenState();
}

class _FolkloreScreenState extends State<FolkloreScreen> {
  List<Map<String, dynamic>> _folklore = [];
  bool _loading = true;
  String? _error;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService();
      final data = await api.getFolklore();
      final raw = data['folklore'] as List? ?? data['legends'] as List? ?? [];
      setState(() {
        _folklore = raw.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('🏺 Folklore & Legends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _error != null
              ? _buildError()
              : _folklore.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏺', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('No folklore available', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );

  Widget _buildList() => RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primaryGold,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _folklore.length,
          itemBuilder: (_, i) {
            final item = _folklore[i];
            final isExpanded = _expandedIndex == i;
            final title = item['legend_title'] ?? item['title'] ?? 'Untitled Legend';
            final legend = item['legend'] ?? item['story'] ?? '';
            final fact = item['historical_fact'] ?? item['fact'] ?? '';
            final character = item['character'] ?? item['character_id'] ?? '';

            final charColor = _charColor(character);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isExpanded ? charColor : AppTheme.borderColor,
                  width: isExpanded ? 1.5 : 1,
                ),
                boxShadow: isExpanded
                    ? [BoxShadow(color: charColor.withOpacity(0.15), blurRadius: 12, spreadRadius: 2)]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Header
                    InkWell(
                      onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: charColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(_charEmoji(character), style: const TextStyle(fontSize: 22)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: isExpanded ? AppTheme.primaryGold : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (character.isNotEmpty)
                                    Text(
                                      _charName(character),
                                      style: TextStyle(color: charColor, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded content
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isExpanded
                          ? Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(color: AppTheme.borderColor),
                                  const SizedBox(height: 8),

                                  // Legend / Story
                                  _sectionLabel('📖 The Legend', AppTheme.primaryGold),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGold.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.primaryGold.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      legend,
                                      style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 13.5, height: 1.6),
                                    ),
                                  ),

                                  if (fact.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    _sectionLabel('🏛️ Historical Fact', Colors.tealAccent),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                                      ),
                                     child: Text(
                                    fact,
                                    style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 13.5, height: 1.6),
                                    ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _sectionLabel(String text, Color color) => Row(
        children: [
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      );

  Color _charColor(String id) => switch (id) {
        'king' => const Color(0xFFFFD700),
        'nilame' => const Color(0xFFFFAB40),
        'dutch' => const Color(0xFF4CAF50),
        'citizen' || 'guide' => const Color(0xFF00BCD4),
        _ => AppTheme.primaryGold,
      };

  String _charEmoji(String id) => switch (id) {
        'king' => '👑',
        'nilame' => '🏛️',
        'dutch' => '⚓',
        'citizen' || 'guide' => '📚',
        _ => '🏺',
      };

  String _charName(String id) => switch (id) {
        'king' => 'King Sri Vijaya Rajasinha',
        'nilame' => 'Diyawadana Nilame',
        'dutch' => 'Dutch Merchant',
        'citizen' || 'guide' => 'Heritage Guide',
        _ => id,
      };
}