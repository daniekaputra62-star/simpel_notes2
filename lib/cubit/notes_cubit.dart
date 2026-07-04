import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';
import '../models/note_model.dart';
import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  NotesCubit() : super(NotesInitial());

  void fetchNotes() async {
    emit(NotesLoading());

    final data = await ApiService.getNotes();
    List<Note> notes = data.map<Note>((e) => Note.fromJson(e)).toList();

    emit(NotesLoaded(notes));
  }

  void addNote(String title, String content) async {
    await ApiService.addNote(title, content);
    fetchNotes();
  }

  void deleteNote(String id) async {
    await ApiService.deleteNote(id);
    fetchNotes();
  }
}