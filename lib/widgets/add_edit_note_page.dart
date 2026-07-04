import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/api_service.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;

  const AddEditNotePage({super.key, this.note});

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPinned = false;
  String _selectedCategory = 'Umum';
  String _selectedColor = '#4FACFE';

  // Words and character counters
  int _charCount = 0;
  int _wordCount = 0;

  // Preset colors for note cards
  final List<String> _presetColors = [
    '#4FACFE', // Cyan Blue
    '#FF9A9E', // Soft Pink
    '#F6D365', // Vibrant Coral/Orange
    '#A1C4FD', // Sky Blue
    '#84FAB0', // Mint Green
    '#CD9CF2', // Lavender Purple
  ];

  // Preset categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Umum', 'icon': Icons.notes},
    {'name': 'Ide', 'icon': Icons.lightbulb_outline},
    {'name': 'Pekerjaan', 'icon': Icons.work_outline},
    {'name': 'Pribadi', 'icon': Icons.person_outline},
    {'name': 'Penting', 'icon': Icons.star_border},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _isPinned = widget.note!.isPinned;
      _selectedCategory = widget.note!.category;
      _selectedColor = widget.note!.color;
      _updateCounters(widget.note!.content);
    }
    _contentController.addListener(() {
      _updateCounters(_contentController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateCounters(String text) {
    setState(() {
      _charCount = text.length;
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan isi catatan tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (widget.note == null) {
      success = await ApiService.addNote(
        title: title,
        content: content,
        category: _selectedCategory,
        color: _selectedColor,
        isPinned: _isPinned,
      );
    } else {
      success = await ApiService.updateNote(
        id: widget.note!.id,
        title: title,
        content: content,
        category: _selectedCategory,
        color: _selectedColor,
        isPinned: _isPinned,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan catatan")),
      );
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;
    final primaryColor = _parseColor(_selectedColor);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEdit ? "Edit Catatan" : "Catatan Baru",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Pin Icon in Toolbar
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Colors.amber : Colors.white70,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          const SizedBox(width: 8),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE), strokeWidth: 2)),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.check_circle, color: Color(0xFF00F2FE), size: 28),
                    onPressed: _saveNote,
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // 🏷️ Category Selection Header
                    Text(
                      "Pilih Kategori",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Horizontal Categories selection
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (ctx, idx) {
                          final cat = _categories[idx];
                          final isSelected = _selectedCategory == cat['name'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat['name']),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryColor : const Color(0xFF334155),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(cat['icon'], size: 14, color: isSelected ? primaryColor : Colors.grey[400]),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[300],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🎨 Color Card Picker Header
                    Text(
                      "Pilih Warna Aksen Catatan",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Colors Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _presetColors.map((hex) {
                        final parsedColor = _parseColor(hex);
                        final isSelected = _selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: parsedColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: parsedColor.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Title Input Box
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Judul Catatan",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Content Input Box
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
                      decoration: InputDecoration(
                        hintText: "Mulai menulis catatan Anda di sini...",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Stats Bar (Word/Character Counters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$_charCount karakter",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  Text(
                    "$_wordCount kata",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
