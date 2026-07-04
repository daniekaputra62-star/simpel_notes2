import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/notes_cubit.dart';

class AddNotePage extends StatelessWidget {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Catatan")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Judul"),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: "Isi"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<NotesCubit>().addNote(
                      titleController.text,
                      contentController.text,
                    );
                Navigator.pop(context);
              },
              child: Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}