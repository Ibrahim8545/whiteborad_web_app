import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:testwhiteboard/models/note_model.dart';
import 'package:uuid/uuid.dart';

class NotesService with ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final List<NoteModel> _notes = [];
  StreamSubscription? _notesSubscription;
  bool _isConnected = true;
  bool _showPuzzleSuccess = false;
  String _puzzleWinnerName = '';
  ui.Image? _completedPuzzleImage;
  Timer? _puzzleDisplayTimer;

  List<NoteModel> get notes => List.unmodifiable(_notes);
  bool get isConnected => _isConnected;
  bool get showPuzzleSuccess => _showPuzzleSuccess;
  String get puzzleWinnerName => _puzzleWinnerName;
  ui.Image? get completedPuzzleImage => _completedPuzzleImage;

  PuzzleSuccessDisplayData? _lastSuccessData;
  PuzzleSuccessDisplayData? get lastSuccessData => _lastSuccessData;

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

  void triggerPuzzleSuccessDisplay(
    String playerName,
    ui.Image completedImage,
    int secondsElapsed, // <--- تأكد من وجود هذا المتغير
  ) {
    _showPuzzleSuccess = true;
    _puzzleWinnerName = playerName;
    _completedPuzzleImage = completedImage;
    _lastSuccessData = PuzzleSuccessDisplayData(
      playerName: playerName,
      completedImage: completedImage,
      secondsElapsed: secondsElapsed,
      completionTime: DateTime.now(),
    );
    notifyListeners();
    print(
      'تم إرسال بيانات الفوز للشاشة الأخرى: $playerName في $secondsElapsed ثانية',
    );

    // إلغاء أي مؤقت سابق وتعيين مؤقت جديد لمدة 10 ثوانٍ
    _puzzleDisplayTimer?.cancel();
    _puzzleDisplayTimer = Timer(Duration(seconds: 10), () {
      hidePuzzleSuccess();
    });
  }

  // دالة لإخفاء البازل
  void hidePuzzleSuccess() {
    _showPuzzleSuccess = false;
    _puzzleWinnerName = '';
    _completedPuzzleImage = null;
    _puzzleDisplayTimer?.cancel(); // تأكد من إلغاء المؤقت عند الإخفاء
    notifyListeners();
  }

  // void triggerPuzzleSuccessDisplay(String playerName, ui.Image completedImage) {
  //   _showPuzzleSuccess = true;
  //   _puzzleWinnerName = playerName;
  //   _completedPuzzleImage = completedImage;
  //   notifyListeners();

  //   // تعديل المدة إلى 10 ثواني
  //   _puzzleDisplayTimer?.cancel();
  //   _puzzleDisplayTimer = Timer(Duration(seconds: 10), () {
  //     hidePuzzleSuccess();
  //   });
  // }

  // // دالة لإخفاء البازل
  // void hidePuzzleSuccess() {
  //   _showPuzzleSuccess = false;
  //   _puzzleWinnerName = '';
  //   _completedPuzzleImage = null;
  //   _puzzleDisplayTimer?.cancel();
  //   notifyListeners();
  // }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}

class PuzzleSuccessDisplayData {
  final String playerName;
  final ui.Image completedImage;
  final int secondsElapsed; // <--- تمت الإضافة
  final DateTime completionTime;

  PuzzleSuccessDisplayData({
    required this.playerName,
    required this.completedImage,
    required this.secondsElapsed, // <--- تمت الإضافة
    required this.completionTime,
  });
}
