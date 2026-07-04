import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/note_model.dart';

class ApiService {
  // If running on Android Emulator, localhost is mapped to 10.0.2.2.
  // For physical devices or other platforms, use the actual host IP or localhost.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1/api_notes';
    }
    return 'http://10.0.2.2/api_notes';
  }

  static Future<List<NoteModel>> getNotes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_notes.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List list = data['data'] ?? [];
          return list.map((json) => NoteModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching notes: $e");
      return [];
    }
  }

  static Future<bool> addNote({
    required String title,
    required String content,
    required String category,
    required String color,
    required bool isPinned,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_notes.php'),
        body: {
          'title': title,
          'content': content,
          'category': category,
          'color': color,
          'is_pinned': isPinned ? '1' : '0',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Error adding note: $e");
      return false;
    }
  }

  static Future<bool> updateNote({
    required int id,
    required String title,
    required String content,
    required String category,
    required String color,
    required bool isPinned,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_note.php'),
        body: {
          'id': id.toString(),
          'title': title,
          'content': content,
          'category': category,
          'color': color,
          'is_pinned': isPinned ? '1' : '0',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Error updating note: $e");
      return false;
    }
  }

  static Future<bool> deleteNote(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_note.php'),
        body: {
          'id': id.toString(),
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting note: $e");
      return false;
    }
  }
}
