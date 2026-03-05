import 'package:flutter/material.dart';
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

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _api = ApiService();

  String _selectedCharacter = 'king';
  String _selectedType      = 'multiple_choice';
  String _selectedDifficulty = 'medium';

  QuizQuestion? _currentQuiz;
  bool _isLoading      = false;
  bool _isSubmitting   = false;
  bool _hasAnswered    = false;
  bool _answeredCorrect = false;
  dynamic _selectedAnswer;
  QuizResult? _result;
  int _totalXp = 0;

  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color _pageBg        = Color(0xFFFFFDE7);
  static const Color _cardBg        = Color(0xFFFFFBF0);
  static const Color _surfaceBg     = Color(0xFFFFF9C4);
  static const Color _deepBlue      = Color(0xFF0D47A1);
  static const Color _midBlue       = Color(0xFF1565C0);
  static const Color _hintBlue      = Color(0xFF5C7CBF);
  static const Color _accentYellow  = Color(0xFFFFCA28);
  static const Color _borderYellow  = Color(0xFFE6D96A);
  static const Color _appBarBg      = Color(0xFF0D47A1);

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

  Color _diffColor(String id) {
    switch (id) {
      case 'easy':   return Colors.green.shade600;
      case 'medium': return Colors.orange.shade700;
      case 'hard':   return Colors.red.shade600;
      default:       return _midBlue;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get _sessionId {
    final user = context.read<AuthProvider>().user;
    return user?.username ?? 'quiz_guest';
  }

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
      setState(() {
        _currentQuiz = quiz;
        _isLoading   = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitAnswer(dynamic answer) async {
    if (_currentQuiz == null || _isSubmitting) return;
    setState(() {
      _isSubmitting   = true;
      _selectedAnswer = answer;
    });
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
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFE082)),
        title: const Text(
          'VR Quiz',
          style: TextStyle(
            color: Color(0xFFFFF9C4),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accentYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _accentYellow.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: _accentYellow, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_totalXp XP',
                  style: const TextStyle(
                    color: Color(0xFFFFF9C4),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigPanel(),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Generate New Question',
              icon: Icons.refresh,
              isLoading: _isLoading,
              onPressed: _generateQuiz,
            ),
            const SizedBox(height: 24),
            if (_currentQuiz != null) _buildQuizContent(),
            const SizedBox(height: 16),
            _buildLeaderboardButton(),
          ],
        ),
      ),
    );
  }

  // ── Config panel ───────────────────────────────────────────────────────────

  Widget _buildConfigPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderYellow),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings_outlined,
                    color: _deepBlue, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quiz Settings',
                style: TextStyle(
                  color: _deepBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Character selection ──────────────────────────────────────
          const Text('Character',
              style: TextStyle(color: _hintBlue, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  AppConstants.characters.entries.map((entry) {
                final info     = entry.value;
                final selected = _selectedCharacter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedCharacter = entry.key),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _midBlue.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _midBlue : _borderYellow,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _midBlue.withOpacity(0.15),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          // Initials circle
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? _midBlue.withOpacity(0.15)
                                  : const Color(0xFFE3F2FD),
                              border: Border.all(
                                color: selected
                                    ? _midBlue.withOpacity(0.5)
                                    : _borderYellow,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _initials(info.name),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? _midBlue : _deepBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            info.id == 'citizen'
                                ? 'Historian'
                                : info.id.toUpperCase(),
                            style: TextStyle(
                              color:
                                  selected ? _midBlue : _hintBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── Quiz type ────────────────────────────────────────────────
          const Text('Quiz Type',
              style: TextStyle(color: _hintBlue, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quizTypes.map((type) {
              final sel = _selectedType == type['id'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedType = type['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel
                        ? _accentYellow.withOpacity(0.18)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? _deepBlue : _borderYellow,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    type['label']!,
                    style: TextStyle(
                      color: sel ? _deepBlue : _hintBlue,
                      fontWeight:
                          sel ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ── Difficulty ───────────────────────────────────────────────
          const Text('Difficulty',
              style: TextStyle(color: _hintBlue, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: _difficulties.map((diff) {
              final sel    = _selectedDifficulty == diff['id'];
              final dColor = _diffColor(diff['id']!);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedDifficulty = diff['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? dColor.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? dColor : _borderYellow,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Coloured dot replaces emoji
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diff['label']!,
                            style: TextStyle(
                              color: sel ? dColor : _hintBlue,
                              fontSize: 11,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Quiz content ───────────────────────────────────────────────────────────

  Widget _buildQuizContent() {
    final quiz = _currentQuiz!;
    final char = AppConstants.characters[quiz.characterId]!;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasAnswered
              ? (_answeredCorrect
                  ? Colors.green.shade400
                  : Colors.red.shade400)
              : _borderYellow,
          width: _hasAnswered ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _midBlue.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                    color: _borderYellow.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                // Initials avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE3F2FD),
                    border: Border.all(
                        color: _midBlue.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      _initials(char.name),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _deepBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        char.name,
                        style: const TextStyle(
                          color: _deepBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_selectedType.replaceAll('_', ' ').toUpperCase()}  •  ${_selectedDifficulty.toUpperCase()}  •  ${quiz.xpReward} XP',
                        style: const TextStyle(
                            color: _hintBlue, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // XP badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accentYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _accentYellow.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: _deepBlue, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${quiz.xpReward} XP',
                        style: const TextStyle(
                          color: _deepBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VR title
                if (quiz.quizType == 'vr_challenge') ...[
                  Text(
                    quiz.title ?? '',
                    style: const TextStyle(
                      color: _deepBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Question
                if (quiz.question != null ||
                    quiz.description != null) ...[
                  Text(
                    quiz.question ?? quiz.description ?? '',
                    style: const TextStyle(
                      color: _deepBlue,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Hint
                if (quiz.hint != null && !_hasAnswered) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accentYellow.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _accentYellow.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: _deepBlue, size: 16),
                        const SizedBox(width: 6),
                        const Text('Hint: ',
                            style: TextStyle(
                                color: _deepBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Expanded(
                          child: Text(
                            quiz.hint!,
                            style: const TextStyle(
                                color: _hintBlue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (!_hasAnswered) _buildAnswerInput(quiz),
                if (_hasAnswered)  _buildResult(quiz),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Answer input ───────────────────────────────────────────────────────────

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
        return Row(
          children: [
            Expanded(
              child: _answerOption(
                label: 'TRUE',
                icon: Icons.check_circle_outline,
                onTap: _isSubmitting ? null : () => _submitAnswer(true),
                isSelected: _selectedAnswer == true,
                color: Colors.green.shade600,
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
                color: Colors.red.shade600,
                disabled: _isSubmitting,
              ),
            ),
          ],
        );

      case 'fill_blank':
        final ctrl = TextEditingController();
        return Column(
          children: [
            TextFormField(
              controller: ctrl,
              style: const TextStyle(color: _deepBlue, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                hintStyle:
                    const TextStyle(color: _hintBlue, fontSize: 13),
                prefixIcon: const Icon(Icons.edit_outlined,
                    color: _hintBlue),
                filled: true,
                fillColor: _surfaceBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _borderYellow),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: _deepBlue, width: 2),
                ),
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
          ],
        );

      case 'vr_challenge':
        return Column(
          children: (quiz.choices ?? []).map((choice) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _answerOption(
                label: choice.text,
                onTap: _isSubmitting
                    ? null
                    : () => _submitAnswer(choice.correct),
                isSelected: false,
                disabled: _isSubmitting,
              ),
            );
          }).toList(),
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
    final activeColor = color ?? _midBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : _borderYellow,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _deepBlue.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    color: isSelected ? activeColor : _hintBlue,
                    size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeColor : _deepBlue,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded,
                    color: activeColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Result ─────────────────────────────────────────────────────────────────

  Widget _buildResult(QuizQuestion quiz) {
    final correct = _answeredCorrect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: correct
                ? Colors.green.withOpacity(0.08)
                : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: correct
                  ? Colors.green.shade400
                  : Colors.red.shade400,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (correct ? Colors.green : Colors.red)
                      .withOpacity(0.12),
                ),
                child: Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color:
                      correct ? Colors.green.shade600 : Colors.red.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      correct
                          ? 'Correct!  +${_result?.xpEarned ?? 0} XP'
                          : 'Incorrect',
                      style: TextStyle(
                        color: correct
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    if (_result != null)
                      Text(
                        'Accuracy: ${_result!.accuracy.toStringAsFixed(1)}%  |  Total XP: ${_result!.totalXp}',
                        style: const TextStyle(
                            color: _hintBlue, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Explanation
        if (quiz.explanation != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderYellow),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        color: _deepBlue, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Explanation',
                      style: TextStyle(
                        color: _deepBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  quiz.explanation!,
                  style: const TextStyle(
                      color: _hintBlue, height: 1.5, fontSize: 13),
                ),
              ],
            ),
          ),
        ],

        // VR feedback
        if (quiz.quizType == 'vr_challenge') ...[
          const SizedBox(height: 8),
          ...(quiz.choices ?? [])
              .where((c) => c.correct == correct)
              .map(
                (c) => Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: _surfaceBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderYellow),
                  ),
                  child: Text(c.feedback,
                      style: const TextStyle(
                          color: _hintBlue, fontSize: 13)),
                ),
              ),
        ],

        const SizedBox(height: 16),
        GradientButton(
          label: 'Next Question',
          icon: Icons.arrow_forward,
          onPressed: _generateQuiz,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ── Leaderboard button ─────────────────────────────────────────────────────

  Widget _buildLeaderboardButton() {
    return InkWell(
      onTap: _showLeaderboard,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderYellow),
          boxShadow: [
            BoxShadow(
              color: _deepBlue.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  color: _deepBlue, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Leaderboard',
                    style: TextStyle(
                      color: _deepBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'See top XP earners',
                    style: TextStyle(color: _hintBlue, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _hintBlue),
          ],
        ),
      ),
    );
  }

  // ── Leaderboard sheet ──────────────────────────────────────────────────────

  Future<void> _showLeaderboard() async {
    try {
      final data = await _api.getLeaderboard();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: _cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _borderYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: _deepBlue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Quiz Leaderboard',
                    style: TextStyle(
                      color: _deepBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No scores yet. Play some quizzes!',
                    style: TextStyle(color: _hintBlue),
                  ),
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
                  final rankColor = rank <= 3
                      ? medalColors[rank - 1]
                      : _hintBlue;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? medalColors[rank - 1].withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: rank <= 3
                            ? medalColors[rank - 1].withOpacity(0.4)
                            : _borderYellow,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank circle
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rankColor.withOpacity(0.15),
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rankColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry['session_id']?.toString() ?? '',
                            style: const TextStyle(
                              color: _deepBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: _accentYellow, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  '${entry['xp']} XP',
                                  style: const TextStyle(
                                    color: _deepBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${entry['accuracy']}% accuracy',
                              style: const TextStyle(
                                  color: _hintBlue, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}