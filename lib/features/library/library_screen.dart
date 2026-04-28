import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/saved_session.dart';
import '../../core/firestore_service.dart';
import '../teacher/teacher_dashboard_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'My Study Library',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
            ),
            tooltip: 'Teacher Insights',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<SavedSession>>(
        stream: FirestoreService().sessionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return const _EmptyLibrary();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _SessionCard(session: session);
            },
          );
        },
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 80, color: Colors.indigo.shade100),
          const SizedBox(height: 24),
          Text(
            'Your library is empty',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload a problem and save your first\ntutoring session to see it here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final SavedSession session;
  const _SessionCard({required this.session});

  static const Map<String, Color> _subjectColors = {
    'Mathematics': Color(0xFF3949AB),
    'Science': Color(0xFF00897B),
    'Physics': Color(0xFF8E24AA),
    'Chemistry': Color(0xFFE53935),
    'Biology': Color(0xFF43A047),
    'History': Color(0xFFF4511E),
    'Geography': Color(0xFF039BE5),
  };

  Color get _color =>
      _subjectColors[session.subject] ?? const Color(0xFF3949AB);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.indigo.shade50),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(session: session),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Subject badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.subject,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Learning mode badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.learningMode,
                      style: GoogleFonts.outfit(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: Colors.grey.shade400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                session.grade,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                session.preview,
                style: GoogleFonts.outfit(
                    fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                _formatDate(session.savedAt),
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}  $hour:$min $period';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('This session will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && session.id != null) {
      await FirestoreService().deleteSession(session.id!);
    }
  }
}

// ─── Session Detail Screen ────────────────────────────────────────────────────
class SessionDetailScreen extends StatelessWidget {
  final SavedSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(session.subject, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade900,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.indigo.shade50, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata row
            Row(
              children: [
                _Tag(label: session.grade, color: Colors.indigo),
                const SizedBox(width: 8),
                _Tag(label: session.learningMode, color: Colors.teal),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Full Gemini response
            MarkdownBody(
              data: session.response,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.outfit(fontSize: 16, height: 1.7, color: Colors.black87),
                h3: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
                listBullet: const TextStyle(fontSize: 16, height: 1.7),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.outfit(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
