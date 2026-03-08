// lib/screens/quiz/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/gradient_button.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  String _selectedCharacter  = 'king';
  String _selectedType       = 'multiple_choice';
  String _selectedDifficulty = 'medium';

  QuizQuestion? _currentQuiz;
  bool    _isLoading       = false;
  bool    _isSubmitting    = false;
  bool    _hasAnswered     = false;
  bool    _answeredCorrect = false;
  dynamic _selectedAnswer;
  QuizResult? _result;
  int     _totalXp         = 0;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _navy     = Color(0xFF001233);
  static const Color _navyMid  = Color(0xFF002D72);
  static const Color _blue     = Color(0xFF023E8A);
  static const Color _blueMid  = Color(0xFF0077B6);
  static const Color _gold     = Color(0xFFFFD700);
  static const Color _goldDeep = Color(0xFFFFB800);
  static const Color _pageBg   = Color(0xFFF5F8FF);
  static const Color _textMain = Color(0xFF001845);
  static const Color _textSub  = Color(0xFF90A4C4);
  static const Color _inputBg  = Color(0xFFF0F6FF);

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _shimmerController;
  late Animation<double>   _shimmer;

  final List<Map<String, String>> _quizTypes = [
    {'id': 'multiple_choice', 'label': 'Multiple Choice'},
    {'id': 'true_false',      'label': 'True / False'},
    {'id': 'fill_blank',      'label': 'Fill in the Blank'},
    {'id': 'vr_challenge',    'label': 'VR Challenge'},
  ];

  final List<Map<String, String>> _difficulties = [
    {'id': 'easy',   'label': 'Easy'},
    {'id': 'medium', 'label': 'Medium'},
    {'id': 'hard',   'label': 'Hard'},
  ];

  Color _diffColor(String id) => switch (id) {
        'easy'   => const Color(0xFF2E7D32),
        'medium' => const Color(0xFFE65100),
        'hard'   => const Color(0xFFC62828),
        _        => _navyMid,
      };

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get _sessionId {
    final user = context.read<AuthProvider>().user;
    return user?.username ?? 'quiz_guest';
  }

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
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _generateQuiz() async {
    setState(() {
      _isLoading      = true;
      _currentQuiz    = null;
      _hasAnswered    = false;
      _selectedAnswer = null;
      _result         = null;
    });
    try {
      final data = await _api.generateQuiz(
        characterId: _selectedCharacter,
        quizType:    _selectedType,
        difficulty:  _selectedDifficulty,
        sessionId:   _sessionId,
      );
      final quiz = QuizQuestion.fromJson(data, {
        'character_id': _selectedCharacter,
        'quiz_type':    _selectedType,
        'difficulty':   _selectedDifficulty,
      });
      setState(() { _currentQuiz = quiz; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _submitAnswer(dynamic answer) async {
    if (_currentQuiz == null || _isSubmitting) return;
    setState(() { _isSubmitting = true; _selectedAnswer = answer; });
    try {
      final data = await _api.submitQuizAnswer(
        sessionId:     _sessionId,
        quizType:      _selectedType,
        userAnswer:    answer,
        correctAnswer: _currentQuiz!.correctAnswer ?? _currentQuiz!.boolAnswer,
        xpReward:      _currentQuiz!.xpReward,
        challengeId:   _currentQuiz!.challengeId,
      );
      final result = QuizResult.fromJson(data);
      setState(() {
        _result          = result;
        _hasAnswered     = true;
        _answeredCorrect = result.correct;
        _totalXp         = result.totalXp;
        _isSubmitting    = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      body: Column(children: [
        _buildHero(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildConfigPanel(),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Generate New Question',
                icon: Icons.refresh,
                isLoading: _isLoading,
                onPressed: _generateQuiz,
              ),
              const SizedBox(height: 20),
              if (_currentQuiz != null) _buildQuizContent(),
              const SizedBox(height: 16),
              _buildLeaderboardButton(),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _navy,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
        ),
      ),
      title: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 1.5),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.quiz_outlined, size: 16, color: _gold),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('VR QUIZ', style: TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w800, letterSpacing: 2.0)),
            Text('Test your knowledge', style: TextStyle(color: _gold, fontSize: 10,
                fontWeight: FontWeight.w400, letterSpacing: 1.2)),
          ],
        ),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: 0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, color: _gold, size: 15),
            const SizedBox(width: 5),
            Text('$_totalXp XP',
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_gold, Color(0xFFFFA500), _gold]),
          ),
        ),
      ),
    );
  }

  // ── Hero — fixed 90 px ────────────────────────────────────────────────────

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) => SizedBox(
        height: 90,
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, _blue, _blueMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
          Positioned.fill(child: CustomPaint(painter: _ShimmerPainter(_shimmer.value))),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(size: const Size(double.infinity, 24), painter: _WavePainter()),
          ),
          Positioned(
            left: 20, right: 20, bottom: 14,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: const Text('VR QUIZ ARENA',
                    style: TextStyle(color: _gold, fontSize: 9,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
              const SizedBox(width: 10),
              Text('${_totalXp} XP earned',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Config panel ───────────────────────────────────────────────────────────

  Widget _buildConfigPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(top: BorderSide(color: _gold, width: 2.5)),
        boxShadow: [
          BoxShadow(color: _navyMid.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel(label: 'QUIZ SETTINGS'),
        const SizedBox(height: 16),

        // ── Character selection ────────────────────────────────────────
        const Text('Character',
            style: TextStyle(color: _textSub, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppConstants.characters.entries.map((entry) {
              final info     = entry.value;
              final selected = _selectedCharacter == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCharacter = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _navyMid.withValues(alpha: 0.08) : _inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _navyMid : _textSub.withValues(alpha: 0.2),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? _navyMid.withValues(alpha: 0.12) : _textSub.withValues(alpha: 0.08),
                          border: Border.all(
                            color: selected ? _navyMid.withValues(alpha: 0.5) : _textSub.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(_initials(info.name),
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold,
                                  color: selected ? _navyMid : _textSub)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.id == 'citizen' ? 'Historian' : info.id.toUpperCase(),
                        style: TextStyle(
                            color: selected ? _navyMid : _textSub,
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // ── Quiz type ──────────────────────────────────────────────────
        const Text('Quiz Type',
            style: TextStyle(color: _textSub, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _quizTypes.map((type) {
            final sel = _selectedType == type['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? _navyMid : _inputBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? _navyMid : _textSub.withValues(alpha: 0.2),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Text(type['label']!,
                    style: TextStyle(
                        color: sel ? Colors.white : _textSub,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 12)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ── Difficulty ─────────────────────────────────────────────────
        const Text('Difficulty',
            style: TextStyle(color: _textSub, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: _difficulties.map((diff) {
            final sel    = _selectedDifficulty == diff['id'];
            final dColor = _diffColor(diff['id']!);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDifficulty = diff['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: sel ? dColor.withValues(alpha: 0.08) : _inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? dColor : _textSub.withValues(alpha: 0.2),
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: dColor),
                      ),
                      const SizedBox(height: 5),
                      Text(diff['label']!,
                          style: TextStyle(
                              color: sel ? dColor : _textSub,
                              fontSize: 11,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                    ]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── Quiz content ───────────────────────────────────────────────────────────

  Widget _buildQuizContent() {
    final quiz = _currentQuiz!;
    final char = AppConstants.characters[quiz.characterId]!;
    final borderColor = _hasAnswered
        ? (_answeredCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828))
        : _gold;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.8), width: 2.5)),
        boxShadow: [
          BoxShadow(color: _navyMid.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _navyMid.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _navyMid.withValues(alpha: 0.1),
                border: Border.all(color: _navyMid.withValues(alpha: 0.3), width: 1),
              ),
              child: Center(
                child: Text(_initials(char.name),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navyMid)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(char.name,
                    style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  '${_selectedType.replaceAll('_', ' ').toUpperCase()}  •  ${_selectedDifficulty.toUpperCase()}',
                  style: const TextStyle(color: _textSub, fontSize: 11),
                ),
              ]),
            ),
            // XP badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withValues(alpha: 0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: _goldDeep, size: 13),
                const SizedBox(width: 3),
                Text('${quiz.xpReward} XP',
                    style: const TextStyle(color: _navyMid, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // VR title
            if (quiz.quizType == 'vr_challenge') ...[
              Text(quiz.title ?? '',
                  style: const TextStyle(color: _textMain, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
            ],

            // Question
            if (quiz.question != null || quiz.description != null) ...[
              Text(quiz.question ?? quiz.description ?? '',
                  style: const TextStyle(color: _textMain, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
            ],

            // Hint
            if (quiz.hint != null && !_hasAnswered) ...[
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withValues(alpha: 0.35)),
                ),
                child: Row(children: [
                  const Icon(Icons.lightbulb_outline, color: _goldDeep, size: 16),
                  const SizedBox(width: 6),
                  const Text('Hint: ',
                      style: TextStyle(color: _navyMid, fontWeight: FontWeight.w700, fontSize: 13)),
                  Expanded(
                    child: Text(quiz.hint!,
                        style: const TextStyle(color: _textSub, fontSize: 13)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            if (!_hasAnswered) _buildAnswerInput(quiz),
            if (_hasAnswered)  _buildResult(quiz),
          ]),
        ),
      ]),
    );
  }

  // ── Answer input (logic unchanged) ────────────────────────────────────────

  Widget _buildAnswerInput(QuizQuestion quiz) {
    switch (quiz.quizType) {
      case 'multiple_choice':
        return Column(
          children: (quiz.options ?? []).map((opt) {
            final letter = opt.substring(0, 1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _answerOption(
                label: opt,
                onTap: _isSubmitting ? null : () => _submitAnswer(letter),
                isSelected: _selectedAnswer == letter,
                disabled: _isSubmitting,
              ),
            );
          }).toList(),
        );

      case 'true_false':
        return Row(children: [
          Expanded(
            child: _answerOption(
              label: 'TRUE',
              icon: Icons.check_circle_outline,
              onTap: _isSubmitting ? null : () => _submitAnswer(true),
              isSelected: _selectedAnswer == true,
              color: const Color(0xFF2E7D32),
              disabled: _isSubmitting,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _answerOption(
              label: 'FALSE',
              icon: Icons.cancel_outlined,
              onTap: _isSubmitting ? null : () => _submitAnswer(false),
              isSelected: _selectedAnswer == false,
              color: const Color(0xFFC62828),
              disabled: _isSubmitting,
            ),
          ),
        ]);

      case 'fill_blank':
        final ctrl = TextEditingController();
        return Column(children: [
          TextField(
            controller: ctrl,
            style: const TextStyle(color: _textMain, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Type your answer...',
              hintStyle: const TextStyle(color: _textSub, fontSize: 13),
              prefixIcon: const Icon(Icons.edit_outlined, color: _textSub, size: 18),
              filled: true,
              fillColor: _inputBg,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _textSub.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _navyMid, width: 1.5)),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Submit Answer',
            icon: Icons.check,
            isLoading: _isSubmitting,
            onPressed: () => _submitAnswer(ctrl.text.trim()),
          ),
        ]);

      case 'vr_challenge':
        return Column(
          children: (quiz.choices ?? []).map((choice) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _answerOption(
              label: choice.text,
              onTap: _isSubmitting ? null : () => _submitAnswer(choice.correct),
              isSelected: false,
              disabled: _isSubmitting,
            ),
          )).toList(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _answerOption({
    required String label,
    required VoidCallback? onTap,
    required bool isSelected,
    IconData? icon,
    Color? color,
    bool disabled = false,
  }) {
    final activeColor = color ?? _navyMid;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.08) : _inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : _textSub.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            if (icon != null) ...[
              Icon(icon, color: isSelected ? activeColor : _textSub, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: isSelected ? activeColor : _textMain,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 15)),
            ),
            if (isSelected)
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ]),
        ),
      ),
    );
  }

  // ── Result (logic unchanged) ───────────────────────────────────────────────

  Widget _buildResult(QuizQuestion quiz) {
    final correct = _answeredCorrect;
    final resultColor = correct ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Result banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: resultColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: resultColor.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: resultColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: resultColor, size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                correct ? 'Correct!  +${_result?.xpEarned ?? 0} XP' : 'Incorrect',
                style: TextStyle(color: resultColor, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              if (_result != null)
                Text(
                  'Accuracy: ${_result!.accuracy.toStringAsFixed(1)}%  |  Total XP: ${_result!.totalXp}',
                  style: const TextStyle(color: _textSub, fontSize: 12),
                ),
            ]),
          ),
        ]),
      ),

      // Explanation
      if (quiz.explanation != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.5), width: 1.5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.menu_book_outlined, color: _navyMid, size: 15),
              SizedBox(width: 6),
              Text('Explanation',
                  style: TextStyle(color: _navyMid, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Text(quiz.explanation!,
                style: const TextStyle(color: _textSub, height: 1.5, fontSize: 13)),
          ]),
        ),
      ],

      // VR feedback
      if (quiz.quizType == 'vr_challenge') ...[
        const SizedBox(height: 8),
        ...(quiz.choices ?? []).where((c) => c.correct == correct).map((c) => Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _inputBg, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _textSub.withValues(alpha: 0.15)),
              ),
              child: Text(c.feedback, style: const TextStyle(color: _textSub, fontSize: 13)),
            )),
      ],

      const SizedBox(height: 16),
      GradientButton(
        label: 'Next Question',
        icon: Icons.arrow_forward,
        onPressed: _generateQuiz,
        isLoading: _isLoading,
      ),
    ]);
  }

  // ── Leaderboard button ─────────────────────────────────────────────────────

  Widget _buildLeaderboardButton() {
    return GestureDetector(
      onTap: _showLeaderboard,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.6), width: 2)),
          boxShadow: [BoxShadow(color: _navyMid.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                  colors: [Color(0xFF0A4FA3), _navy], center: Alignment(-0.3, -0.3)),
              border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1),
              boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.15), blurRadius: 8)],
            ),
            child: const Icon(Icons.emoji_events_outlined, color: _gold, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('View Leaderboard',
                  style: TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 14)),
              Text('See top XP earners',
                  style: TextStyle(color: _textSub, fontSize: 12)),
            ]),
          ),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _inputBg),
            child: const Icon(Icons.chevron_right, color: _textSub, size: 18),
          ),
        ]),
      ),
    );
  }

  // ── Leaderboard sheet (logic unchanged) ───────────────────────────────────

  Future<void> _showLeaderboard() async {
    try {
      final data = await _api.getLeaderboard();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [Color(0xFF0A4FA3), _navy], center: Alignment(-0.3, -0.3)),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.2), blurRadius: 8)],
                ),
                child: const Icon(Icons.emoji_events_rounded, color: _gold, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Quiz Leaderboard',
                  style: TextStyle(color: _textMain, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),

            if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No scores yet. Play some quizzes!',
                    style: TextStyle(color: _textSub)),
              )
            else
              ...data.take(10).toList().asMap().entries.map((e) {
                final entry = e.value as Map<String, dynamic>;
                final rank  = e.key + 1;
                final medalColors = [
                  Colors.amber.shade600,
                  Colors.blueGrey.shade400,
                  Colors.brown.shade400,
                ];
                final rankColor = rank <= 3 ? medalColors[rank - 1] : _textSub;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? medalColors[rank - 1].withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rank <= 3
                          ? medalColors[rank - 1].withValues(alpha: 0.4)
                          : _textSub.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: rankColor.withValues(alpha: 0.15)),
                      child: Center(
                        child: Text('$rank',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: rankColor, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry['session_id']?.toString() ?? '',
                          style: const TextStyle(color: _textMain, fontWeight: FontWeight.w600)),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: _gold, size: 14),
                        const SizedBox(width: 3),
                        Text('${entry['xp']} XP',
                            style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                      Text('${entry['accuracy']}% accuracy',
                          style: const TextStyle(color: _textSub, fontSize: 11)),
                    ]),
                  ]),
                );
              }),
          ]),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Color(0xFF002D72), fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 2.5)),
      ]);
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;
    p.color = const Color(0xFFFFD700).withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 1.05, -10), size.width * 0.55, p);
    p.color = const Color(0xFF48CAE4).withValues(alpha: 0.09);
    canvas.drawCircle(Offset(-20, size.height * 1.5), size.width * 0.5, p);
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.03);
    p.strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0), Offset(size.width * i / 6 + 40, size.height), p);
    }
    final dot = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(Offset(size.width - 20 - i * 20.0, 12 + j * 20.0), 1.6, dot);
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
      begin: Alignment(progress - 1, 0), end: Alignment(progress, 0),
      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.04), Colors.transparent],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF5F8FF)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.30);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}