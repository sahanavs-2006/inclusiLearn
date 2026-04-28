import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'core/gemini_service.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'models/user_profile.dart';
import 'features/profile/profile_screen.dart';
import 'models/saved_session.dart';
import 'core/firestore_service.dart';
import 'features/library/library_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/quiz_question.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Loads the key securely
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InclusiLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _response = "Upload a photo of a math problem or diagram";
  List<Map<String, String>> _messages = []; // [{role: 'user'|'model', text: '...'}]
  bool _isLoading = false;
  UserProfile _profile = UserProfile.defaults;
  bool _isSaved = false;

  late final GeminiService _geminiService;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  final TextEditingController _textController = TextEditingController();
  
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  
  List<QuizQuestion> _quiz = [];
  int _currentQuizIndex = 0;
  bool _isQuizLoading = false;
  int? _selectedOption;
  bool _showExplanation = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();

    _setupTts();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (val) => debugPrint('STT Status: $val'),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _setupTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setSpeechRate(0.45); // Slower, clearer speech
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isPlaying = false);
      debugPrint("TTS Error: $msg");
    });
  }

  Future<void> _speak() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    // Clean markdown symbols so the bot doesn't say "asterisk asterisk"
    String cleanText = _response.replaceAll(RegExp(r'[*#_]'), '');
    
    if (mounted) setState(() => _isPlaying = true);
    await _flutterTts.speak(cleanText);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    if (_isSaved) return;
    final session = SavedSession(
      subject: _profile.subject,
      grade: _profile.grade,
      learningMode: _profile.learningMode,
      response: _response,
      savedAt: DateTime.now(),
    );
    await FirestoreService().saveSession(session);
    if (mounted) {
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📚 Saved to your Library!'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openProfile() async {
    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(currentProfile: _profile),
      ),
    );
    if (updatedProfile != null) {
      setState(() => _profile = updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Profile saved! ${updatedProfile.subject} · ${updatedProfile.grade} · ${updatedProfile.learningMode}'),
          backgroundColor: Colors.indigo,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) _processImage(photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
                if (photo != null) _processImage(photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(XFile imageFile) async {
    setState(() {
      _selectedImage = File(imageFile.path);
      _response = "Analyzing...";
      _isLoading = true;
    });

    final result = await _geminiService.solveProblem(
      subject: _profile.subject,
      userProfile: _profile.toPromptString(),
      board: "Karnataka State Board / CBSE",
      image: _selectedImage,
      textInput: _textController.text.isNotEmpty ? _textController.text : null,
    );

    setState(() {
      _response = result;
      _isLoading = false;
      _isSaved = false; 
      _textController.clear();
      _quiz = []; 
      
      // Start a chat session for follow-ups
      _geminiService.startNewChat(_profile.toPromptString());
      _messages = [{'role': 'model', 'text': result}];
    });
  }

  Future<void> _sendTextOnly() async {
    String text = _textController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _selectedImage = null; // Clear image if sending text-only
    });
    
    if (_messages.isEmpty) {
      // First question (no image)
      final result = await _geminiService.solveProblem(
        subject: _profile.subject,
        userProfile: _profile.toPromptString(),
        board: "Karnataka State Board / CBSE",
        textInput: text,
      );
      setState(() {
        _response = result;
        _isLoading = false;
        _isSaved = false;
        _textController.clear();
        _messages = [{'role': 'model', 'text': result}];
        _quiz = [];
        _geminiService.startNewChat(result);
      });
    } else {
      // Follow-up question
      setState(() {
        _messages.add({'role': 'user', 'text': text});
        _textController.clear();
      });

      final result = await _geminiService.askFollowUp(text);

      setState(() {
        _response = result; // Still update response for TTS/Library
        _messages.add({'role': 'model', 'text': result});
        _isLoading = false;
        _isSaved = false;
        _quiz = []; // Clear quiz on new question
      });
    }
  }

  Future<void> _startQuiz() async {
    setState(() => _isQuizLoading = true);
    final quiz = await _geminiService.generateQuiz(_response);
    setState(() {
      _quiz = quiz;
      _isQuizLoading = false;
      _currentQuizIndex = 0;
      _selectedOption = null;
      _showExplanation = false;
      _score = 0;
    });
  }

  void _submitAnswer(int index) {
    if (_selectedOption != null) return;
    setState(() {
      _selectedOption = index;
      _showExplanation = true;
      if (index == _quiz[_currentQuizIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuizQuestion() {
    if (_currentQuizIndex < _quiz.length - 1) {
      setState(() {
        _currentQuizIndex++;
        _selectedOption = null;
        _showExplanation = false;
      });
    } else {
      // Quiz finished
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Quiz Complete!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text("You scored $_score out of ${_quiz.length}!", style: GoogleFonts.outfit()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _quiz = []);
              },
              child: const Text("Awesome!"),
            ),
          ],
        ),
      );
    }
  }

  void _resetChat() {
    setState(() {
      _messages = [];
      _response = "Upload a photo of a math problem or diagram";
      _selectedImage = null;
      _quiz = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting a new study session!'), backgroundColor: Colors.indigo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'InclusiLearn',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.indigo),
            onPressed: _resetChat,
            tooltip: 'New Chat',
          ),
          if (_response.length > 50 && !_isLoading)
            IconButton(
              icon: Icon(_isPlaying ? Icons.stop_circle : Icons.volume_up_rounded, size: 26),
              color: _isPlaying ? Colors.redAccent : Colors.indigo,
              onPressed: _speak,
              tooltip: _isPlaying ? "Stop Audio" : "Read Aloud",
            ),
          IconButton(
            icon: const Icon(Icons.collections_bookmark_rounded, color: Colors.indigo),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LibraryScreen()),
            ),
            tooltip: 'My Library',
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded, color: Colors.indigo),
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade700, 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5)
                    ),
                  ),
                ),
              ],
            ),
            onPressed: _openProfile,
            tooltip: 'Learning Profile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.3)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty 
                ? _buildWelcomeDashboard()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedImage != null)
                          _buildSelectedImagePreview(),
                        
                        if (_response.length > 50 && !_isLoading)
                          _buildSaveButton(),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _isLoading 
                            ? _buildLoadingState()
                            : Column(
                                children: [
                                  ..._messages.map((m) => _buildMessageBubble(m)),
                                  if (_quiz.isEmpty && _response.length > 50 && !_isLoading)
                                    _buildStartQuizButton(),
                                  if (_quiz.isNotEmpty)
                                    _buildQuizCard(),
                                ],
                              ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomInput(),
    );
  }

  Widget _buildWelcomeDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Hero(
            tag: 'logo',
            child: Container(
              height: 100,
              width: 100,
              child: Image.asset(
                'assets/logo.png',
                color: Colors.indigo.shade300,
                colorBlendMode: BlendMode.srcIn,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Welcome back!",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
          ),
          const SizedBox(height: 8),
          Text(
            "What would you like to learn today?",
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 40),
          // Action Cards
          _buildActionCard(
            title: "Scan Homework",
            subtitle: "Capture a photo of any problem",
            icon: Icons.camera_alt_rounded,
            color: Colors.indigo,
            onTap: _pickImage,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            title: "Voice Query",
            subtitle: "Ask a question with your voice",
            icon: Icons.mic_rounded,
            color: Colors.teal,
            onTap: _listen,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            title: "Study Library",
            subtitle: "Review your saved sessions",
            icon: Icons.collections_bookmark_rounded,
            color: Colors.orange.shade700,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
          ),
          const SizedBox(height: 40),
          // SDG Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSDGBadge("4", "Quality Education", Colors.red.shade700),
              const SizedBox(width: 12),
              _buildSDGBadge("10", "Reduced Inequalities", Colors.pink.shade600),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Built for Google Solution Challenge 2026",
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSDGBadge(String goal, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Text(goal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(width: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(_selectedImage!, height: 250, width: double.infinity, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _isSaved ? null : _saveSession,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: _isSaved ? Colors.teal.shade50 : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isSaved ? Colors.teal.shade200 : Colors.indigo.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                color: _isSaved ? Colors.teal : Colors.indigo,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isSaved ? 'Saved to Library' : 'Save to My Library',
                style: TextStyle(
                  color: _isSaved ? Colors.teal.shade700 : Colors.indigo.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        children: [
          const SizedBox(height: 40),
          CircularProgressIndicator(color: Colors.indigo.shade400, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            "Generating personalized explanation...",
            style: GoogleFonts.outfit(color: Colors.indigo.shade300, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg) {
    bool isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16, left: isUser ? 40 : 0, right: isUser ? 0 : 40),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: isUser ? null : Border.all(color: Colors.indigo.shade50),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: msg['text']!,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.outfit(fontSize: 16, height: 1.6, color: isUser ? Colors.white : Colors.black87),
                h3: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isUser ? Colors.white : Colors.indigo),
                listBullet: TextStyle(fontSize: 16, height: 1.6, color: isUser ? Colors.white : Colors.black87),
                strong: TextStyle(fontWeight: FontWeight.bold, color: isUser ? Colors.white : Colors.indigo),
              ),
            ),
            if (!isUser) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text("Did this help?", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                  _buildFeedbackIcon(Icons.thumb_up_alt_outlined, Colors.green, true),
                  const SizedBox(width: 8),
                  _buildFeedbackIcon(Icons.thumb_down_alt_outlined, Colors.red, false),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackIcon(IconData icon, Color color, bool isPositive) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPositive ? "Glad I could help! 😊" : "Sorry about that! I'll try to improve. ✍️"),
            backgroundColor: color.withOpacity(0.8),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildStartQuizButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: ElevatedButton.icon(
        onPressed: _isQuizLoading ? null : _startQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        icon: _isQuizLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.psychology_alt_rounded),
        label: Text(
          _isQuizLoading ? "Preparing Quiz..." : "Test My Knowledge!",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildQuizCard() {
    final q = _quiz[_currentQuizIndex];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.orange.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${_currentQuizIndex + 1} of ${_quiz.length}",
                style: GoogleFonts.outfit(color: Colors.orange.shade900, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text("Score: $_score", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            q.question,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ...List.generate(q.options.length, (i) {
            final isCorrect = i == q.correctIndex;
            final isSelected = i == _selectedOption;
            Color btnColor = Colors.white;
            if (_showExplanation) {
              if (isCorrect) btnColor = Colors.green.shade100;
              else if (isSelected) btnColor = Colors.red.shade100;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _submitAnswer(i),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _showExplanation && isCorrect 
                        ? Colors.green 
                        : (_showExplanation && isSelected ? Colors.red : Colors.orange.shade100),
                      width: isSelected || (_showExplanation && isCorrect) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        String.fromCharCode(65 + i) + ".",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(q.options[i], style: GoogleFonts.outfit(fontSize: 15)),
                      ),
                      if (_showExplanation && isCorrect) const Icon(Icons.check_circle, color: Colors.green),
                      if (_showExplanation && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_showExplanation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text(
                "💡 ${q.explanation}",
                style: GoogleFonts.outfit(fontStyle: FontStyle.italic, color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextQuizQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentQuizIndex < _quiz.length - 1 ? "Next Question" : "Finish Quiz",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_a_photo_rounded, color: Colors.indigo),
                onPressed: _isLoading ? null : _pickImage,
                tooltip: 'Upload Image',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendTextOnly(),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, child) {
                  return CircleAvatar(
                    backgroundColor: value.text.isNotEmpty ? Colors.indigo : Colors.grey.shade200,
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.send_rounded,
                        color: value.text.isNotEmpty || _isListening ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                      onPressed: _isListening
                          ? _listen
                          : (value.text.isNotEmpty && !_isLoading ? _sendTextOnly : _listen),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}