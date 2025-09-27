import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:testwhiteboard/screens/puzzle_screen.dart';
import 'package:testwhiteboard/services.dart/sercives.dart';
import '../models/note_model.dart';

class DisplayScreen extends StatefulWidget {
  @override
  _DisplayScreenState createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  late AnimationController _puzzleController;
  late Animation<double> _puzzleAnimation;
  bool _isAssembling = false;

  final List<Offset> _scatteredStartPositions = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _puzzleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _puzzleAnimation = CurvedAnimation(
      parent: _puzzleController,
      curve: Curves.easeInOutQuad,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesService = Provider.of<NotesService>(context, listen: false);
      debugPrint(
        'Init: showPuzzleSuccess = ${notesService.showPuzzleSuccess}, completedPuzzleImage = ${notesService.completedPuzzleImage != null}',
      );
      _generateScatteredPositions(notesService.notes.length);
      notesService.addListener(_onNotesChanged); // إضافة المتابعة
    });
  }

  @override
  void dispose() {
    final notesService = Provider.of<NotesService>(context, listen: false);
    notesService.removeListener(_onNotesChanged); // إزالة المتابعة
    _backgroundController.dispose();
    _puzzleController.dispose();
    super.dispose();
  }

  void _generateScatteredPositions(int count) {
    _scatteredStartPositions.clear();
    if (count == 0) return;

    final size = MediaQuery.of(context).size;
    const double CARD_SCALE_FACTOR_W = 0.08;
    const double CARD_SCALE_FACTOR_H = 0.12;
    final double cardWidth = size.width * CARD_SCALE_FACTOR_W;
    final double cardHeight = size.height * CARD_SCALE_FACTOR_H;

    final double center_x = size.width / 2 - cardWidth / 2;
    final double center_y = size.height / 2 - cardHeight / 2;

    final double scatterRadiusX = size.width * 0.40;
    final double scatterRadiusY = size.height * 0.40;

    for (int i = 0; i < count; i++) {
      final double randomX =
          center_x + (_random.nextDouble() * 2 - 1) * scatterRadiusX;
      final double randomY =
          center_y + (_random.nextDouble() * 2 - 1) * scatterRadiusY;

      final double safeX = math.max(
        0,
        math.min(randomX, size.width - cardWidth),
      );
      final double safeY = math.max(
        kToolbarHeight,
        math.min(randomY, size.height - cardHeight),
      );

      _scatteredStartPositions.add(Offset(safeX, safeY));
    }
  }

  void _onNotesChanged() {
    setState(() {}); // إعادة بناء الشاشة عند تغيير NotesService
    final notesService = Provider.of<NotesService>(context, listen: false);
    debugPrint(
      'onNotesChanged: showPuzzleSuccess = ${notesService.showPuzzleSuccess}, completedPuzzleImage = ${notesService.completedPuzzleImage != null}',
    );
  }

  double _calculateDynamicGap(
    Size screenSize,
    int totalNotes,
    double cardWidth,
    double cardHeight,
  ) {
    if (totalNotes == 0) return 10.0;

    final double screenWidth = screenSize.width;
    const int maxColumns = 10;
    const int maxRows = 5;
    final double availableWidth = screenWidth * 0.8;
    final double availableHeight = screenSize.height * 0.6;

    final double maxWidthForCards = maxColumns * cardWidth;
    final double maxHeightForCards = maxRows * cardHeight;

    final double gapWidth =
        (availableWidth - maxWidthForCards) / (maxColumns - 1);
    final double gapHeight =
        (availableHeight - maxHeightForCards) / (maxRows - 1);

    double calculatedGap = math.min(gapWidth, gapHeight);
    calculatedGap = math.max(2.0, calculatedGap);
    calculatedGap = math.min(20.0, calculatedGap);

    if (totalNotes > 30) {
      calculatedGap *= 0.7;
    } else if (totalNotes > 20) {
      calculatedGap *= 0.85;
    }

    return calculatedGap;
  }

  List<Offset> _getTargetPositions(
    Size screenSize,
    int totalNotes,
    double cardWidth,
    double cardHeight,
  ) {
    if (totalNotes == 0) return [];

    final double gap = _calculateDynamicGap(
      screenSize,
      totalNotes,
      cardWidth,
      cardHeight,
    );

    final List<List<int>> pattern95 = [
      [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
      [1, 0, 1, 0, 0, 1, 0, 0, 0, 0],
      [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
      [0, 0, 1, 0, 0, 0, 0, 0, 0, 1],
      [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
    ];

    final List<Offset> required95Positions = [];
    for (int r = 0; r < pattern95.length; r++) {
      for (int c = 0; c < pattern95[0].length; c++) {
        if (pattern95[r][c] == 1) {
          final double x = c * (cardWidth + gap);
          final double y = r * (cardHeight + gap);
          required95Positions.add(Offset(x, y));
        }
      }
    }

    final int count95 = required95Positions.length;
    final double maxColIndex =
        (pattern95.map((row) => row.lastIndexOf(1)).reduce(math.max))
            .toDouble();
    final double actualPatternWidth =
        (maxColIndex + 1) * cardWidth + maxColIndex * gap;
    final double actualPatternHeight =
        pattern95.length * cardHeight + (pattern95.length - 1) * gap;

    final double offsetX = screenSize.width / 2 - actualPatternWidth / 2;
    final double offsetY = screenSize.height / 2 - actualPatternHeight / 2;

    final List<Offset> finalPositions = [];
    for (int i = 0; i < totalNotes; i++) {
      final int targetIndex = i % count95;
      final Offset basePosition = required95Positions[targetIndex];

      final Offset finalOffset = Offset(
        basePosition.dx + offsetX,
        basePosition.dy + offsetY,
      );
      final double stackingJitter = (i % 10).toDouble() * (gap < 5 ? 0.2 : 0.5);

      finalPositions.add(
        Offset(
          finalOffset.dx + stackingJitter,
          finalOffset.dy + stackingJitter,
        ),
      );
    }

    return finalPositions;
  }

  void _confirmAndDeleteAll(BuildContext context, NotesService notesService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد المسح'),
        content: Text(
          'هل أنت متأكد من أنك تريد مسح جميع الكروت نهائيًا؟ سيتم حذفها من قاعدة البيانات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notesService.clearAllNotes();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم مسح جميع الكروت بنجاح.')),
              );
            },
            child: Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const double CARD_SCALE_FACTOR_W = 0.08;
    const double CARD_SCALE_FACTOR_H = 0.12;
    final double cardWidth = size.width * CARD_SCALE_FACTOR_W;
    final double cardHeight = size.height * CARD_SCALE_FACTOR_H;
    final centerPoint = Offset(
      size.width / 2 - cardWidth / 2,
      size.height / 2 - cardHeight / 2,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage(
              'assets/images/WhatsApp Image 2025-09-27 at 7.44.50 AM (1).jpeg',
            ),
            fit: BoxFit.fill,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Consumer<NotesService>(
          builder: (context, notesService, child) {
            debugPrint(
              'DisplayScreen: showPuzzleSuccess = ${notesService.showPuzzleSuccess}, completedPuzzleImage = ${notesService.completedPuzzleImage != null}',
            );

            if (_scatteredStartPositions.length != notesService.notes.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _generateScatteredPositions(notesService.notes.length);
                if (!_isAssembling) {
                  setState(() {
                    _puzzleController.reverse(from: 1.0);
                  });
                }
              });
            }

            return Stack(
              children: [
                // الشاشة الأساسية للكروت
                if (!notesService.showPuzzleSuccess) ...[
                  if (notesService.notes.isEmpty)
                    Center(
                      child: Text(
                        'لا توجد كروت لعرضها. اضف كروت جديدة!',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final notes = notesService.notes;
                        final targetPositions = _getTargetPositions(
                          size,
                          notes.length,
                          cardWidth,
                          cardHeight,
                        );

                        return Stack(
                          children: notes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final note = entry.value;
                            final Offset endOffset = targetPositions[index];
                            final Offset scatteredPosition =
                                _scatteredStartPositions.length > index
                                ? _scatteredStartPositions[index]
                                : centerPoint;
                            final Offset startAnimationPoint = _isAssembling
                                ? scatteredPosition
                                : scatteredPosition;
                            final Offset targetAnimationPoint = _isAssembling
                                ? endOffset
                                : scatteredPosition;

                            return AnimatedBuilder(
                              animation: _puzzleAnimation,
                              builder: (context, child) {
                                final currentX =
                                    startAnimationPoint.dx +
                                    (_puzzleAnimation.value *
                                        (targetAnimationPoint.dx -
                                            startAnimationPoint.dx));
                                final currentY =
                                    startAnimationPoint.dy +
                                    (_puzzleAnimation.value *
                                        (targetAnimationPoint.dy -
                                            startAnimationPoint.dy));
                                return Positioned(
                                  left: currentX,
                                  top: currentY,
                                  child: child!,
                                );
                              },
                              child: _buildNoteWidget(
                                context,
                                note,
                                notesService,
                                cardWidth,
                                cardHeight,
                                index,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],

                // طبقة عرض البازل المكتمل - مثل PuzzleGameScreen
                if (notesService.showPuzzleSuccess)
                  Container(
                    width: size.width,
                    height: size.height,
                    color: Colors.black.withOpacity(0.7), // خلفية شفافة
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(30),
                        margin: EdgeInsets.symmetric(horizontal: 50),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // أيقونة الفوز
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade600,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 20),

                              // رسالة التهنئة
                              Text(
                                'مبروك!',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              SizedBox(height: 10),

                              Text(
                                notesService.puzzleWinnerName.isEmpty
                                    ? 'لاعب مجهول'
                                    : notesService.puzzleWinnerName,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(height: 10),

                              // إضافة معلومات الوقت إذا كانت متوفرة
                              if (notesService.lastSuccessData != null)
                                Text(
                                  'أكملت البازل بنجاح في ${notesService.lastSuccessData!.secondsElapsed} ثانية!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                              SizedBox(height: 30),

                              // عرض الصورة المكتملة
                              if (notesService.completedPuzzleImage != null)
                                Container(
                                  width: 300,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: CustomPaint(
                                      painter: CompletedImagePainter(
                                        notesService.completedPuzzleImage!,
                                      ),
                                      size: Size(300, 200),
                                    ),
                                  ),
                                ),

                              SizedBox(height: 15),

                              Text(
                                'تم عرض نتيجتك على الشاشة الأخرى!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade600,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Consumer<NotesService>(
        builder: (context, notesService, child) {
          if (notesService.notes.isEmpty || notesService.showPuzzleSuccess) {
            return SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                _isAssembling = !_isAssembling;
                if (_isAssembling) {
                  _puzzleController.forward(from: 0.0);
                } else {
                  _generateScatteredPositions(notesService.notes.length);
                  _puzzleController.reverse(from: 1.0);
                }
              });
            },
            label: Text(
              _isAssembling ? 'تفكيك الكروت' : 'تجميع الرقم 95',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: Icon(_isAssembling ? Icons.scatter_plot : Icons.grid_on),
            backgroundColor: Colors.orange.shade700,
          );
        },
      ),
    );
  }
}

Widget _buildNoteWidget(
  BuildContext context,
  NoteModel note,
  NotesService notesService,
  double cardWidth,
  double cardHeight,
  int index,
) {
  final Color contentColor = note.color;
  return Transform.rotate(
    angle: (index % 10) * 0.01 - 0.05,
    child: Container(
      width: cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.yellow.shade500,
        elevation: 8,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: note.isImage
                              ? _buildImageDisplay(note.imageData)
                              : DisplaySignature(
                                  drawingPoints: note.drawingPoints,
                                  strokeColor: contentColor,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildImageDisplay(String? imageData) {
  if (imageData == null || imageData.isEmpty)
    return Center(
      child: Text(
        'لا يمكن عرض الصورة',
        style: TextStyle(color: Colors.grey, fontSize: 10),
      ),
    );
  try {
    final bytes = base64Decode(imageData);
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 30),
            SizedBox(height: 4),
            Text('خطأ', style: TextStyle(color: Colors.red, fontSize: 10)),
          ],
        ),
      ),
    );
  } catch (e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.orange, size: 30),
          SizedBox(height: 4),
          Text('تلف', style: TextStyle(color: Colors.orange, fontSize: 10)),
        ],
      ),
    );
  }
}

class DisplaySignature extends StatelessWidget {
  final List<List<Map<String, double>>> drawingPoints;
  final Color strokeColor;

  DisplaySignature({required this.drawingPoints, required this.strokeColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SignaturePainter(drawingPoints, strokeColor: strokeColor),
      child: Container(width: double.infinity, height: double.infinity),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<List<Map<String, double>>> drawingPoints;
  final Color strokeColor;

  SignaturePainter(this.drawingPoints, {this.strokeColor = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    double minX = double.infinity,
        minY = double.infinity,
        maxX = double.negativeInfinity,
        maxY = double.negativeInfinity;
    int pointCount = 0;

    for (final stroke in drawingPoints) {
      for (final point in stroke) {
        final x = point['x']?.toDouble();
        final y = point['y']?.toDouble();
        if (x != null && y != null && x.isFinite && y.isFinite) {
          minX = math.min(minX, x);
          minY = math.min(minY, y);
          maxX = math.max(maxX, x);
          maxY = math.max(maxY, y);
          pointCount++;
        }
      }
    }

    if (pointCount == 0 || !minX.isFinite || !maxX.isFinite) return;

    final drawingWidth = maxX - minX;
    final drawingHeight = maxY - minY;
    final margin = 20.0;
    final availableWidth = size.width - (2 * margin);
    final availableHeight = size.height - (2 * margin);

    double scale = 1.0;
    if (drawingWidth > 0 && drawingHeight > 0) {
      final scaleX = availableWidth / drawingWidth;
      final scaleY = availableHeight / drawingHeight;
      scale = math.min(scaleX, scaleY);
    }

    final scaledWidth = drawingWidth * scale;
    final scaledHeight = drawingHeight * scale;
    final offsetX = (size.width - scaledWidth) / 2 - (minX * scale);
    final offsetY = (size.height - scaledHeight) / 2 - (minY * scale);

    for (final stroke in drawingPoints) {
      if (stroke.isEmpty) continue;
      final path = Path();
      final validPoints = <Offset>[];
      for (final point in stroke) {
        final x = point['x']?.toDouble();
        final y = point['y']?.toDouble();
        if (x != null && y != null && x.isFinite && y.isFinite)
          validPoints.add(Offset((x * scale) + offsetX, (y * scale) + offsetY));
      }
      if (validPoints.isEmpty) continue;

      if (validPoints.length == 1) {
        canvas.drawCircle(validPoints[0], 3.0, fillPaint);
      } else {
        path.moveTo(validPoints[0].dx, validPoints[0].dy);
        for (int i = 1; i < validPoints.length; i++)
          path.lineTo(validPoints[i].dx, validPoints[i].dy);
        canvas.drawPath(path, paint);
        for (final point in validPoints)
          canvas.drawCircle(point, 2.0, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    return oldDelegate.drawingPoints != drawingPoints ||
        oldDelegate.strokeColor != strokeColor;
  }
}

class CompletedImagePainter extends CustomPainter {
  final ui.Image image;

  CompletedImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
// import 'dart:convert';
// import 'dart:math' as math;
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:testwhiteboard/screens/puzzle_screen.dart';
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

//   // متحكمات الرسوم المتحركة للفوز
//   late AnimationController _winAnimationController;
//   late Animation<double> _winScaleAnimation;
//   late Animation<double> _winOpacityAnimation;
//   late Animation<Offset> _winSlideAnimation;

//   final List<Offset> _scatteredStartPositions = [];
//   final math.Random _random = math.Random();

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

//     _winAnimationController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     );

//     _winScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _winAnimationController,
//         curve: Curves.elasticOut,
//       ),
//     );

//     _winOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _winAnimationController, curve: Curves.easeInOut),
//     );

//     _winSlideAnimation = Tween<Offset>(begin: Offset(0, -1), end: Offset.zero)
//         .animate(
//           CurvedAnimation(
//             parent: _winAnimationController,
//             curve: Curves.bounceOut,
//           ),
//         );

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final notesService = Provider.of<NotesService>(context, listen: false);
//       debugPrint(
//         'Init: showPuzzleSuccess = ${notesService.showPuzzleSuccess}, completedPuzzleImage = ${notesService.completedPuzzleImage != null}',
//       );
//       _generateScatteredPositions(notesService.notes.length);
//       notesService.addListener(_onNotesChanged); // إضافة المتابعة
//     });
//   }

//   @override
//   void dispose() {
//     final notesService = Provider.of<NotesService>(context, listen: false);
//     notesService.removeListener(_onNotesChanged); // إزالة المتابعة
//     _backgroundController.dispose();
//     _puzzleController.dispose();
//     _winAnimationController.dispose();
//     super.dispose();
//   }

//   void _generateScatteredPositions(int count) {
//     _scatteredStartPositions.clear();
//     if (count == 0) return;

//     final size = MediaQuery.of(context).size;
//     const double CARD_SCALE_FACTOR_W = 0.08;
//     const double CARD_SCALE_FACTOR_H = 0.12;
//     final double cardWidth = size.width * CARD_SCALE_FACTOR_W;
//     final double cardHeight = size.height * CARD_SCALE_FACTOR_H;

//     final double center_x = size.width / 2 - cardWidth / 2;
//     final double center_y = size.height / 2 - cardHeight / 2;

//     final double scatterRadiusX = size.width * 0.40;
//     final double scatterRadiusY = size.height * 0.40;

//     for (int i = 0; i < count; i++) {
//       final double randomX =
//           center_x + (_random.nextDouble() * 2 - 1) * scatterRadiusX;
//       final double randomY =
//           center_y + (_random.nextDouble() * 2 - 1) * scatterRadiusY;

//       final double safeX = math.max(
//         0,
//         math.min(randomX, size.width - cardWidth),
//       );
//       final double safeY = math.max(
//         kToolbarHeight,
//         math.min(randomY, size.height - cardHeight),
//       );

//       _scatteredStartPositions.add(Offset(safeX, safeY));
//     }
//   }

//   void _onNotesChanged() {
//     setState(() {}); // إعادة بناء الشاشة عند تغيير NotesService
//     final notesService = Provider.of<NotesService>(context, listen: false);
//     debugPrint(
//       'onNotesChanged: showPuzzleSuccess = ${notesService.showPuzzleSuccess}, completedPuzzleImage = ${notesService.completedPuzzleImage != null}',
//     );
//     if (notesService.showPuzzleSuccess &&
//         !_winAnimationController.isAnimating) {
//       _winAnimationController.forward();
//     } else if (!notesService.showPuzzleSuccess &&
//         _winAnimationController.isCompleted) {
//       _winAnimationController.reset();
//     }
//   }

//   double _calculateDynamicGap(
//     Size screenSize,
//     int totalNotes,
//     double cardWidth,
//     double cardHeight,
//   ) {
//     if (totalNotes == 0) return 10.0;

//     final double screenWidth = screenSize.width;
//     const int maxColumns = 10;
//     const int maxRows = 5;
//     final double availableWidth = screenWidth * 0.8;
//     final double availableHeight = screenSize.height * 0.6;

//     final double maxWidthForCards = maxColumns * cardWidth;
//     final double maxHeightForCards = maxRows * cardHeight;

//     final double gapWidth =
//         (availableWidth - maxWidthForCards) / (maxColumns - 1);
//     final double gapHeight =
//         (availableHeight - maxHeightForCards) / (maxRows - 1);

//     double calculatedGap = math.min(gapWidth, gapHeight);
//     calculatedGap = math.max(2.0, calculatedGap);
//     calculatedGap = math.min(20.0, calculatedGap);

//     if (totalNotes > 30) {
//       calculatedGap *= 0.7;
//     } else if (totalNotes > 20) {
//       calculatedGap *= 0.85;
//     }

//     return calculatedGap;
//   }

//   List<Offset> _getTargetPositions(
//     Size screenSize,
//     int totalNotes,
//     double cardWidth,
//     double cardHeight,
//   ) {
//     if (totalNotes == 0) return [];

//     final double gap = _calculateDynamicGap(
//       screenSize,
//       totalNotes,
//       cardWidth,
//       cardHeight,
//     );

//     final List<List<int>> pattern95 = [
//       [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
//       [1, 0, 1, 0, 0, 1, 0, 0, 0, 0],
//       [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
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
//     final double maxColIndex =
//         (pattern95.map((row) => row.lastIndexOf(1)).reduce(math.max))
//             .toDouble();
//     final double actualPatternWidth =
//         (maxColIndex + 1) * cardWidth + maxColIndex * gap;
//     final double actualPatternHeight =
//         pattern95.length * cardHeight + (pattern95.length - 1) * gap;

//     final double offsetX = screenSize.width / 2 - actualPatternWidth / 2;
//     final double offsetY = screenSize.height / 2 - actualPatternHeight / 2;

//     final List<Offset> finalPositions = [];
//     for (int i = 0; i < totalNotes; i++) {
//       final int targetIndex = i % count95;
//       final Offset basePosition = required95Positions[targetIndex];

//       final Offset finalOffset = Offset(
//         basePosition.dx + offsetX,
//         basePosition.dy + offsetY,
//       );
//       final double stackingJitter = (i % 10).toDouble() * (gap < 5 ? 0.2 : 0.5);

//       finalPositions.add(
//         Offset(
//           finalOffset.dx + stackingJitter,
//           finalOffset.dy + stackingJitter,
//         ),
//       );
//     }

//     return finalPositions;
//   }

//   void _confirmAndDeleteAll(BuildContext context, NotesService notesService) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('تأكيد المسح'),
//         content: Text(
//           'هل أنت متأكد من أنك تريد مسح جميع الكروت نهائيًا؟ سيتم حذفها من قاعدة البيانات.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('إلغاء'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               notesService.clearAllNotes();
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('تم مسح جميع الكروت بنجاح.')),
//               );
//             },
//             child: Text('مسح الكل', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     const double CARD_SCALE_FACTOR_W = 0.08;
//     const double CARD_SCALE_FACTOR_H = 0.12;
//     final double cardWidth = size.width * CARD_SCALE_FACTOR_W;
//     final double cardHeight = size.height * CARD_SCALE_FACTOR_H;
//     final centerPoint = Offset(
//       size.width / 2 - cardWidth / 2,
//       size.height / 2 - cardHeight / 2,
//     );

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Container(
//         width: size.width,
//         height: size.height,
//         decoration: BoxDecoration(
//           color: Colors.black,
//           image: DecorationImage(
//             image: AssetImage(
//               'assets/images/WhatsApp Image 2025-09-27 at 7.44.50 AM (1).jpeg',
//             ),
//             fit: BoxFit.fill,
//             colorFilter: ColorFilter.mode(
//               Colors.black.withOpacity(0.3),
//               BlendMode.darken,
//             ),
//           ),
//         ),
//         child: Consumer<NotesService>(
//           builder: (context, notesService, child) {
//             debugPrint(
//               'DisplayScreen: showPuzzleSuccess = ${notesService.showPuzzleSuccess}, completedPuzzleImage = ${notesService.completedPuzzleImage != null}',
//             );

//             if (_scatteredStartPositions.length != notesService.notes.length) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 _generateScatteredPositions(notesService.notes.length);
//                 if (!_isAssembling) {
//                   setState(() {
//                     _puzzleController.reverse(from: 1.0);
//                   });
//                 }
//               });
//             }

//             return Stack(
//               children: [
//                 // الشاشة الأساسية للكروت
//                 if (!notesService.showPuzzleSuccess) ...[
//                   if (notesService.notes.isEmpty)
//                     Center(
//                       child: Text(
//                         'لا توجد كروت لعرضها. اضف كروت جديدة!',
//                         style: TextStyle(
//                           fontSize: 24,
//                           color: Colors.white70,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     )
//                   else
//                     Builder(
//                       builder: (context) {
//                         final notes = notesService.notes;
//                         final targetPositions = _getTargetPositions(
//                           size,
//                           notes.length,
//                           cardWidth,
//                           cardHeight,
//                         );

//                         return Stack(
//                           children: notes.asMap().entries.map((entry) {
//                             final index = entry.key;
//                             final note = entry.value;
//                             final Offset endOffset = targetPositions[index];
//                             final Offset scatteredPosition =
//                                 _scatteredStartPositions.length > index
//                                 ? _scatteredStartPositions[index]
//                                 : centerPoint;
//                             final Offset startAnimationPoint = _isAssembling
//                                 ? scatteredPosition
//                                 : scatteredPosition;
//                             final Offset targetAnimationPoint = _isAssembling
//                                 ? endOffset
//                                 : scatteredPosition;

//                             return AnimatedBuilder(
//                               animation: _puzzleAnimation,
//                               builder: (context, child) {
//                                 final currentX =
//                                     startAnimationPoint.dx +
//                                     (_puzzleAnimation.value *
//                                         (targetAnimationPoint.dx -
//                                             startAnimationPoint.dx));
//                                 final currentY =
//                                     startAnimationPoint.dy +
//                                     (_puzzleAnimation.value *
//                                         (targetAnimationPoint.dy -
//                                             startAnimationPoint.dy));
//                                 return Positioned(
//                                   left: currentX,
//                                   top: currentY,
//                                   child: child!,
//                                 );
//                               },
//                               child: _buildNoteWidget(
//                                 context,
//                                 note,
//                                 notesService,
//                                 cardWidth,
//                                 cardHeight,
//                                 index,
//                               ),
//                             );
//                           }).toList(),
//                         );
//                       },
//                     ),
//                 ],

//                 // طبقة عرض البازل المكتمل المحسّنة
//                 if (notesService.showPuzzleSuccess)
//                   AnimatedBuilder(
//                     animation: _winAnimationController,
//                     builder: (context, child) {
//                       if (notesService.completedPuzzleImage == null) {
//                         debugPrint('DisplayScreen: No completed puzzle image');
//                         return Center(
//                           child: Text(
//                             'فشل عرض الصورة المكتملة (تحقق من PuzzleGameScreen)',
//                             style: TextStyle(color: Colors.white, fontSize: 20),
//                           ),
//                         ); // عرض رسالة تشخيص
//                       }
//                       return Container(
//                         width: size.width,
//                         height: size.height,
//                         color: Colors.black.withOpacity(
//                           0.90 * _winOpacityAnimation.value,
//                         ),
//                         child: Transform.scale(
//                           scale: _winScaleAnimation.value,
//                           child: SlideTransition(
//                             position: _winSlideAnimation,
//                             child: Center(
//                               child: Container(
//                                 padding: EdgeInsets.all(40),
//                                 margin: EdgeInsets.symmetric(horizontal: 20),
//                                 constraints: BoxConstraints(
//                                   maxWidth: size.width * 0.9,
//                                   maxHeight: size.height * 0.85,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: [
//                                       Colors.yellow.shade300,
//                                       Colors.orange.shade400,
//                                       Colors.red.shade300,
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(30),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.4),
//                                       blurRadius: 25,
//                                       offset: Offset(0, 15),
//                                     ),
//                                     BoxShadow(
//                                       color: Colors.yellow.withOpacity(0.6),
//                                       blurRadius: 40,
//                                       spreadRadius: 10,
//                                     ),
//                                   ],
//                                   border: Border.all(
//                                     color: Colors.white,
//                                     width: 4,
//                                   ),
//                                 ),
//                                 child: SingleChildScrollView(
//                                   child: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       AnimatedBuilder(
//                                         animation: _backgroundAnimation,
//                                         builder: (context, child) {
//                                           return Transform.rotate(
//                                             angle:
//                                                 _backgroundAnimation.value *
//                                                 0.2,
//                                             child: Container(
//                                               width: 120,
//                                               height: 120,
//                                               decoration: BoxDecoration(
//                                                 color: Colors.yellow.shade600,
//                                                 shape: BoxShape.circle,
//                                                 boxShadow: [
//                                                   BoxShadow(
//                                                     color: Colors.black
//                                                         .withOpacity(0.3),
//                                                     blurRadius: 20,
//                                                     offset: Offset(0, 8),
//                                                   ),
//                                                 ],
//                                                 border: Border.all(
//                                                   color: Colors.white,
//                                                   width: 3,
//                                                 ),
//                                               ),
//                                               child: Icon(
//                                                 Icons.emoji_events,
//                                                 size: 70,
//                                                 color: Colors.white,
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       ),

//                                       SizedBox(height: 25),

//                                       Text(
//                                         'مبروك!',
//                                         style: TextStyle(
//                                           fontSize: 56,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.white,
//                                           shadows: [
//                                             Shadow(
//                                               color: Colors.black.withOpacity(
//                                                 0.6,
//                                               ),
//                                               blurRadius: 15,
//                                               offset: Offset(3, 3),
//                                             ),
//                                           ],
//                                         ),
//                                       ),

//                                       SizedBox(height: 15),

//                                       Container(
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: 30,
//                                           vertical: 15,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.white,
//                                           borderRadius: BorderRadius.circular(
//                                             20,
//                                           ),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: Colors.black.withOpacity(
//                                                 0.2,
//                                               ),
//                                               blurRadius: 15,
//                                               offset: Offset(0, 5),
//                                             ),
//                                           ],
//                                           border: Border.all(
//                                             color: Colors.orange.shade400,
//                                             width: 3,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           notesService.puzzleWinnerName.isEmpty
//                                               ? 'لاعب مجهول'
//                                               : notesService.puzzleWinnerName,
//                                           style: TextStyle(
//                                             fontSize: 42,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.orange.shade700,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),

//                                       SizedBox(height: 20),

//                                       Text(
//                                         'أكمل البازل بنجاح!',
//                                         style: TextStyle(
//                                           fontSize: 28,
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.w700,
//                                           shadows: [
//                                             Shadow(
//                                               color: Colors.black.withOpacity(
//                                                 0.5,
//                                               ),
//                                               blurRadius: 8,
//                                               offset: Offset(2, 2),
//                                             ),
//                                           ],
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),

//                                       SizedBox(height: 30),

//                                       if (notesService.completedPuzzleImage !=
//                                           null)
//                                         Container(
//                                           width: math.min(
//                                             400,
//                                             size.width * 0.7,
//                                           ),
//                                           height: math.min(
//                                             267,
//                                             size.width * 0.7 * 2 / 3,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             borderRadius: BorderRadius.circular(
//                                               25,
//                                             ),
//                                             boxShadow: [
//                                               BoxShadow(
//                                                 color: Colors.black.withOpacity(
//                                                   0.5,
//                                                 ),
//                                                 blurRadius: 20,
//                                                 offset: Offset(0, 10),
//                                               ),
//                                               BoxShadow(
//                                                 color: Colors.white.withOpacity(
//                                                   0.4,
//                                                 ),
//                                                 blurRadius: 25,
//                                                 spreadRadius: -5,
//                                               ),
//                                             ],
//                                             border: Border.all(
//                                               color: Colors.white,
//                                               width: 5,
//                                             ),
//                                           ),
//                                           child: ClipRRect(
//                                             borderRadius: BorderRadius.circular(
//                                               20,
//                                             ),
//                                             child: CustomPaint(
//                                               painter: CompletedImagePainter(
//                                                 notesService
//                                                     .completedPuzzleImage!,
//                                               ),
//                                               size: Size(
//                                                 math.min(400, size.width * 0.7),
//                                                 math.min(
//                                                   267,
//                                                   size.width * 0.7 * 2 / 3,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),

//                                       SizedBox(height: 25),

//                                       Container(
//                                         padding: EdgeInsets.all(20),
//                                         decoration: BoxDecoration(
//                                           color: Colors.white.withOpacity(0.95),
//                                           borderRadius: BorderRadius.circular(
//                                             20,
//                                           ),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: Colors.black.withOpacity(
//                                                 0.1,
//                                               ),
//                                               blurRadius: 10,
//                                               offset: Offset(0, 3),
//                                             ),
//                                           ],
//                                         ),
//                                         child: Text(
//                                           'هذه الرسالة ستختفي قريباً...',
//                                           style: TextStyle(
//                                             fontSize: 18,
//                                             color: Colors.grey.shade700,
//                                             fontStyle: FontStyle.italic,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//               ],
//             );
//           },
//         ),
//       ),
//       floatingActionButton: Consumer<NotesService>(
//         builder: (context, notesService, child) {
//           if (notesService.notes.isEmpty || notesService.showPuzzleSuccess) {
//             return SizedBox.shrink();
//           }
//           return FloatingActionButton.extended(
//             onPressed: () {
//               setState(() {
//                 _isAssembling = !_isAssembling;
//                 if (_isAssembling) {
//                   _puzzleController.forward(from: 0.0);
//                 } else {
//                   _generateScatteredPositions(notesService.notes.length);
//                   _puzzleController.reverse(from: 1.0);
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
// }

// Widget _buildNoteWidget(
//   BuildContext context,
//   NoteModel note,
//   NotesService notesService,
//   double cardWidth,
//   double cardHeight,
//   int index,
// ) {
//   final Color contentColor = note.color;
//   return Transform.rotate(
//     angle: (index % 10) * 0.01 - 0.05,
//     child: Container(
//       width: cardWidth,
//       height: cardHeight,
//       child: Material(
//         color: Colors.yellow.shade500,
//         elevation: 8,
//         borderRadius: BorderRadius.circular(5),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(5),
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(5.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Container(
//                         width: double.infinity,
//                         height: double.infinity,
//                         decoration: BoxDecoration(
//                           color: Colors.transparent,
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(4),
//                           child: note.isImage
//                               ? _buildImageDisplay(note.imageData)
//                               : DisplaySignature(
//                                   drawingPoints: note.drawingPoints,
//                                   strokeColor: contentColor,
//                                 ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

// Widget _buildImageDisplay(String? imageData) {
//   if (imageData == null || imageData.isEmpty)
//     return Center(
//       child: Text(
//         'لا يمكن عرض الصورة',
//         style: TextStyle(color: Colors.grey, fontSize: 10),
//       ),
//     );
//   try {
//     final bytes = base64Decode(imageData);
//     return Image.memory(
//       bytes,
//       fit: BoxFit.contain,
//       errorBuilder: (context, error, stackTrace) => Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error, color: Colors.red, size: 30),
//             SizedBox(height: 4),
//             Text('خطأ', style: TextStyle(color: Colors.red, fontSize: 10)),
//           ],
//         ),
//       ),
//     );
//   } catch (e) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.broken_image, color: Colors.orange, size: 30),
//           SizedBox(height: 4),
//           Text('تلف', style: TextStyle(color: Colors.orange, fontSize: 10)),
//         ],
//       ),
//     );
//   }
// }

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

//     double minX = double.infinity,
//         minY = double.infinity,
//         maxX = double.negativeInfinity,
//         maxY = double.negativeInfinity;
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

//     if (pointCount == 0 || !minX.isFinite || !maxX.isFinite) return;

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
//         if (x != null && y != null && x.isFinite && y.isFinite)
//           validPoints.add(Offset((x * scale) + offsetX, (y * scale) + offsetY));
//       }
//       if (validPoints.isEmpty) continue;

//       if (validPoints.length == 1) {
//         canvas.drawCircle(validPoints[0], 3.0, fillPaint);
//       } else {
//         path.moveTo(validPoints[0].dx, validPoints[0].dy);
//         for (int i = 1; i < validPoints.length; i++)
//           path.lineTo(validPoints[i].dx, validPoints[i].dy);
//         canvas.drawPath(path, paint);
//         for (final point in validPoints)
//           canvas.drawCircle(point, 2.0, fillPaint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant SignaturePainter oldDelegate) {
//     return oldDelegate.drawingPoints != drawingPoints ||
//         oldDelegate.strokeColor != strokeColor;
//   }
// }

// class CompletedImagePainter extends CustomPainter {
//   final ui.Image image;

//   CompletedImagePainter(this.image);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final srcRect = Rect.fromLTWH(
//       0,
//       0,
//       image.width.toDouble(),
//       image.height.toDouble(),
//     );
//     final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
//     canvas.drawImageRect(image, srcRect, dstRect, Paint());
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }
