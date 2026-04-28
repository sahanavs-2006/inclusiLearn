import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/gemini_service.dart';
import '../../core/firestore_service.dart';
import '../../models/saved_session.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final GeminiService _geminiService = GeminiService();
  String _report = "Click the button below to generate a classroom difficulty report based on recent student activity.";
  bool _isLoading = false;

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _report = "Analyzing student sessions anonymously...";
    });

    try {
      // 1. Get all sessions (In a real app, this would be filtered by Classroom ID)
      // We'll use the existing stream and convert to a one-time future for the report
      final sessions = await FirestoreService().sessionsStream().first;
      
      if (sessions.isEmpty) {
        setState(() {
          _report = "No student sessions found to analyze. Encourage your students to save their study sessions!";
          _isLoading = false;
        });
        return;
      }

      // 2. Anonymize and extract summaries
      final summaries = sessions.map((s) => "Subject: ${s.subject}, Grade: ${s.grade}, Mode: ${s.learningMode}\nContent: ${s.preview}").toList();

      // 3. Send to Gemini
      final report = await _geminiService.analyzeClassroomTrends(summaries);

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _report = "Error generating report: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text('Teacher Dashboard 2.0', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPrivacyInfo(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildReportCard(),
            const SizedBox(height: 30),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.insights_rounded, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              Text(
                "Classroom Analytics",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "This tool uses Gemini AI to analyze all saved student sessions and identify which topics are causing the most confusion across your class.",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade50),
      ),
      child: _isLoading 
        ? Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text("Gemini is reading the data...", style: GoogleFonts.outfit(color: Colors.indigo)),
              ],
            ),
          )
        : MarkdownBody(
            data: _report,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.outfit(fontSize: 15, height: 1.6),
              h3: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              listBullet: const TextStyle(fontSize: 15),
            ),
          ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        icon: const Icon(Icons.auto_awesome),
        label: Text(
          "Generate Classroom Insights",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy & Anonymity"),
        content: const Text(
          "No student names or personal IDs are sent to the AI. Only the subject, grade, and the educational content of their questions are analyzed to protect student privacy.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("I Understand")),
        ],
      ),
    );
  }
}
