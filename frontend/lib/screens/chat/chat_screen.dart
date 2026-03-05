// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/voice_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/character_selector.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;

  // ── Light mode palette ────────────────────────────────────────────────────
  static const Color _pageBg       = Color(0xFFFFFDE7); // light yellow page bg
  static const Color _appBarBg     = Color(0xFF0D47A1); // deep blue app bar
  static const Color _inputBg      = Color(0xFFFFF9C4); // soft yellow input bg
  static const Color _inputBorder  = Color(0xFFE6D96A); // warm yellow border
  static const Color _sendBg       = Color(0xFF1565C0); // mid blue send btn
  static const Color _micIdle      = Color(0xFFFFE082); // light yellow mic
  static const Color _micActive    = Color(0xFFFF7043); // orange-red active mic
  static const Color _deepBlue     = Color(0xFF0D47A1); // deep blue text
  static const Color _midBlue      = Color(0xFF1565C0); // mid blue accents
  static const Color _hintBlue     = Color(0xFF5C7CBF); // muted blue hints

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    _focusNode.unfocus();
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  // ── Voice toggle ──────────────────────────────────────────────────────────
  Future<void> _toggleVoice() async {
    final voice = context.read<VoiceService>();

    if (_isRecording) {
      await voice.stopListening();
      setState(() => _isRecording = false);
      if (_inputCtrl.text.trim().isNotEmpty) {
        await _send(_inputCtrl.text.trim());
      }
    } else {
      final ok = await voice.initStt();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone not available. Check permissions.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      setState(() => _isRecording = true);
      await voice.startListening(
        onResult: (text) {
          if (mounted) {
            setState(() {
              _inputCtrl.text = text;
              _inputCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
            });
          }
        },
        onDone: () async {
          if (mounted) setState(() => _isRecording = false);
          if (_inputCtrl.text.trim().isNotEmpty) {
            await _send(_inputCtrl.text.trim());
          }
        },
      );
    }
  }

  // ── Initials helper ───────────────────────────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final user   = context.read<AuthProvider>().user;
    final charId = context.watch<ChatProvider>().activeCharacterId;
    final char   = AppConstants.characters[charId]!;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historical Chat',
              style: TextStyle(
                color: Color(0xFFFFF9C4),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (user != null)
              Text(
                'Hi, ${user.fullName.isNotEmpty ? user.fullName : user.username}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFFE082),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFFE082)),
            tooltip: 'Clear chat',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: _pageBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  'Clear Conversation',
                  style: TextStyle(
                      color: _deepBlue, fontWeight: FontWeight.w700),
                ),
                content: const Text(
                  "Clear this character's conversation?",
                  style: TextStyle(color: _hintBlue),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: _hintBlue)),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ChatProvider>().clearConversation();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Character selector ──────────────────────────────────────────
          CharacterSelector(
            selectedId: charId,
            onSelect: (id) {
              context.read<ChatProvider>().setCharacter(id);
              _scrollToBottom();
            },
          ),

          // ── Messages list ───────────────────────────────────────────────
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, chat, __) {
                final messages = chat.currentMessages;
                if (messages.isEmpty) return _buildEmptyState(char);
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length + (chat.isLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == messages.length) {
                      return _buildTypingIndicator(char);
                    }
                    return ChatBubble(
                      message: messages[i],
                      characterInfo: char,
                      onFeedback: (rating) {
                        if (!messages[i].isUser) {
                          chat.submitFeedback(messages[i].content, rating);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Thanks for rating $rating★'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: _midBlue,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),

          // ── Error banner ────────────────────────────────────────────────
          Consumer<ChatProvider>(
            builder: (_, chat, __) => chat.error != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: Colors.red.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(chat.error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.red, size: 16),
                          onPressed: chat.clearError,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Input area ──────────────────────────────────────────────────
          _buildInputArea(char),
        ],
      ),
    );
  }

  // ── Input row ─────────────────────────────────────────────────────────────
  Widget _buildInputArea(CharacterInfo char) {
    return Container(
      decoration: BoxDecoration(
        color: _pageBg,
        border: Border(
          top: BorderSide(
              color: _inputBorder.withOpacity(0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // ── Mic button ────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleVoice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isRecording ? _micActive : _micIdle,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? _micActive : _micIdle)
                        .withOpacity(0.45),
                    blurRadius: _isRecording ? 14 : 4,
                    spreadRadius: _isRecording ? 3 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? Colors.white : Colors.black87,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Text input ────────────────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _inputBorder),
                boxShadow: [
                  BoxShadow(
                    color: _deepBlue.withOpacity(0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                style: const TextStyle(color: _deepBlue, fontSize: 14),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: 'Ask ${char.name}...',
                  hintStyle: const TextStyle(
                      color: _hintBlue, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Send button ───────────────────────────────────────────────
          Consumer<ChatProvider>(
            builder: (_, chat, __) => GestureDetector(
              onTap: chat.isLoading
                  ? null
                  : () => _send(_inputCtrl.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: chat.isLoading
                      ? Colors.grey.shade300
                      : _sendBg,
                  shape: BoxShape.circle,
                  boxShadow: chat.isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: _sendBg.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: chat.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFF9C4),
                        ),
                      )
                    : const Icon(Icons.send,
                        color: Color(0xFFFFF9C4), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(CharacterInfo char) {
    return Container(
      color: _pageBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Character avatar — initials, no emoji
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE3F2FD),
                  border: Border.all(
                    color: _midBlue.withOpacity(0.5),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _deepBlue.withOpacity(0.12),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials(char.name),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _deepBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                char.name,
                style: const TextStyle(
                  color: _deepBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                char.title,
                style: const TextStyle(color: _midBlue, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Suggested questions
              ...['Hello, who are you?',
                  'Tell me about the Tooth Relic',
                  'What is the Esala Perahera?']
                  .map(
                    (q) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _send(q),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _deepBlue.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _deepBlue.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: _midBlue.withOpacity(0.6),
                                  size: 15),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  q,
                                  style: const TextStyle(
                                    color: _deepBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: _hintBlue.withOpacity(0.5),
                                  size: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────
  Widget _buildTypingIndicator(CharacterInfo char) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Avatar — initials, no emoji
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE3F2FD),
              border: Border.all(
                color: _midBlue.withOpacity(0.4),
              ),
            ),
            child: Center(
              child: Text(
                _initials(char.name),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _deepBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border:
                  Border.all(color: _inputBorder.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: _deepBlue.withOpacity(0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _dot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 500 + i * 150),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _deepBlue.withOpacity(v),
        ),
      ),
    );
  }
}