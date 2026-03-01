import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/voice_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final CharacterInfo characterInfo;
  final Function(double)? onFeedback;

  const ChatBubble({
    super.key,
    required this.message,
    required this.characterInfo,
    this.onFeedback,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  final VoiceService _voice = VoiceService();
  bool _showEnrichments = false;
  bool _showFeedback = false;
  double? _rating;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.characterInfo.color.withOpacity(0.3),
                    border: Border.all(
                        color: widget.characterInfo.color.withOpacity(0.6)),
                  ),
                  child: Center(
                    child: Text(widget.characterInfo.emoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Bubble
              Flexible(
                child: GestureDetector(
                  onLongPress: isUser
                      ? null
                      : () {
                          _voice.speak(msg.content,
                              );
                        },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? widget.characterInfo.color.withOpacity(0.3)
                          : AppTheme.cardDark,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: Border.all(
                        color: isUser
                            ? widget.characterInfo.color.withOpacity(0.5)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Anomaly warning
                        if (!isUser && msg.anomaly?.detected == true) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber,
                                    color: Colors.orange, size: 14),
                                SizedBox(width: 4),
                                Text('Misconception Corrected',
                                    style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],

                        // Message text
                        SelectableText(
                          msg.content,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                            fontSize: 14.5,
                            height: 1.5,
                          ),
                        ),

                        // Metadata
                        if (!isUser && msg.confidence != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _chip(
                                  '${(msg.confidence! * 100).toInt()}%',
                                  Colors.green),
                              const SizedBox(width: 4),
                              if (msg.topic != null)
                                _chip(msg.topic!, AppTheme.jade),
                            ],
                          ),
                        ],

                        // Timestamp
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            DateFormat('HH:mm').format(msg.timestamp),
                            style: const TextStyle(
                                color: Colors.white30, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isUser) const SizedBox(width: 8),
            ],
          ),

          // Bot message actions
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Row(
                children: [
                  // TTS button
                  _actionBtn(
                    icon: Icons.volume_up_outlined,
                    onTap: () => _voice.speak(msg.content),
                    tooltip: 'Listen',
                  ),
                  const SizedBox(width: 4),

                  // Feedback
                  _actionBtn(
                    icon: Icons.thumb_up_outlined,
                    onTap: () => setState(() => _showFeedback = !_showFeedback),
                    tooltip: 'Rate',
                  ),
                  const SizedBox(width: 4),

                  // Enrichments toggle
                  if (_hasEnrichments()) ...[
                    _actionBtn(
                      icon: _showEnrichments
                          ? Icons.expand_less
                          : Icons.auto_awesome_outlined,
                      onTap: () =>
                          setState(() => _showEnrichments = !_showEnrichments),
                      tooltip: 'Show enrichments',
                      color: AppTheme.saffron,
                    ),
                  ],
                ],
              ),
            ),

            // Feedback bar
            if (_showFeedback)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 4),
                child: Row(
                  children: [
                    const Text('Rate: ',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    ...List.generate(5, (i) {
                      final star = (i + 1).toDouble();
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = star;
                            _showFeedback = false;
                          });
                          widget.onFeedback?.call(star);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            (_rating ?? 0) >= star
                                ? Icons.star
                                : Icons.star_border,
                            color: AppTheme.primaryGold,
                            size: 22,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Enrichments panel
            if (_showEnrichments && _hasEnrichments())
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 8),
                child: _buildEnrichmentsPanel(),
              ),
          ],
        ],
      ),
    );
  }

  bool _hasEnrichments() {
    final msg = widget.message;
    return msg.folklore != null ||
        msg.causalChain != null ||
        msg.criticalQuestion != null ||
        (msg.vrSites?.isNotEmpty ?? false);
  }

  Widget _buildEnrichmentsPanel() {
    final msg = widget.message;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folklore
          if (msg.folklore != null) ...[
            _enrichmentSection(
              '📜 Legend: ${msg.folklore!.legendTitle}',
              msg.folklore!.legend,
              AppTheme.saffron,
            ),
            const SizedBox(height: 8),
            _enrichmentSection(
              '📚 Historical Fact',
              msg.folklore!.historicalFact,
              AppTheme.jade,
            ),
            const Divider(color: AppTheme.borderColor, height: 16),
          ],

          // Critical question
          if (msg.criticalQuestion != null) ...[
            _enrichmentSection(
              '💭 Think Deeper',
              msg.criticalQuestion!,
              AppTheme.sriLankaBlue,
            ),
            const Divider(color: AppTheme.borderColor, height: 16),
          ],

          // VR Sites
          if (msg.vrSites?.isNotEmpty ?? false) ...[
            const Text('🏛️ Explore in VR',
                style: TextStyle(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
            const SizedBox(height: 6),
            ...msg.vrSites!.take(2).map((site) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(color: Colors.white54)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(site.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text(site.vrExperience,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _enrichmentSection(String title, String content, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(content,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12, height: 1.4)),
        ],
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 10)),
      );

  Widget _actionBtn({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color color = Colors.white38,
  }) =>
      Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      );
}
