import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile currentProfile;
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.currentProfile, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _subject;
  late String _grade;
  late String _learningMode;
  late String _language;
  late TextEditingController _nameController;

  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
  ];

  final List<String> _grades = [
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  final List<String> _learningModes = [
    'Standard',
    'Dyslexia-Friendly',
    'Visually Impaired',
    'Simplified',
  ];

  final Map<String, IconData> _modeIcons = {
    'Standard': Icons.school,
    'Dyslexia-Friendly': Icons.text_fields,
    'Visually Impaired': Icons.visibility,
    'Simplified': Icons.child_care,
  };

  final Map<String, String> _modeDescriptions = {
    'Standard': 'Clear educational language for all students',
    'Dyslexia-Friendly': 'Short sentences, bullets, bold key terms',
    'Visually Impaired': 'Detailed verbal descriptions, no visual references',
    'Simplified': 'Very simple words and analogies',
  };

  final List<String> _languages = ['English', 'Kannada', 'Hindi', 'Tamil'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _subject = widget.currentProfile.subject;
    _grade = widget.currentProfile.grade;
    _learningMode = widget.currentProfile.learningMode;
    _language = widget.currentProfile.language;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('My Learning Profile'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_pin, size: 36, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'Profile: ${widget.currentProfile.name}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your preferences and library are locked to this name.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Name (Read Only)
            _SectionLabel(label: 'Full Name (Account ID)', icon: Icons.lock_outline),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.currentProfile.name,
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Subject
            _SectionLabel(label: 'Subject', icon: Icons.book_outlined),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _subject,
              items: _subjects,
              onChanged: (val) => setState(() => _subject = val!),
            ),

            const SizedBox(height: 20),

            // Grade
            _SectionLabel(label: 'Grade / Class', icon: Icons.grade_outlined),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _grade,
              items: _grades,
              onChanged: (val) => setState(() => _grade = val!),
            ),

            const SizedBox(height: 20),

            // Language
            _SectionLabel(
                label: 'Preferred Language', icon: Icons.language_outlined),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages
                  .map((lang) => SizedBox(
                        width: (MediaQuery.of(context).size.width - 56) / 2,
                        child: _ChoiceChip(
                          label: lang,
                          icon: lang == 'English'
                              ? Icons.abc
                              : Icons.translate,
                          isSelected: _language == lang,
                          onTap: () => setState(() => _language = lang),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // Learning Mode
            _SectionLabel(
                label: 'Learning Mode', icon: Icons.accessibility_new_outlined),
            const SizedBox(height: 8),
            ...(_learningModes.map((mode) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ModeCard(
                    mode: mode,
                    icon: _modeIcons[mode]!,
                    description: _modeDescriptions[mode]!,
                    isSelected: _learningMode == mode,
                    onTap: () => setState(() => _learningMode = mode),
                  ),
                ))),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save Changes',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Logout Button
            Center(
              child: TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text("Switch Student / Logout", style: TextStyle(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    final profile = widget.currentProfile.copyWith(
      subject: _subject,
      grade: _grade,
      learningMode: _learningMode,
      language: _language,
    );
    Navigator.pop(context, profile);
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      );
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ChoiceChip(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.indigo : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String mode;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  const _ModeCard(
      {required this.mode,
      required this.icon,
      required this.description,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.indigo : Colors.grey.shade200,
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected
                              ? Colors.indigo.shade800
                              : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.indigo, size: 22),
          ],
        ),
      ),
    );
  }
}
