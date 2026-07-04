import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/api_service.dart';
import 'note_detail_page.dart';
import 'add_edit_note_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<NoteModel> _allNotes = [];
  List<NoteModel> _filteredNotes = [];
  bool _isLoading = false;
  bool _isGridView = true;
  int _currentIndex = 0;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': Icons.all_inclusive},
    {'name': 'Umum', 'icon': Icons.notes},
    {'name': 'Ide', 'icon': Icons.lightbulb_outline},
    {'name': 'Pekerjaan', 'icon': Icons.work_outline},
    {'name': 'Pribadi', 'icon': Icons.person_outline},
    {'name': 'Penting', 'icon': Icons.star_border},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await ApiService.getNotes();
    setState(() {
      _allNotes = notes;
      _isLoading = false;
    });
    _onFilterChanged();
  }

  void _onFilterChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _allNotes.where((note) {
        final matchesSearch = note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'Semua' || note.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _togglePin(NoteModel note) async {
    final success = await ApiService.updateNote(
      id: note.id,
      title: note.title,
      content: note.content,
      category: note.category,
      color: note.color,
      isPinned: !note.isPinned,
    );
    if (success) {
      _loadNotes();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi 🌅';
    if (hour < 15) return 'Selamat Siang ☀️';
    if (hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
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

  void _exportNotes() {
    if (_allNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada catatan untuk diekspor")),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln("# EKSPOR DATA SIMPEL NOTES");
    buffer.writeln("Tanggal Ekspor: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}");
    buffer.writeln("Total Catatan: ${_allNotes.length}\n");
    buffer.writeln("=========================================\n");

    for (var note in _allNotes) {
      buffer.writeln("## ${note.title}");
      buffer.writeln("Kategori: ${note.category} | Pinned: ${note.isPinned ? 'Ya' : 'Tidak'}");
      buffer.writeln("Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(note.date)}");
      buffer.writeln("Isi Catatan:");
      buffer.writeln(note.content);
      buffer.writeln("\n-----------------------------------------\n");
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Ekspor Catatan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Salin teks format Markdown di bawah ini:",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    buffer.toString(),
                    style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup", style: TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _currentIndex == 0 ? _buildNotesTab() : _buildStatsAndProfileTab(),
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF00F2FE),
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_rounded),
            label: 'Catatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Analisis & Profil',
          ),
        ],
      ),

      // Floating Action Button (Only show on Notes Tab)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final added = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditNotePage()),
                );
                if (added == true) {
                  _loadNotes();
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
    );
  }

  // NOTE TAB
  Widget _buildNotesTab() {
    final totalNotesCount = _allNotes.length;
    final pinnedNotesCount = _allNotes.where((n) => n.isPinned).length;
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1E293B),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF00F2FE)),
                        onPressed: _loadNotes,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Quick Stats Board
          Container(
            height: 90,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.description_outlined, color: Color(0xFF00F2FE), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              totalNotesCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text("Catatan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.push_pin_outlined, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pinnedNotesCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text("Disematkan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Gradient Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155), width: 1),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Cari catatan Anda...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00F2FE)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Category Filter Row
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (ctx, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['name'];
                    });
                    _onFilterChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)])
                          : null,
                      color: isSelected ? null : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          cat['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Notes List/Grid Display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE)))
                : RefreshIndicator(
                    onRefresh: _loadNotes,
                    child: _filteredNotes.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF334155), width: 1),
                                      ),
                                      child: const Icon(Icons.note_alt_outlined, size: 50, color: Color(0xFF00F2FE)),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Tidak Ada Catatan",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tulis catatan pertamamu dengan mengetuk tombol +",
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _filteredNotes.length,
                                itemBuilder: (ctx, idx) => _buildNoteCard(_filteredNotes[idx]),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: _filteredNotes.length,
                                itemBuilder: (ctx, idx) => _buildNoteListTile(_filteredNotes[idx]),
                              ),
                  ),
          ),
        ],
      ),
    );
  }

  // STATS & DEVELOPER PROFILE TAB (Grade A Feature Expansion)
  Widget _buildStatsAndProfileTab() {
    // Math statistics
    final total = _allNotes.length;
    final ideCount = _allNotes.where((n) => n.category == 'Ide').length;
    final kerjaCount = _allNotes.where((n) => n.category == 'Pekerjaan').length;
    final pribadiCount = _allNotes.where((n) => n.category == 'Pribadi').length;
    final pentingCount = _allNotes.where((n) => n.category == 'Penting').length;
    final umumCount = _allNotes.where((n) => n.category == 'Umum').length;

    // Helper progress math
    double percent(int count) {
      if (total == 0) return 0.0;
      return count / total;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Statistik & Profil",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Dashboard analisis dan informasi pengembang",
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 20),

            // 📊 STATS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Color(0xFF00F2FE)),
                      SizedBox(width: 8),
                      Text(
                        "Distribusi Kategori",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildProgressRow("Ide 💡", ideCount, percent(ideCount), const Color(0xFFFF9A9E)),
                  const SizedBox(height: 14),
                  _buildProgressRow("Pekerjaan 💼", kerjaCount, percent(kerjaCount), const Color(0xFFA1C4FD)),
                  const SizedBox(height: 14),
                  _buildProgressRow("Pribadi 🏠", pribadiCount, percent(pribadiCount), const Color(0xFF84FAB0)),
                  const SizedBox(height: 14),
                  _buildProgressRow("Penting 🔥", pentingCount, percent(pentingCount), const Color(0xFFF6D365)),
                  const SizedBox(height: 14),
                  _buildProgressRow("Umum 📋", umumCount, percent(umumCount), Colors.white70),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🎓 DEVELOPER PROFILE (Important for University / Class Projects!)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Icon Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Dani Eka Putra",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Pengembang Aplikasi (Developer)",
                    style: TextStyle(color: Color(0xFF00F2FE), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Divider(color: Color(0xFF334155), height: 30),
                  _buildProfileRow(Icons.book, "Proyek", "Ujian Akhir Semester (UAS)"),
                  const SizedBox(height: 12),
                  _buildProfileRow(Icons.code, "Teknologi", "Flutter (Dart) & PHP REST API"),
                  const SizedBox(height: 12),
                  _buildProfileRow(Icons.storage, "Database", "MySQL (PDO Connection)"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ⚙️ ACTIONS CARD (Grade A feature: Markdown Export)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155), width: 1),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download_rounded, color: Color(0xFF00F2FE)),
                ),
                title: const Text("Ekspor Catatan (Markdown)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Salin data tulisan catatan Anda", style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: _exportNotes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, double percentValue, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text("$count catatan", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentValue,
            minHeight: 8,
            backgroundColor: const Color(0xFF334155),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 18),
        const SizedBox(width: 12),
        Text(
          "$label:",
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Grid Card View
  Widget _buildNoteCard(NoteModel note) {
    final noteColor = _parseColor(note.color);
    final formattedDate = DateFormat('dd MMM yyyy').format(note.date);
    final readingTime = _getReadingTime(note.content);

    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailPage(note: note)),
        );
        if (updated == true) {
          _loadNotes();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: note.isPinned ? Colors.amber.withValues(alpha: 0.6) : const Color(0xFF334155),
            width: note.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(color: noteColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: noteColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            note.category,
                            style: TextStyle(
                              color: noteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _togglePin(note),
                          child: Icon(
                            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 16,
                            color: note.isPinned ? Colors.amber : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        note.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey[500], fontSize: 10),
                        ),
                        Text(
                          "$readingTime mnt baca",
                          style: TextStyle(color: Colors.grey[500], fontSize: 10),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List Item View
  Widget _buildNoteListTile(NoteModel note) {
    final noteColor = _parseColor(note.color);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(note.date);
    final readingTime = _getReadingTime(note.content);

    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailPage(note: note)),
        );
        if (updated == true) {
          _loadNotes();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: note.isPinned ? Colors.amber.withValues(alpha: 0.6) : const Color(0xFF334155),
            width: note.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(color: noteColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: noteColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  note.category,
                                  style: TextStyle(
                                    color: noteColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(color: Colors.grey[500], fontSize: 10),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "•  $readingTime mnt baca",
                                style: TextStyle(color: Colors.grey[500], fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _togglePin(note),
                      child: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: note.isPinned ? Colors.amber : Colors.grey[500],
                        size: 20,
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