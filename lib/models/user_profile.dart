class UserProfile {
  final String subject;
  final String grade;
  final String learningMode;
  final String language;

  const UserProfile({
    required this.subject,
    required this.grade,
    required this.learningMode,
    required this.language,
  });

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

    return '$grade student, $subject, $learningMode mode. $modeDesc $langHint';
  }

  static const UserProfile defaults = UserProfile(
    subject: 'Mathematics',
    grade: 'Class 8',
    learningMode: 'Standard',
    language: 'English',
  );
}
