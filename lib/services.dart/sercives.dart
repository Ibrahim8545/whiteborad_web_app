import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:testwhiteboard/models/note_model.dart';
import 'package:uuid/uuid.dart';

class NotesService with ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final List<NoteModel> _notes = [];
  StreamSubscription? _notesSubscription;
  bool _isConnected = true;

  List<NoteModel> get notes => List.unmodifiable(_notes);
  bool get isConnected => _isConnected;

  NotesService() {
    _initializeDatabase();
  }

  void _initializeDatabase() {
    _database.child('.info/connected').onValue.listen((event) {
      _isConnected = event.snapshot.value as bool? ?? false;
      print('Firebase connection status: $_isConnected');
      notifyListeners();
    });

    _notesSubscription = _database.child('notes').onValue.listen((event) {
      print('=== NotesService: Received data update ===');

      _notes.clear();
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          print('Raw Firebase data keys: ${data.keys}');

          data.forEach((key, value) {
            try {
              print('Processing note with key: $key');
              final noteData = Map<String, dynamic>.from(value);
              print('Note data keys: ${noteData.keys}');

              final note = NoteModel.fromMap(noteData);
              _notes.add(note);
              print('Successfully added note: ${note.id}');
            } catch (e) {
              print('Error processing note $key: $e');
            }
          });

          _notes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          print('Total notes loaded: ${_notes.length}');
        } catch (e) {
          print('Error processing Firebase data: $e');
        }
      } else {
        print('No data received from Firebase');
      }

      notifyListeners();
    });
  }

  Future<bool> addNote({
    required List<List<Map<String, double>>> drawingPoints,
    required Color color,
    String author = 'مستخدم',
  }) async {
    try {
      print('=== NotesService: Adding new note ===');
      print('Drawing points: $drawingPoints');
      print('Points count: ${drawingPoints.length}');

      // Validate input
      if (drawingPoints.isEmpty) {
        print('Error: Empty drawing points');
        return false;
      }

      // Count total points for validation
      int totalPoints = 0;
      for (final stroke in drawingPoints) {
        totalPoints += stroke.length;
      }

      if (totalPoints == 0) {
        print('Error: No valid points found');
        return false;
      }

      print('Total points to save: $totalPoints');

      final random = Random();
      final x = random.nextDouble() * 500 + 50;
      final y = random.nextDouble() * 300 + 50;

      final note = NoteModel(
        drawingPoints: drawingPoints,
        color: color,
        x: x,
        y: y,
        author: author,
      );

      print('Created note: ${note.id}');
      final noteMap = note.toMap();
      print('Note map keys: ${noteMap.keys}');

      await _database.child('notes').child(note.id).set(noteMap);
      print('Note saved to Firebase successfully');

      return true;
    } catch (e) {
      print('خطأ في إضافة الملاحظة: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // New method for adding notes with image data
  Future<bool> addNoteWithImage({
    required String imageData,
    required Color color,
    String author = 'مستخدم',
  }) async {
    try {
      print('=== NotesService: Adding new note with image ===');
      print('Image data length: ${imageData.length}');

      final random = Random();
      final x = random.nextDouble() * 500 + 50;
      final y = random.nextDouble() * 300 + 50;

      final noteData = {
        'id': Uuid().v4(),
        'imageData': imageData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'color': color.value,
        'x': x,
        'y': y,
        'author': author,
        'isImage': true,
      };

      print('Created image note with id: ${noteData['id']}');

      await _database
          .child('notes')
          .child(noteData['id'] as String)
          .set(noteData);
      print('Image note saved to Firebase successfully');

      return true;
    } catch (e) {
      print('خطأ في إضافة الملاحظة بالصورة: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      print('Deleting note: $noteId');
      await _database.child('notes').child(noteId).remove();
      print('Note deleted successfully');
      return true;
    } catch (e) {
      print('خطأ في حذف الملاحظة: $e');
      return false;
    }
  }

  Future<bool> clearAllNotes() async {
    try {
      print('Clearing all notes');
      await _database.child('notes').remove();
      print('All notes cleared successfully');
      return true;
    } catch (e) {
      print('خطأ في مسح الملاحظات: $e');
      return false;
    }
  }

  Future<bool> updateNotePosition(String noteId, double x, double y) async {
    try {
      await _database.child('notes').child(noteId).update({'x': x, 'y': y});
      return true;
    } catch (e) {
      print('خطأ في تحديث موقع الملاحظة: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
// class NotesService with ChangeNotifier {
//   final DatabaseReference _database = FirebaseDatabase.instance.ref();
//   final List<NoteModel> _notes = [];
//   StreamSubscription? _notesSubscription;
//   bool _isConnected = true;

//   List<NoteModel> get notes => List.unmodifiable(_notes);
//   bool get isConnected => _isConnected;

//   NotesService() {
//     _initializeDatabase();
//   }

//   void _initializeDatabase() {
//     _database.child('.info/connected').onValue.listen((event) {
//       _isConnected = event.snapshot.value as bool? ?? false;
//       notifyListeners();
//     });

//     _notesSubscription = _database.child('notes').onValue.listen((event) {
//       _notes.clear();
//       if (event.snapshot.value != null) {
//         final data = Map<String, dynamic>.from(event.snapshot.value as Map);
//         data.forEach((key, value) {
//           final noteData = Map<String, dynamic>.from(value);
//           _notes.add(NoteModel.fromMap(noteData));
//         });
//         _notes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//       }
//       notifyListeners();
//     });
//   }

//   Future<bool> addNote({
//     required List<List<dynamic>> drawingPoints,
//     required Color color,
//     String author = 'مستخدم',
//   }) async {
//     try {
//       final random = Random();
//       final x = random.nextDouble() * 500 + 50;
//       final y = random.nextDouble() * 300 + 50;

//       final note = NoteModel(
//         drawingPoints: drawingPoints,
//         color: color,
//         x: x,
//         y: y,
//         author: author,
//       );

//       await _database.child('notes').child(note.id).set(note.toMap());
//       return true;
//     } catch (e) {
//       print('خطأ في إضافة الملاحظة: $e');
//       return false;
//     }
//   }

//   // New method for image-based notes
//   Future<bool> addImageNote({
//     required String imageData,
//     required Color color,
//     String author = 'مستخدم',
//   }) async {
//     try {
//       final random = Random();
//       final x = random.nextDouble() * 500 + 50;
//       final y = random.nextDouble() * 300 + 50;

//       // Create a simple note with image data instead of drawing points
//       final noteData = {
//         'id': DateTime.now().millisecondsSinceEpoch.toString(),
//         'imageData': imageData,
//         'color': color.value,
//         'x': x,
//         'y': y,
//         'author': author,
//         'timestamp': ServerValue.timestamp,
//         'type': 'image',
//       };

//       await _database
//           .child('notes')
//           .child(noteData['id'] as String)
//           .set(noteData);
//       return true;
//     } catch (e) {
//       print('خطأ في إضافة ملاحظة الصورة: $e');
//       return false;
//     }
//   }

//   Future<bool> deleteNote(String noteId) async {
//     try {
//       await _database.child('notes').child(noteId).remove();
//       return true;
//     } catch (e) {
//       print('خطأ في حذف الملاحظة: $e');
//       return false;
//     }
//   }

//   Future<bool> clearAllNotes() async {
//     try {
//       await _database.child('notes').remove();
//       return true;
//     } catch (e) {
//       print('خطأ في مسح الملاحظات: $e');
//       return false;
//     }
//   }

//   Future<bool> updateNotePosition(String noteId, double x, double y) async {
//     try {
//       await _database.child('notes').child(noteId).update({'x': x, 'y': y});
//       return true;
//     } catch (e) {
//       print('خطأ في تحديث موقع الملاحظة: $e');
//       return false;
//     }
//   }

//   @override
//   void dispose() {
//     _notesSubscription?.cancel();
//     super.dispose();
//   }
// }
