import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class NoteModel {
  final String id;
  final List<List<Map<String, double>>> drawingPoints;
  final String? imageData; // Add support for image data
  final bool isImage; // Flag to indicate if this is an image-based note
  final DateTime timestamp;
  final Color color;
  final double x;
  final double y;
  final String author;

  NoteModel({
    String? id,
    this.drawingPoints = const [],
    this.imageData,
    this.isImage = false,
    DateTime? timestamp,
    required this.color,
    required this.x,
    required this.y,
    this.author = 'مجهول',
  }) : id = id ?? Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    print('=== NoteModel.toMap Debug ===');
    print('ID: $id');
    print('Is Image: $isImage');
    if (isImage) {
      print('Image data length: ${imageData?.length ?? 0}');
    } else {
      print('Drawing points: $drawingPoints');
      print('Points count: ${drawingPoints.length}');
    }

    final map = {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'color': color.value,
      'x': x,
      'y': y,
      'author': author,
      'isImage': isImage,
    };

    if (isImage && imageData != null) {
      map['imageData'] = imageData!;
    } else {
      map['drawingPoints'] = drawingPoints;
    }

    return map;
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    print('=== NoteModel.fromMap Debug ===');
    print('Input map keys: ${map.keys}');

    final isImage = map['isImage'] == true;
    print('Is Image: $isImage');

    if (isImage) {
      // Handle image-based note
      final imageData = map['imageData'] as String?;
      print('Image data length: ${imageData?.length ?? 0}');

      return NoteModel(
        id: map['id']?.toString() ?? '',
        isImage: true,
        imageData: imageData,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          _parseInt(map['timestamp']) ?? 0,
        ),
        color: Color(_parseInt(map['color']) ?? Colors.yellow.value),
        x: _parseDouble(map['x']) ?? 0.0,
        y: _parseDouble(map['y']) ?? 0.0,
        author: map['author']?.toString() ?? 'مجهول',
      );
    } else {
      // Handle drawing points-based note
      final List<List<Map<String, double>>> points = [];

      try {
        final rawDrawingPoints = map['drawingPoints'];
        print('Raw drawing points: $rawDrawingPoints');
        print('Raw drawing points type: ${rawDrawingPoints.runtimeType}');

        if (rawDrawingPoints != null && rawDrawingPoints is List) {
          for (
            int strokeIndex = 0;
            strokeIndex < rawDrawingPoints.length;
            strokeIndex++
          ) {
            final stroke = rawDrawingPoints[strokeIndex];
            print('Processing stroke $strokeIndex: $stroke');

            if (stroke is List) {
              final List<Map<String, double>> newStroke = [];

              for (
                int pointIndex = 0;
                pointIndex < stroke.length;
                pointIndex++
              ) {
                final point = stroke[pointIndex];
                print('Processing point $pointIndex: $point');

                if (point is Map) {
                  try {
                    final x = _parseDouble(point['x']);
                    final y = _parseDouble(point['y']);

                    if (x != null && y != null && x.isFinite && y.isFinite) {
                      newStroke.add({'x': x, 'y': y});
                      print('Added valid point: x=$x, y=$y');
                    } else {
                      print('Skipped invalid point: x=$x, y=$y');
                    }
                  } catch (e) {
                    print('Error parsing point: $e');
                  }
                }
              }

              if (newStroke.isNotEmpty) {
                points.add(newStroke);
                print('Added stroke with ${newStroke.length} points');
              }
            }
          }
        }

        print('Final points structure: $points');
        print('Total strokes: ${points.length}');
      } catch (e) {
        print('Error processing drawing points: $e');
      }

      return NoteModel(
        id: map['id']?.toString() ?? '',
        drawingPoints: points,
        isImage: false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          _parseInt(map['timestamp']) ?? 0,
        ),
        color: Color(_parseInt(map['color']) ?? Colors.yellow.value),
        x: _parseDouble(map['x']) ?? 0.0,
        y: _parseDouble(map['y']) ?? 0.0,
        author: map['author']?.toString() ?? 'مجهول',
      );
    }
  }

  // Helper methods for safe parsing
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, isImage: $isImage, pointsCount: ${drawingPoints.length}, author: $author)';
  }
}
// class NoteModel {
//   final String id;
//   final List<List<dynamic>> drawingPoints;
//   final DateTime timestamp;
//   final Color color;
//   final double x;
//   final double y;
//   final String author;

//   NoteModel({
//     String? id,
//     required this.drawingPoints,
//     DateTime? timestamp,
//     required this.color,
//     required this.x,
//     required this.y,
//     this.author = 'مجهول',
//   }) : id = id ?? Uuid().v4(),
//        timestamp = timestamp ?? DateTime.now();

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'drawingPoints': drawingPoints,
//       'timestamp': timestamp.millisecondsSinceEpoch,
//       'color': color.value,
//       'x': x,
//       'y': y,
//       'author': author,
//     };
//   }

//   factory NoteModel.fromMap(Map<String, dynamic> map) {
//     final List<List<dynamic>> points = [];
//     if (map['drawingPoints'] is List) {
//       for (var stroke in map['drawingPoints']) {
//         if (stroke is List) {
//           final List<dynamic> newStroke = [];
//           for (var point in stroke) {
//             if (point is Map) {
//               newStroke.add(point);
//             }
//           }
//           points.add(newStroke);
//         }
//       }
//     }

//     return NoteModel(
//       id: map['id'] ?? '',
//       drawingPoints: points,
//       timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
//       color: Color(map['color'] ?? Colors.yellow.value),
//       x: (map['x'] ?? 0).toDouble(),
//       y: (map['y'] ?? 0).toDouble(),
//       author: map['author'] ?? 'مجهول',
//     );
//   }
// }
