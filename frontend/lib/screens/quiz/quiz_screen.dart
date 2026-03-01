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
  String _selectedType = 'multiple_choice';
  String _selectedDifficulty = 'medium';

  QuizQuestion? _currentQuiz;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasAnswered = false;
  bool _answeredCorrect = false;
  dynamic _selectedAnswer;
  QuizResult? _result;
  int _totalXp = 0;

  final List<Map<String, String>> _quizTypes = [
    {'id': 'multiple_choice', 'label': 'Multiple Choice', 'emoji': '🔤'},
    {'id': 'true_false', 'label': 'True / False', 'emoji': '✅'},
    {'id': 'fill_blank', 'label': 'Fill in the Blank', 'emoji': '✏️'},
    {'id': 'vr_challenge', 'label': 'VR Challenge', 'emoji': '🎮'},
  ];

  final List<Map<String, String>> _difficulties = [
    {'id': 'easy', 'label': 'Easy', 'emoji': '🟢'},
    {'id': 'medium', 'label': 'Medium', 'emoji': '🟡'},
    {'id': 'hard', 'label': 'Hard', 'emoji': '🔴'},
  ];

  String get _sessionId {
    final user = context.read<AuthProvider>().user;
    return user?.username ?? 'quiz_guest';
  }

  Future<void> _generateQuiz() async {
    setState(() {
      _isLoading = true;
      _currentQuiz = null;
      _hasAnswered = false;
      _selectedAnswer = null;
      _result = null;
    });
    try {
      final data = await _api.generateQuiz(
        characterId: _selectedCharacter,
        quizType: _selectedType,
        difficulty: _selectedDifficulty,
        sessionId: _sessionId,
      );
      final quiz = QuizQuestion.fromJson(data, {
        'character_id': _selectedCharacter,
        'quiz_type': _selectedType,
        'difficulty': _selectedDifficulty,
      });
      setState(() {
        _currentQuiz = quiz;
        _isLoading = false;
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
      _isSubmitting = true;
      _selectedAnswer = answer;
    });
    try {
      final data = await _api.submitQuizAnswer(
        sessionId: _sessionId,
        quizType: _selectedType,
        userAnswer: answer,
        correctAnswer: _currentQuiz!.correctAnswer ?? _currentQuiz!.boolAnswer,
        xpReward: _currentQuiz!.xpReward,
        challengeId: _currentQuiz!.challengeId,
      );
      final result = QuizResult.fromJson(data);
      setState(() {
        _result = result;
        _hasAnswered = true;
        _answeredCorrect = result.correct;
        _totalXp = result.totalXp;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('VR Quiz'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_totalXp XP',
                  style: const TextStyle(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.w700),
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
            // Config panel
            _buildConfigPanel(),
            const SizedBox(height: 20),

            // Generate button
            GradientButton(
              label: 'Generate New Question',
              icon: Icons.refresh,
              isLoading: _isLoading,
              onPressed: _generateQuiz,
            ),
            const SizedBox(height: 24),

            // Quiz content
            if (_currentQuiz != null) _buildQuizContent(),

            // Leaderboard link
            const SizedBox(height: 16),
            _buildLeaderboardButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigPanel() {
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
          const Text('Quiz Settings',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 16),

          // Character selection
          const Text('Character',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.characters.entries.map((entry) {
                final info = entry.value;
                final selected = _selectedCharacter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCharacter = entry.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? info.color.withOpacity(0.3)
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? info.color : AppTheme.borderColor,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(info.emoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            info.id == 'citizen' ? 'Historian' : info.id.toUpperCase(),
                            style: TextStyle(
                              color: selected ? info.accentColor : Colors.white54,
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

          // Quiz type
          const Text('Quiz Type',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quizTypes.map((type) {
              final sel = _selectedType == type['id'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type['emoji']!),
                    const SizedBox(width: 4),
                    Text(type['label']!),
                  ],
                ),
                selected: sel,
                onSelected: (_) => setState(() => _selectedType = type['id']!),
                selectedColor: AppTheme.primaryGold.withOpacity(0.3),
                backgroundColor: AppTheme.surfaceDark,
                labelStyle: TextStyle(
                    color: sel ? AppTheme.primaryGold : Colors.white54),
                side: BorderSide(
                    color: sel ? AppTheme.primaryGold : AppTheme.borderColor),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Difficulty
          const Text('Difficulty',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: _difficulties.map((diff) {
              final sel = _selectedDifficulty == diff['id'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedDifficulty = diff['id']!),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.primaryGold.withOpacity(0.2)
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppTheme.primaryGold : AppTheme.borderColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(diff['emoji']!),
                          const SizedBox(height: 2),
                          Text(
                            diff['label']!,
                            style: TextStyle(
                              color: sel ? AppTheme.primaryGold : Colors.white54,
                              fontSize: 11,
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

  Widget _buildQuizContent() {
    final quiz = _currentQuiz!;
    final char = AppConstants.characters[quiz.characterId]!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasAnswered
              ? (_answeredCorrect ? Colors.green : Colors.red)
              : char.color.withOpacity(0.5),
          width: _hasAnswered ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: char.color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(char.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        char.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_selectedType.replaceAll('_', ' ').toUpperCase()} • ${_selectedDifficulty.toUpperCase()} • ⭐ ${quiz.xpReward} XP',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
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
                // Question
                if (quiz.quizType == 'vr_challenge') ...[
                  Text(
                    quiz.title ?? '',
                    style: const TextStyle(
                        color: AppTheme.primaryGold,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                ],
                if (quiz.question != null || quiz.description != null) ...[
                  Text(
                    quiz.question ?? quiz.description ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                ],
                if (quiz.hint != null && !_hasAnswered)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.saffron.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('💡 Hint: ',
                            style: TextStyle(color: AppTheme.saffron)),
                        Expanded(
                          child: Text(
                            quiz.hint!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Answers based on type
                const SizedBox(height: 8),
                if (!_hasAnswered) _buildAnswerInput(quiz),
                if (_hasAnswered) _buildResult(quiz),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                label: '✅  TRUE',
                onTap: _isSubmitting ? null : () => _submitAnswer(true),
                isSelected: _selectedAnswer == true,
                color: Colors.green,
                disabled: _isSubmitting,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _answerOption(
                label: '❌  FALSE',
                onTap: _isSubmitting ? null : () => _submitAnswer(false),
                isSelected: _selectedAnswer == false,
                color: Colors.red,
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
              decoration: const InputDecoration(
                hintText: 'Type your answer...',
                prefixIcon: Icon(Icons.edit),
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
                onTap: _isSubmitting ? null : () => _submitAnswer(choice.correct),
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
    Color? color,
    bool disabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppTheme.primaryGold).withOpacity(0.2)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppTheme.primaryGold)
                  : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? (color ?? AppTheme.primaryGold) : Colors.white,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

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
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: correct ? Colors.green : Colors.red,
            ),
          ),
          child: Row(
            children: [
              Text(correct ? '🎉' : '❌',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      correct ? 'Correct! +${_result?.xpEarned ?? 0} XP' : 'Incorrect',
                      style: TextStyle(
                        color: correct ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    if (_result != null)
                      Text(
                        'Accuracy: ${_result!.accuracy.toStringAsFixed(1)}% | Total XP: ${_result!.totalXp}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
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
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📖 Explanation',
                    style: TextStyle(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  quiz.explanation!,
                  style: const TextStyle(
                      color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ],

        // VR Challenge feedback
        if (quiz.quizType == 'vr_challenge') ...[
          const SizedBox(height: 8),
          ...(quiz.choices ?? []).where((c) => c.correct == correct).map(
                (c) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(c.feedback,
                      style: const TextStyle(color: Colors.white70)),
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

  Widget _buildLeaderboardButton() {
    return InkWell(
      onTap: () => _showLeaderboard(),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('View Leaderboard',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('See top XP earners',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Future<void> _showLeaderboard() async {
    try {
      final data = await _api.getLeaderboard();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆 Quiz Leaderboard',
                  style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (data.isEmpty)
                const Text('No scores yet. Play some quizzes!',
                    style: TextStyle(color: Colors.white54))
              else
                ...data.take(10).toList().asMap().entries.map((e) {
                  final entry = e.value as Map<String, dynamic>;
                  final rank = e.key + 1;
                  final medals = ['🥇', '🥈', '🥉'];
                  return ListTile(
                    leading: Text(rank <= 3 ? medals[rank - 1] : '$rank.',
                        style: const TextStyle(fontSize: 20)),
                    title: Text(
                      entry['session_id']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entry['xp']} XP',
                          style: const TextStyle(
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${entry['accuracy']}% accuracy',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
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
