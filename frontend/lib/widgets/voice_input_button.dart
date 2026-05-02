import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../utils/theme.dart';

class VoiceInputButton extends StatelessWidget {
  final Function(String) onTextReceived;
  final Function(String) onSendReceived;

  const VoiceInputButton({
    super.key,
    required this.onTextReceived,
    required this.onSendReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceService>(
      builder: (_, voice, __) {
        final isListening = voice.isListening;
        final available = voice.sttAvailable;

        if (!available) {
          return const SizedBox(width: 48, height: 48);
        }

        return GestureDetector(
          onTap: () {
            if (isListening) {
              voice.stopListening();
            } else {
              _startListening(context, voice);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isListening
                  ? Colors.red.withOpacity(0.2)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isListening ? Colors.red : AppTheme.borderColor,
                width: isListening ? 2 : 1,
              ),
              boxShadow: isListening
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isListening ? Icons.stop : Icons.mic,
                  color: isListening ? Colors.red : Colors.white54,
                  size: 22,
                ),
                if (isListening)
                  Positioned.fill(
                    child: _PulseAnimation(
                      color: Colors.red.withOpacity(0.3),
                      soundLevel: voice.soundLevel,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startListening(BuildContext context, VoiceService voice) {
    String lastText = '';
    voice.startListening(
      onResult: (text) {
        lastText = text;
        onTextReceived(text);
      },
      onDone: () {
        if (lastText.trim().isNotEmpty) {
          onSendReceived(lastText.trim());
        }
      },
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Color color;
  final double soundLevel;

  const _PulseAnimation({required this.color, required this.soundLevel});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value * 0.5),
        ),
      ),
    );
  }
}
