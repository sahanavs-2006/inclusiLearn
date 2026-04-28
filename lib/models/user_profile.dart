class UserProfile {
  final String name;
  final String subject;
  final String grade;
  final String learningMode;
  final String language;
  
  // Gamification Fields
  final int points;
  final List<String> badges;
  final int streak;
  final String lastActiveDate; // YYYY-MM-DD

  const UserProfile({
    required this.name,
    required this.subject,
    required this.grade,
    required this.learningMode,
    required this.language,
    this.points = 0,
    this.badges = const [],
    this.streak = 0,
    this.lastActiveDate = '',
  });

  int get buddyLevel {
    if (points >= 1000) return 4;
    if (points >= 500) return 3;
    if (points >= 100) return 2;
    return 1;
  }

  String get buddyStatus {
    return switch (buddyLevel) {
      4 => 'Master Buddy',
      3 => 'Junior Explorer',
      2 => 'Learning Sprout',
      _ => 'New Seed',
    };
  }

  UserProfile copyWith({
    String? name,
    String? subject,
    String? grade,
    String? learningMode,
    String? language,
    int? points,
    List<String>? badges,
    int? streak,
    String? lastActiveDate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      learningMode: learningMode ?? this.learningMode,
      language: language ?? this.language,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  /// Builds the dynamic prompt string sent to Gemini
  String toPromptString() {
    final modeDesc = switch (learningMode) {
      'Dyslexia-Friendly' =>
        'Use short sentences, bullet points, bold key terms. Avoid dense paragraphs.',
      'Visually Impaired' =>
        'Describe everything verbally in great detail. Avoid phrases like "as you can see". Use numbered steps.',
      'Simplified' =>
        'Use extremely simple words. Explain as if talking to a young child. Use analogies.',
      _ => 'Use clear, standard educational language.',
    };

    final langHint =
        'Respond entirely in $language. If it is an Indian language, use the native script but keep technical terms like "Photosynthesis" in English brackets if needed.';

    return 'Student name is $name. $grade student, $subject, $learningMode mode. $modeDesc $langHint';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'grade': grade,
      'learningMode': learningMode,
      'language': language,
      'points': points,
      'badges': badges,
      'streak': streak,
      'lastActiveDate': lastActiveDate,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? 'Student',
      subject: map['subject'] ?? 'Mathematics',
      grade: map['grade'] ?? 'Class 8',
      learningMode: map['learningMode'] ?? 'Standard',
      language: map['language'] ?? 'English',
      points: map['points'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      streak: map['streak'] ?? 0,
      lastActiveDate: map['lastActiveDate'] ?? '',
    );
  }

  static const UserProfile defaults = UserProfile(
    name: 'Student',
    subject: 'Mathematics',
    grade: 'Class 8',
    learningMode: 'Standard',
    language: 'English',
    points: 0,
    badges: [],
    streak: 0,
    lastActiveDate: '',
  );
}
