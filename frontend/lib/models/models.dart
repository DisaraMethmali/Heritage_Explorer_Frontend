class User {
  final String userId;
  final String username;
  final String email;
  final String fullName;
  final String expertiseLevel;
  final String ageGroup;
  final String? lastLogin;
  final int totalSessions;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.fullName,
    required this.expertiseLevel,
    required this.ageGroup,
    this.lastLogin,
    required this.totalSessions,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['user_id'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        fullName: json['full_name'] ?? '',
        expertiseLevel: json['expertise_level'] ?? 'tourist',
        ageGroup: json['age_group'] ?? 'adult',
        lastLogin: json['last_login'],
        totalSessions: json['total_sessions'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'email': email,
        'full_name': fullName,
        'expertise_level': expertiseLevel,
        'age_group': ageGroup,
      };
}

class AuthSession {
  final String token;
  final User user;

  AuthSession({required this.token, required this.user});
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? characterId;
  final String? characterName;
  final double? confidence;
  final String? topic;
  final String? intent;
  final List<VrSite>? vrSites;
  final FolkloreData? folklore;
  final String? causalChain;
  final String? criticalQuestion;
  final AnomalyData? anomaly;
  bool isSpeaking;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.characterId,
    this.characterName,
    this.confidence,
    this.topic,
    this.intent,
    this.vrSites,
    this.folklore,
    this.causalChain,
    this.criticalQuestion,
    this.anomaly,
    this.isSpeaking = false,
  });

  factory ChatMessage.fromApiResponse(Map<String, dynamic> json, String question) {
    List<VrSite>? vrSites;
    if (json['vr_sites'] != null) {
      vrSites = (json['vr_sites'] as List)
          .map((s) => VrSite.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    FolkloreData? folklore;
    if (json['folklore'] != null && json['folklore'] is Map) {
      folklore = FolkloreData.fromJson(json['folklore'] as Map<String, dynamic>);
    }

    AnomalyData? anomaly;
    if (json['anomaly'] != null && json['anomaly'] is Map) {
      anomaly = AnomalyData.fromJson(json['anomaly'] as Map<String, dynamic>);
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['answer'] ?? '',
      isUser: false,
      timestamp: DateTime.now(),
      characterId: json['character_id'] ?? json['character'],
      characterName: json['character_name'] ?? json['character'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      topic: json['topic'],
      intent: json['intent'],
      vrSites: vrSites,
      folklore: folklore,
      causalChain: json['causal_chain'],
      criticalQuestion: json['critical_question'],
      anomaly: anomaly,
    );
  }
}

class VrSite {
  final String siteId;
  final String name;
  final String type;
  final String description;
  final String vrExperience;

  VrSite({
    required this.siteId,
    required this.name,
    required this.type,
    required this.description,
    required this.vrExperience,
  });

  factory VrSite.fromJson(Map<String, dynamic> json) => VrSite(
        siteId: json['site_id'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '',
        description: json['description'] ?? '',
        vrExperience: json['vr_experience'] ?? '',
      );
}

class FolkloreData {
  final String legendTitle;
  final String legend;
  final String historicalFact;

  FolkloreData({
    required this.legendTitle,
    required this.legend,
    required this.historicalFact,
  });

  factory FolkloreData.fromJson(Map<String, dynamic> json) => FolkloreData(
        legendTitle: json['legend_title'] ?? '',
        legend: json['legend'] ?? '',
        historicalFact: json['historical_fact'] ?? '',
      );
}

class AnomalyData {
  final bool detected;
  final String correction;

  AnomalyData({required this.detected, required this.correction});

  factory AnomalyData.fromJson(Map<String, dynamic> json) => AnomalyData(
        detected: json['detected'] ?? false,
        correction: json['correction'] ?? '',
      );
}

class HistoryRecord {
  final String msgId;
  final String sessionId;
  final String characterId;
  final String characterName;
  final String question;
  final String answer;
  final String topic;
  final String intent;
  final double confidence;
  final DateTime timestamp;

  HistoryRecord({
    required this.msgId,
    required this.sessionId,
    required this.characterId,
    required this.characterName,
    required this.question,
    required this.answer,
    required this.topic,
    required this.intent,
    required this.confidence,
    required this.timestamp,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
        msgId: json['msg_id'] ?? '',
        sessionId: json['session_id'] ?? '',
        characterId: json['character_id'] ?? '',
        characterName: json['character_name'] ?? '',
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
        topic: json['topic'] ?? '',
        intent: json['intent'] ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class QuizQuestion {
  final String quizType;
  final String characterId;
  final String difficulty;
  final int xpReward;

  // Multiple choice
  final String? question;
  final List<String>? options;
  final String? correctAnswer;
  final String? explanation;

  // True/False
  final bool? boolAnswer;

  // Fill blank
  final String? hint;

  // VR Challenge
  final String? challengeId;
  final String? title;
  final String? description;
  final List<QuizChoice>? choices;

  QuizQuestion({
    required this.quizType,
    required this.characterId,
    required this.difficulty,
    required this.xpReward,
    this.question,
    this.options,
    this.correctAnswer,
    this.explanation,
    this.boolAnswer,
    this.hint,
    this.challengeId,
    this.title,
    this.description,
    this.choices,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json, Map<String, dynamic> params) {
    final quiz = json['quiz'] as Map<String, dynamic>? ?? json;
    final quizType = params['quiz_type'] ?? quiz['quiz_type'] ?? 'multiple_choice';

    List<QuizChoice>? choices;
    if (quiz['choices'] != null) {
      choices = (quiz['choices'] as List)
          .map((c) => QuizChoice.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    List<String>? options;
    if (quiz['options'] != null) {
      options = (quiz['options'] as List).map((o) => o.toString()).toList();
    }

    return QuizQuestion(
      quizType: quizType,
      characterId: params['character_id'] ?? '',
      difficulty: params['difficulty'] ?? 'medium',
      xpReward: (quiz['xp_reward'] ?? quiz['xp'] ?? 25) as int,
      question: quiz['question'],
      options: options,
      correctAnswer: quiz['answer']?.toString(),
      explanation: quiz['explanation'],
      boolAnswer: quiz['answer'] is bool ? quiz['answer'] as bool : null,
      hint: quiz['hint'],
      challengeId: quiz['challenge_id'],
      title: quiz['title'],
      description: quiz['description'],
      choices: choices,
    );
  }
}

class QuizChoice {
  final String text;
  final bool correct;
  final String feedback;

  QuizChoice({required this.text, required this.correct, required this.feedback});

  factory QuizChoice.fromJson(Map<String, dynamic> json) => QuizChoice(
        text: json['text'] ?? '',
        correct: json['correct'] ?? false,
        feedback: json['feedback'] ?? '',
      );
}

class QuizResult {
  final bool correct;
  final int xpEarned;
  final int totalXp;
  final double accuracy;

  QuizResult({
    required this.correct,
    required this.xpEarned,
    required this.totalXp,
    required this.accuracy,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? json;
    return QuizResult(
      correct: result['correct'] ?? false,
      xpEarned: result['xp_earned'] ?? 0,
      totalXp: result['total_xp'] ?? 0,
      accuracy: (result['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LeaderboardEntry {
  final String sessionId;
  final int xp;
  final double accuracy;
  final int totalAnswered;

  LeaderboardEntry({
    required this.sessionId,
    required this.xp,
    required this.accuracy,
    required this.totalAnswered,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        sessionId: json['session_id'] ?? '',
        xp: json['xp'] ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        totalAnswered: json['total_answered'] ?? 0,
      );
}
