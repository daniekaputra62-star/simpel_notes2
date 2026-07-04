import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/api_service.dart';
import 'add_edit_note_page.dart';

class NoteDetailPage extends StatefulWidget {
  final NoteModel note;

  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late NoteModel _currentNote;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  void _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Catatan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin menghapus catatan ini?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteNote(_currentNote.id);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus catatan")),
        );
      }
    }
  }

  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF4FACFE);
    }
  }

  int _getReadingTime(String text) {
    final wordCount = text.split(RegExp(r'\s+')).length;
    final time = (wordCount / 200).ceil();
    return time < 1 ? 1 : time;
  }

  @override
  Widget build(BuildContext context) {
    final noteColor = _parseColor(_currentNote.color);
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(_currentNote.date);
    final readingTime = _getReadingTime(_currentNote.content);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanged),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF00F2FE)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditNotePage(note: _currentNote),
                ),
              );
              if (result == true) {
                final list = await ApiService.getNotes();
                final updated = list.firstWhere(
                  (n) => n.id == _currentNote.id,
                  orElse: () => _currentNote,
                );
                setState(() {
                  _currentNote = updated;
                  _hasChanged = true;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meta Header Cards
              Row(
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: noteColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: noteColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      _currentNote.category,
                      style: TextStyle(
                        color: noteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reading Time Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "$readingTime mnt baca",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Note Card Layout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _currentNote.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (_currentNote.isPinned) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.push_pin, color: Colors.amber, size: 24),
                        ]
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 32),
                    Text(
                      _currentNote.content,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFE8E8E8),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
