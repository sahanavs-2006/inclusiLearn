import 'package:cloud_firestore/cloud_firestore.dart';

class SavedSession {
  final String? id;
  final String subject;
  final String grade;
  final String learningMode;
  final String response;
  final DateTime savedAt;
  final String userId;
  final bool? wasHelpful; // Added for Solution Challenge Impact Tracking

  SavedSession({
    this.id,
    required this.userId,
    required this.subject,
    required this.grade,
    required this.learningMode,
    required this.response,
    required this.savedAt,
    this.wasHelpful,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subject': subject,
        'grade': grade,
        'learningMode': learningMode,
        'response': response,
        'savedAt': Timestamp.fromDate(savedAt),
        'wasHelpful': wasHelpful,
      };

  factory SavedSession.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedSession(
      id: doc.id,
      userId: data['userId'] ?? 'unknown',
      subject: data['subject'] ?? '',
      grade: data['grade'] ?? '',
      learningMode: data['learningMode'] ?? '',
      response: data['response'] ?? '',
      savedAt: (data['savedAt'] as Timestamp).toDate(),
      wasHelpful: data['wasHelpful'],
    );
  }

  /// First ~120 characters of the response as a preview
  String get preview {
    final clean = response.replaceAll(RegExp(r'[*#_]'), '').trim();
    return clean.length > 120 ? '${clean.substring(0, 120)}...' : clean;
  }
}
