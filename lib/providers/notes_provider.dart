import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotesInfo {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;

  NotesInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
  });
}

class Notes extends ChangeNotifier {
  List<NotesInfo> _notes = [];
  List<NotesInfo> get notes {
    return [..._notes];
  }

  Future<void> fetchNotesInfo() async {
    const url =
        'https://notes-app-a8567-default-rtdb.firebaseio.com/notes.json';
    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);
      if (responseData == null) {
        return;
      }
      final Map<String, dynamic> notesInfo = responseData;
      final List<NotesInfo> loadedNotes = [];
      notesInfo.forEach((noteId, noteData) {
        loadedNotes.add(
          NotesInfo(
            id: noteId,
            title: noteData['title'],
            description: noteData['description'],
            dateTime: DateTime.parse(noteData['dateTime']),
          ),
        );
      });
      _notes = loadedNotes;
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> saveNote(NotesInfo info) async {
    const url =
        'https://notes-app-a8567-default-rtdb.firebaseio.com/notes.json';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(
          {
            'title': info.title,
            'description': info.description,
            'dateTime': info.dateTime.toIso8601String(),
          },
        ),
      );
      final newNote = NotesInfo(
        id: json.decode(response.body)['name'],
        title: info.title,
        description: info.description,
        dateTime: info.dateTime,
      );
      _notes.add(newNote);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateNote(NotesInfo info) async {
    int currentIndex = _notes.indexWhere((note) => note.id == info.id);

    if (currentIndex >= 0) {
      final id = info.id;
      final url =
          'https://notes-app-a8567-default-rtdb.firebaseio.com/notes/$id.json';

      try {
        await http.patch(
          Uri.parse(url),
          body: json.encode(
            {
              'title': info.title,
              'description': info.description,
              'dateTime': info.dateTime.toIso8601String(),
            },
          ),
        );
        _notes[currentIndex] = info;
        notifyListeners();
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> deleteNote(String id) async {
    final url =
        'https://notes-app-a8567-default-rtdb.firebaseio.com/notes/$id.json';
    int currentIndex = _notes.indexWhere((note) => note.id == id);
    final noteToBeDeleted = _notes[currentIndex];
    _notes.removeAt(currentIndex);
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode >= 400) {
      _notes.insert(currentIndex, noteToBeDeleted);
      notifyListeners();
      throw const HttpException('Unable to delete note from server');
    }
    notifyListeners();
  }
}
