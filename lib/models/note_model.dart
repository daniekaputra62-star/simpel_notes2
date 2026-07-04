class NoteModel {
  final int id;
  final String title;
  final String content;
  final String category;
  final String color;
  final bool isPinned;
  final DateTime date;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.isPinned,
    required this.date,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'Umum',
      color: json['color'] ?? '#4FACFE',
      isPinned: (int.tryParse(json['is_pinned'].toString()) ?? 0) == 1,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }
}
