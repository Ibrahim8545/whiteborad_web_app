// import 'dart:convert';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// // تأكد من صحة مسارات الاستيراد لديك:
// import 'package:testwhiteboard/services.dart/sercives.dart';
// import '../models/note_model.dart';

// class DisplayScreen extends StatefulWidget {
//   @override
//   _DisplayScreenState createState() => _DisplayScreenState();
// }

// class _DisplayScreenState extends State<DisplayScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _backgroundController;
//   late Animation<double> _backgroundAnimation;

//   late AnimationController _puzzleController;
//   late Animation<double> _puzzleAnimation;
//   bool _isAssembling = false;

//   @override
//   void initState() {
//     super.initState();

//     _backgroundController = AnimationController(
//       duration: Duration(seconds: 10),
//       vsync: this,
//     )..repeat(reverse: true);

//     _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
//     );

//     _puzzleController = AnimationController(
//       duration: const Duration(seconds: 4),
//       vsync: this,
//     );

//     _puzzleAnimation = CurvedAnimation(
//       parent: _puzzleController,
//       curve: Curves.easeInOutQuad,
//     );
//   }

//   // ** الدالة المسؤولة عن حساب مواقع التجميع (التداخل على مواقع الـ 95) **
//   List<Offset> _getTargetPositions(
//     Size screenSize,
//     int totalNotes,
//     double cardWidth,
//     double cardHeight,
//   ) {
//     if (totalNotes == 0) return [];

//     final double screenWidth = screenSize.width;
//     final double screenHeight = screenSize.height;

//     const double GAP_SCALE_FACTOR = 0.005;
//     final double gap = screenWidth * GAP_SCALE_FACTOR;

//     // مصفوفة تمثل شكل '95' (مواقع الـ Post-it Notes)
//     final List<List<int>> pattern95 = [
//       [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
//       [1, 0, 1, 0, 0, 1, 0, 0, 0, 1],
//       [1, 1, 1, 0, 0, 1, 1, 1, 1, 0],
//       [0, 0, 1, 0, 0, 0, 0, 0, 0, 1],
//       [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
//     ];

//     final List<Offset> required95Positions = [];

//     for (int r = 0; r < pattern95.length; r++) {
//       for (int c = 0; c < pattern95[0].length; c++) {
//         if (pattern95[r][c] == 1) {
//           final double x = c * (cardWidth + gap);
//           final double y = r * (cardHeight + gap);
//           required95Positions.add(Offset(x, y));
//         }
//       }
//     }

//     final int count95 = required95Positions.length;

//     // حساب الأبعاد الفعلية للشكل الناتج لتوسيطه
//     final double maxColIndex =
//         (pattern95.map((row) => row.lastIndexOf(1)).reduce(math.max))
//             .toDouble();
//     final double actualPatternWidth =
//         (maxColIndex + 1) * cardWidth + maxColIndex * gap;
//     final double actualPatternHeight =
//         pattern95.length * cardHeight + (pattern95.length - 1) * gap;

//     // نقطة الإزاحة لتوسيط الشكل على الشاشة
//     final double offsetX = screenWidth / 2 - actualPatternWidth / 2;
//     final double offsetY = screenHeight / 2 - actualPatternHeight / 2;

//     final List<Offset> finalPositions = [];

//     for (int i = 0; i < totalNotes; i++) {
//       // استخدام باقي القسمة لتكرار المواقع الـ 95 (لتجميع عدد كبير)
//       final int targetIndex = i % count95;
//       final Offset basePosition = required95Positions[targetIndex];

//       // الإزاحة الأساسية للتوسيط
//       final Offset finalOffset = Offset(
//         basePosition.dx + offsetX,
//         basePosition.dy + offsetY,
//       );

//       // إضافة إزاحة بسيطة (Jitter) لتأثير التداخل
//       final double stackingJitter = (i % 10).toDouble() * 0.5;

//       finalPositions.add(
//         Offset(
//           finalOffset.dx + stackingJitter,
//           finalOffset.dy + stackingJitter,
//         ),
//       );
//     }

//     return finalPositions;
//   }

//   // دالة مساعدة لضمان موقع بداية مرئي
//   Offset _getSafeStartPosition(
//     NoteModel note,
//     double screenWidth,
//     double screenHeight,
//     double cardWidth,
//     double cardHeight,
//   ) {
//     double x = note.x;
//     double y = note.y;

//     const double safetyMargin = 30.0;

//     x = math.max(
//       safetyMargin,
//       math.min(x, screenWidth - cardWidth - safetyMargin),
//     );
//     y = math.max(
//       kToolbarHeight + safetyMargin,
//       math.min(y, screenHeight - cardHeight - safetyMargin),
//     );

//     return Offset(x, y);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     const double CARD_SCALE_FACTOR_W = 0.08;
//     const double CARD_SCALE_FACTOR_H = 0.12;

//     final double cardWidth = size.width * CARD_SCALE_FACTOR_W;
//     final double cardHeight = size.height * CARD_SCALE_FACTOR_H;

//     return Scaffold(
//       backgroundColor: Colors.transparent, // الخلفية شفافة لرؤية صورة الـ body
//       // appBar: AppBar(
//       //   title: Row(
//       //     children: [
//       //       Icon(Icons.tv, color: Colors.white),
//       //       SizedBox(width: 8),
//       //       Text('شاشة العرض الكبيرة'),
//       //     ],
//       //   ),
//       //   backgroundColor: Colors.orange.shade600.withOpacity(
//       //     0.9,
//       //   ), // شريط العنوان
//       //   elevation: 0,
//       //   actions: [
//       //     Consumer<NotesService>(
//       //       builder: (context, notesService, child) {
//       //         return Container(
//       //           margin: EdgeInsets.only(right: 16),
//       //           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       //           decoration: BoxDecoration(
//       //             color: notesService.isConnected
//       //                 ? Colors.green.withOpacity(0.2)
//       //                 : Colors.red.withOpacity(0.2),
//       //             borderRadius: BorderRadius.circular(20),
//       //             border: Border.all(
//       //               color: notesService.isConnected ? Colors.green : Colors.red,
//       //             ),
//       //           ),
//       //           child: Row(
//       //             mainAxisSize: MainAxisSize.min,
//       //             children: [
//       //               Icon(
//       //                 notesService.isConnected
//       //                     ? Icons.cloud_done
//       //                     : Icons.cloud_off,
//       //                 size: 16,
//       //                 color: notesService.isConnected
//       //                     ? Colors.green
//       //                     : Colors.red,
//       //               ),
//       //               SizedBox(width: 4),
//       //               Text(
//       //                 '${notesService.notes.length} ملاحظة',
//       //                 style: TextStyle(
//       //                   color: notesService.isConnected
//       //                       ? Colors.green
//       //                       : Colors.red,
//       //                   fontSize: 12,
//       //                   fontWeight: FontWeight.bold,
//       //                 ),
//       //               ),
//       //             ],
//       //           ),
//       //         );
//       //       },
//       //     ),
//       //   ],
//       // ),

//       // *** إضافة صورة الخلفية هنا ***
//       body: Container(
//         width: size.width,
//         height: size.height,
//         decoration: BoxDecoration(
//           color: Colors.black, // لون احتياطي
//           image: DecorationImage(
//             // ** تأكد من استخدام المسار الصحيح للصورة في مجلد assets/images **
//             image: AssetImage(
//               'assets/images/Saudi-National-Day-95th-Creative-National-Identity-Design.webp',
//             ),
//             fit: BoxFit.fill,
//             // تعتيم خفيف لضمان وضوح الكروت الصفراء فوق الخلفية الملونة
//             colorFilter: ColorFilter.mode(
//               Colors.black.withOpacity(0.3),
//               BlendMode.darken,
//             ),
//           ),
//         ),

//         child: Consumer<NotesService>(
//           builder: (context, notesService, child) {
//             final notes = notesService.notes;

//             if (notes.isEmpty) {
//               return Center(
//                 child: Text(
//                   'لا توجد ملاحظات حالياً',
//                   style: TextStyle(
//                     fontSize: 24,
//                     color: Colors.white70,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               );
//             }

//             final targetPositions = _getTargetPositions(
//               size,
//               notes.length,
//               cardWidth,
//               cardHeight,
//             );

//             return Stack(
//               children: notes.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final note = entry.value;

//                 final startOffset = _getSafeStartPosition(
//                   note,
//                   size.width,
//                   size.height,
//                   cardWidth,
//                   cardHeight,
//                 );
//                 final endOffset = targetPositions[index];

//                 return AnimatedBuilder(
//                   animation: _puzzleAnimation,
//                   builder: (context, child) {
//                     final currentX =
//                         startOffset.dx +
//                         (_puzzleAnimation.value *
//                             (endOffset.dx - startOffset.dx));
//                     final currentY =
//                         startOffset.dy +
//                         (_puzzleAnimation.value *
//                             (endOffset.dy - startOffset.dy));

//                     return Positioned(
//                       left: currentX,
//                       top: currentY,
//                       child: child!,
//                     );
//                   },
//                   child: _buildNoteWidget(
//                     context,
//                     note,
//                     notesService,
//                     cardWidth,
//                     cardHeight,
//                     index,
//                   ),
//                 );
//               }).toList(),
//             );
//           },
//         ),
//       ),

//       floatingActionButton: Consumer<NotesService>(
//         builder: (context, notesService, child) {
//           if (notesService.notes.isEmpty) return SizedBox.shrink();

//           return FloatingActionButton.extended(
//             onPressed: () {
//               setState(() {
//                 _isAssembling = !_isAssembling;
//                 if (_isAssembling) {
//                   _puzzleController.forward(from: 0.0);
//                 } else {
//                   _puzzleController.reverse();
//                 }
//               });
//             },
//             label: Text(
//               _isAssembling ? 'تفكيك الكروت' : 'تجميع الرقم 95',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             icon: Icon(_isAssembling ? Icons.scatter_plot : Icons.grid_on),
//             backgroundColor: Colors.orange.shade700,
//           );
//         },
//       ),
//     );
//   }

//   // ** الكود الخاص ببناء الـ Widget لكل ملاحظة (بتأثير ورقة الملاحظات) **
//   Widget _buildNoteWidget(
//     BuildContext context,
//     NoteModel note,
//     NotesService notesService,
//     double cardWidth,
//     double cardHeight,
//     int index,
//   ) {
//     final Color contentColor = note.color;

//     return Transform.rotate(
//       // ميلان خفيف وعشوائي يعتمد على الـ index
//       angle: (index % 10) * 0.01 - 0.05,
//       child: Container(
//         width: cardWidth,
//         height: cardHeight,
//         child: Material(
//           color: Colors.yellow.shade500, // لون أصفر داكن لورقة الملاحظات
//           elevation: 8,
//           borderRadius: BorderRadius.circular(5),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(5),
//             child: Stack(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(5.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Container(
//                           width: double.infinity,
//                           height: double.infinity,
//                           decoration: BoxDecoration(
//                             // الخلفية شفافة لظهور اللون الأصفر تحت الرسم
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(4),
//                             child: note.isImage
//                                 ? _buildImageDisplay(note.imageData)
//                                 : DisplaySignature(
//                                     drawingPoints: note.drawingPoints,
//                                     strokeColor:
//                                         contentColor, // تمرير لون الرسم
//                                   ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'بواسطة: ${note.author}',
//                         style: TextStyle(
//                           fontSize: cardHeight * 0.09,
//                           color: Colors.grey.shade700,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         'تم الإرسال: ${DateFormat.yMd().add_Hms().format(note.timestamp)}',
//                         style: TextStyle(
//                           fontSize: cardHeight * 0.07,
//                           color: Colors.grey.shade500,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Positioned(
//                   top: 2,
//                   right: 2,
//                   child: IconButton(
//                     icon: Icon(
//                       Icons.close,
//                       color: Colors.grey.shade700,
//                       size: 14,
//                     ),
//                     onPressed: () {
//                       notesService.deleteNote(note.id);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageDisplay(String? imageData) {
//     if (imageData == null || imageData.isEmpty) {
//       return Center(
//         child: Text(
//           'لا يمكن عرض الصورة',
//           style: TextStyle(color: Colors.grey, fontSize: 10),
//         ),
//       );
//     }
//     try {
//       final bytes = base64Decode(imageData);
//       return Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: Image.memory(
//           bytes,
//           fit: BoxFit.contain,
//           errorBuilder: (context, error, stackTrace) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error, color: Colors.red, size: 30),
//                   SizedBox(height: 4),
//                   Text(
//                     'خطأ',
//                     style: TextStyle(color: Colors.red, fontSize: 10),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       );
//     } catch (e) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.broken_image, color: Colors.orange, size: 30),
//             SizedBox(height: 4),
//             Text('تلف', style: TextStyle(color: Colors.orange, fontSize: 10)),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _backgroundController.dispose();
//     _puzzleController.dispose();
//     super.dispose();
//   }
// }

// // ----------------------------------------------------------------------
// // كلاسات عرض التوقيع
// // ----------------------------------------------------------------------

// class DisplaySignature extends StatelessWidget {
//   final List<List<Map<String, double>>> drawingPoints;
//   final Color strokeColor;

//   DisplaySignature({required this.drawingPoints, required this.strokeColor});

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       painter: SignaturePainter(drawingPoints, strokeColor: strokeColor),
//       child: Container(width: double.infinity, height: double.infinity),
//     );
//   }
// }

// class SignaturePainter extends CustomPainter {
//   final List<List<Map<String, double>>> drawingPoints;
//   final Color strokeColor;

//   SignaturePainter(this.drawingPoints, {this.strokeColor = Colors.black});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = strokeColor
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 4.0
//       ..style = PaintingStyle.stroke;

//     final fillPaint = Paint()
//       ..color = strokeColor
//       ..style = PaintingStyle.fill;

//     double minX = double.infinity;
//     double minY = double.infinity;
//     double maxX = double.negativeInfinity;
//     double maxY = double.negativeInfinity;
//     int pointCount = 0;

//     for (final stroke in drawingPoints) {
//       for (final point in stroke) {
//         final x = point['x']?.toDouble();
//         final y = point['y']?.toDouble();
//         if (x != null && y != null && x.isFinite && y.isFinite) {
//           minX = math.min(minX, x);
//           minY = math.min(minY, y);
//           maxX = math.max(maxX, x);
//           maxY = math.max(maxY, y);
//           pointCount++;
//         }
//       }
//     }

//     if (pointCount == 0 || !minX.isFinite || !maxX.isFinite) {
//       return;
//     }

//     final drawingWidth = maxX - minX;
//     final drawingHeight = maxY - minY;

//     final margin = 20.0;
//     final availableWidth = size.width - (2 * margin);
//     final availableHeight = size.height - (2 * margin);

//     double scale = 1.0;
//     if (drawingWidth > 0 && drawingHeight > 0) {
//       final scaleX = availableWidth / drawingWidth;
//       final scaleY = availableHeight / drawingHeight;
//       scale = math.min(scaleX, scaleY);
//     }

//     final scaledWidth = drawingWidth * scale;
//     final scaledHeight = drawingHeight * scale;
//     final offsetX = (size.width - scaledWidth) / 2 - (minX * scale);
//     final offsetY = (size.height - scaledHeight) / 2 - (minY * scale);

//     for (final stroke in drawingPoints) {
//       if (stroke.isEmpty) continue;

//       final path = Path();
//       final validPoints = <Offset>[];

//       for (final point in stroke) {
//         final x = point['x']?.toDouble();
//         final y = point['y']?.toDouble();
//         if (x != null && y != null && x.isFinite && y.isFinite) {
//           final scaledPoint = Offset(
//             (x * scale) + offsetX,
//             (y * scale) + offsetY,
//           );
//           validPoints.add(scaledPoint);
//         }
//       }

//       if (validPoints.isEmpty) continue;

//       if (validPoints.length == 1) {
//         canvas.drawCircle(validPoints[0], 3.0, fillPaint);
//       } else {
//         path.moveTo(validPoints[0].dx, validPoints[0].dy);
//         for (int i = 1; i < validPoints.length; i++) {
//           path.lineTo(validPoints[i].dx, validPoints[i].dy);
//         }
//         canvas.drawPath(path, paint);
//         for (final point in validPoints) {
//           canvas.drawCircle(point, 2.0, fillPaint);
//         }
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant SignaturePainter oldDelegate) {
//     return oldDelegate.drawingPoints != drawingPoints ||
//         oldDelegate.strokeColor != strokeColor;
//   }
// }
