import 'dart:io';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/quiz_question.dart';

class GeminiService {
  final GenerativeModel model;

  GeminiService()
      : model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.5-flash', // The current stable 2026 model
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  // Helper for text-only calls (like the quiz)
  final GenerativeModel _jsonModel = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  final GenerativeModel _textModel = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
  );

  ChatSession? _chatSession;

  void startNewChat(String systemPrompt) {
    _chatSession = _textModel.startChat(history: [
      Content.text(systemPrompt),
      Content.model([TextPart("Understood. I am InclusiLearn, your adaptive AI tutor. I will follow your student profile rules strictly. How can I help you today?")]),
    ]);
  }

  String _handleError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('quota') || errorStr.contains('429')) {
      return "⚠️ **AI is taking a break!**\n\nThe free tier quota has been reached. Please wait a minute or two and try again. Each student gets a limited number of requests per minute.";
    }

    if (errorStr.contains('api_key') || errorStr.contains('invalid')) {
      return "❌ **API Key Error**\n\nPlease check your .env file and ensure your GEMINI_API_KEY is correct and active.";
    } else if (errorStr.contains('connection') || errorStr.contains('socket')) {
      return "🌐 **Connection Issue**\n\nPlease check your internet connection and try again.";
    }
    return "😔 **Something went wrong**\n\nI couldn't process that right now. Please try again in a moment.";
  }

  Future<String> askFollowUp(String message) async {
    if (_chatSession == null) {
      return "Please start a session first by uploading a problem.";
    }
    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't process that. Could you rephrase?";
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> solveProblem({
    required String subject,
    required String userProfile,
    required String board,
    File? image,
    String? textInput,
  }) async {
    try {
      final parts = <Part>[];

      if (image != null) {
        final bytes = await image.readAsBytes();
        parts.add(InlineDataPart('image/jpeg', bytes));
      }

      final promptText = '''
You are InclusiLearn, an expert inclusive AI tutor for Indian school students (Class 6-10).

Student Profile: $userProfile
Board: $board
Subject: $subject

ADAPTATION RULES BASED ON LEARNING MODE:
- If "Dyslexia-Friendly": Use short sentences, clear bullet points, and **BOLD** key terms. Break down complex words.
- If "Visually Impaired": Provide extremely descriptive verbal explanations. Describe any diagrams or math symbols in words (e.g., "x squared" instead of just writing x²). Focus on narration-friendly text.
- If "Simplified": Use very simple language, relatable analogies, and avoid technical jargon unless explained simply.
- If "Standard": Provide clear, academic but accessible explanations.

CORE TASK:
- Analyze the input (image and/or text). 
- Provide a step-by-step solution or explanation.
- Be encouraging and patient.
- If the input is not educational, politely redirect the student.

Response should be in Markdown.
''';

      parts.add(TextPart(promptText));

      if (textInput != null && textInput.isNotEmpty) {
        parts.add(TextPart(textInput));
      }

      final content = [Content.multi(parts)];

      final response = await _textModel.generateContent(content);

      return response.text ?? "Sorry, I couldn't process that image. Please try again with a clearer photo.";
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<QuizQuestion>> generateQuiz(String previousExplanation) async {
    try {
      final prompt = '''
Based on this educational explanation:
"$previousExplanation"

Generate 3 multiple-choice questions to test the student's understanding.
Return ONLY a JSON array of objects with this structure:
[
  {
    "question": "string",
    "options": ["string", "string", "string", "string"],
    "correctIndex": int,
    "explanation": "Brief explanation of why the answer is correct"
  }
]
''';

      final response = await _jsonModel.generateContent([Content.text(prompt)]);
      final String? jsonString = response.text;
      
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => QuizQuestion.fromJson(item)).toList();
    } catch (e) {
      print("Quiz generation error: $e");
      return [];
    }
  }

  Future<String> analyzeClassroomTrends(List<String> sessionSummaries) async {
    try {
      final prompt = '''
You are an Educational Data Analyst. Analyze these student session summaries anonymously:
${sessionSummaries.join("\n---\n")}

Provide a "Teacher Difficulty Report" that includes:
1. **Top 3 Hurdles**: Specific topics or concepts that multiple students are struggling with.
2. **Classroom Sentiment**: Are students feeling overwhelmed, confused, or curious?
3. **Actionable Teaching Tips**: Specific ways the teacher can re-explain these concepts in class.

Response should be in Markdown, professional but encouraging.
''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      return response.text ?? "No trends identified yet. Keep teaching!";
    } catch (e) {
      return _handleError(e);
    }
  }
}