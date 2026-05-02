// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _navy      = Color(0xFF001233);
  static const Color _navyMid   = Color(0xFF002D72);
  static const Color _blue      = Color(0xFF023E8A);
  static const Color _blueMid   = Color(0xFF0077B6);
  static const Color _gold      = Color(0xFFFFD700);
  static const Color _goldDeep  = Color(0xFFFFB800);
  static const Color _pageBg    = Color(0xFFF5F8FF);
  static const Color _cardBg    = Color(0xFFFFFFFF);
  static const Color _textMain  = Color(0xFF001845);
  static const Color _textSub   = Color(0xFF90A4C4);
  static const Color _inputBg   = Color(0xFFF0F6FF);
  static const Color _micActive = Color(0xFFFF5C5C);

  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

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
              _inputCtrl.selection =
                  TextSelection.fromPosition(TextPosition(offset: text.length));
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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    final user   = context.read<AuthProvider>().user;
    final charId = context.watch<ChatProvider>().activeCharacterId;
    final char   = AppConstants.characters[charId]!;

    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(user, char),
      body: Column(
        children: [
          // ── Hero header space (behind AppBar) ────────────────────────
          _buildHeroHeader(char),

          // ── Character selector ───────────────────────────────────────
          _buildCharacterSelectorWrapper(charId, char),

          // ── Messages list ────────────────────────────────────────────
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, chat, __) {
                final messages = chat.currentMessages;
                if (messages.isEmpty) return _buildEmptyState(char);
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              backgroundColor: _navyMid,
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

          // ── Error banner ─────────────────────────────────────────────
          Consumer<ChatProvider>(
            builder: (_, chat, __) => chat.error != null
                ? Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFC62828), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(chat.error!,
                              style: const TextStyle(
                                  color: Color(0xFFC62828), fontSize: 13)),
                        ),
                        GestureDetector(
                          onTap: chat.clearError,
                          child: const Icon(Icons.close,
                              color: Color(0xFFC62828), size: 16),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Input area ───────────────────────────────────────────────
          _buildInputArea(char),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(dynamic user, CharacterInfo char) {
    return AppBar(
      backgroundColor: Colors.transparent,
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
              border: Border.all(color: _gold, width: 1.5),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                _initials(char.name),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HISTORICAL CHAT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              if (user != null)
                Text(
                  'Hi, ${user.fullName.isNotEmpty ? user.fullName : user.username}',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.8,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => _showClearDialog(),
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _gold.withValues(alpha: 0.6), width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CLEAR',
              style: TextStyle(
                color: _gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Conversation',
          style: TextStyle(
              color: _textMain, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: const Text(
          "Clear this character's conversation?",
          style: TextStyle(color: _textSub, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textSub)),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearConversation();
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(
                    color: Color(0xFFC62828), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Hero header (navy gradient behind appbar) ──────────────────────────────

  Widget _buildHeroHeader(CharacterInfo char) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              height: 112,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, _blue, _blueMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
            Positioned.fill(
                child: CustomPaint(
                    painter: _ShimmerPainter(_shimmer.value))),
            // Wave
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 28),
                painter: _WavePainter(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Character selector wrapper ─────────────────────────────────────────────

  Widget _buildCharacterSelectorWrapper(String charId, CharacterInfo char) {
    return Container(
      color: _pageBg,
      child: CharacterSelector(
        selectedId: charId,
        onSelect: (id) {
          context.read<ChatProvider>().setCharacter(id);
          _scrollToBottom();
        },
      ),
    );
  }

  // ── Input area ─────────────────────────────────────────────────────────────

  Widget _buildInputArea(CharacterInfo char) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          top: BorderSide(
              color: _gold.withValues(alpha: 0.4), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mic button
          GestureDetector(
            onTap: _toggleVoice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isRecording
                    ? _micActive
                    : _gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording
                      ? _micActive
                      : _gold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? _micActive : _gold)
                        .withValues(alpha: _isRecording ? 0.4 : 0.2),
                    blurRadius: _isRecording ? 14 : 4,
                    spreadRadius: _isRecording ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? Colors.white : _goldDeep,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: _navyMid.withValues(alpha: 0.15), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                style:
                    const TextStyle(color: _textMain, fontSize: 14, height: 1.4),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: 'Ask ${char.name}...',
                  hintStyle:
                      const TextStyle(color: _textSub, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          Consumer<ChatProvider>(
            builder: (_, chat, __) => GestureDetector(
              onTap: chat.isLoading ? null : () => _send(_inputCtrl.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: chat.isLoading
                      ? null
                      : const LinearGradient(
                          colors: [_navyMid, _blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: chat.isLoading
                      ? const Color(0xFFDDE6F0)
                      : null,
                  boxShadow: chat.isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: _navyMid.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: chat.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _navyMid,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(CharacterInfo char) {
    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Character medallion
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _gold.withValues(alpha: 0.2), width: 1),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _gold.withValues(alpha: 0.5), width: 1.5),
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF0A4FA3), _navy],
                          center: Alignment(-0.3, -0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.3),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _initials(char.name),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Gold pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.4), width: 1),
                  ),
                  child: const Text(
                    'HISTORICAL FIGURE',
                    style: TextStyle(
                      color: Color(0xFFB8860B),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  char.name,
                  style: const TextStyle(
                    color: _textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  char.title,
                  style: const TextStyle(color: _textSub, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Section label
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 13,
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SUGGESTED QUESTIONS',
                      style: TextStyle(
                        color: _navyMid,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Suggestion chips
                ...[
                  'Hello, who are you?',
                  'Tell me about the Tooth Relic',
                  'What is the Esala Perahera?',
                ].map((q) => _SuggestionChip(
                      question: q,
                      onTap: () => _send(q),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────────────────

  Widget _buildTypingIndicator(CharacterInfo char) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF0A4FA3), _navy],
                center: Alignment(-0.3, -0.3),
              ),
              border: Border.all(
                  color: _gold.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials(char.name),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                  color: _navyMid.withValues(alpha: 0.10), width: 1),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
      tween: Tween(begin: 0.2, end: 1.0),
      duration: Duration(milliseconds: 500 + i * 150),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _navyMid.withValues(alpha: v),
        ),
      ),
    );
  }
}

// ── Suggestion chip ───────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;
  const _SuggestionChip({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF002D72).withValues(alpha: 0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001845).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF002D72).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF002D72), size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  color: Color(0xFF001845),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: const Color(0xFF90A4C4).withValues(alpha: 0.7),
                size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    p.color = const Color(0xFFFFD700).withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 1.05, -10), size.width * 0.55, p);

    p.color = const Color(0xFF48CAE4).withValues(alpha: 0.09);
    canvas.drawCircle(Offset(-20, size.height * 1.2), size.width * 0.45, p);

    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.03);
    p.strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x + 40, size.height), p);
    }

    final dot = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
            Offset(size.width - 20 - i * 18.0, 16 + j * 18.0), 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(progress - 1, 0),
      end: Alignment(progress, 0),
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.04),
        Colors.transparent,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) =>
      old.progress != progress;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F8FF)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}