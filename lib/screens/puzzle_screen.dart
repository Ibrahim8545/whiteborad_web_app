import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// تأكد من أن هذه الملفات موجودة في مشروعك
import 'package:testwhiteboard/models/position.dart';
import 'package:testwhiteboard/screens/interactive_tablet_screen.dart';
import 'package:testwhiteboard/services.dart/sercives.dart';

class PuzzleGameScreen extends StatefulWidget {
  @override
  _PuzzleGameScreenState createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  String playerName = '';
  bool gameStarted = false;
  bool gameCompleted = false;
  bool showWinScreen = false; // إضافة متغير لعرض شاشة الفوز
  List<PuzzlePiece> puzzlePieces = [];
  DateTime? gameStartTime;
  Timer? gameTimer;
  int secondsElapsed = 0;

  // صورة البازل الأساسية
  ui.Image? puzzleImage;
  bool imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPuzzleImage();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPuzzleImage() async {
    try {
      // استخدام الصورة الموجودة في المشروع
      final ByteData data = await rootBundle.load('assets/images/puzzle.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      setState(() {
        puzzleImage = frameInfo.image;
        imageLoaded = true;
      });

      _generatePuzzlePieces();
    } catch (e) {
      print('خطأ في تحميل الصورة: $e');
      // في حالة فشل التحميل، إنشاء صورة بديلة
      _createFallbackImage();
    }
  }

  // إنشاء صورة بديلة في حالة فشل التحميل
  void _createFallbackImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.green.shade600;

    // رسم مستطيل أخضر بسيط
    canvas.drawRect(Rect.fromLTWH(0, 0, 300, 200), paint);

    // إضافة نص
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'صورة البازل',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(150 - textPainter.width / 2, 100 - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(300, 200);

    setState(() {
      puzzleImage = image;
      imageLoaded = true;
    });

    _generatePuzzlePieces();
  }

  void _generatePuzzlePieces() {
    if (puzzleImage == null) return;

    puzzlePieces.clear();

    // تقسيم الصورة إلى 6 قطع (2x3)
    final double pieceWidth = puzzleImage!.width / 3;
    final double pieceHeight = puzzleImage!.height / 2;

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        final int index = row * 3 + col;
        puzzlePieces.add(
          PuzzlePiece(
            id: index,
            correctRow: row,
            correctCol: col,
            currentRow: row,
            currentCol: col,
            sourceRect: Rect.fromLTWH(
              col * pieceWidth,
              row * pieceHeight,
              pieceWidth,
              pieceHeight,
            ),
          ),
        );
      }
    }

    // خلط القطع
    _shufflePieces();
  }

  void _shufflePieces() {
    final random = math.Random();

    // إنشاء قائمة بجميع المواضع المتاحة
    List<Position> availablePositions = [];
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        availablePositions.add(Position(row, col));
      }
    }

    // خلط المواضع عشوائياً
    availablePositions.shuffle(random);

    // تعيين مواضع جديدة للقطع
    for (int i = 0; i < puzzlePieces.length; i++) {
      final newPosition = availablePositions[i];
      puzzlePieces[i].currentRow = newPosition.row;
      puzzlePieces[i].currentCol = newPosition.col;
    }

    // التأكد من أن القطع ليست في مواضعها الصحيحة (اختياري)
    bool allCorrect = true;
    do {
      allCorrect = true;
      for (int i = 0; i < puzzlePieces.length; i++) {
        if (puzzlePieces[i].isInCorrectPosition()) {
          // إذا كانت القطعة في الموضع الصحيح، بدّلها مع قطعة أخرى
          int swapIndex = (i + 1) % puzzlePieces.length;
          final tempRow = puzzlePieces[i].currentRow;
          final tempCol = puzzlePieces[i].currentCol;

          puzzlePieces[i].currentRow = puzzlePieces[swapIndex].currentRow;
          puzzlePieces[i].currentCol = puzzlePieces[swapIndex].currentCol;

          puzzlePieces[swapIndex].currentRow = tempRow;
          puzzlePieces[swapIndex].currentCol = tempCol;

          allCorrect = false;
        }
      }
    } while (!allCorrect);
  }

  void _startGame() {
    if (playerName.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى إدخال اسمك أولاً')));
      return;
    }

    setState(() {
      gameStarted = true;
      gameCompleted = false;
      showWinScreen = false;
      gameStartTime = DateTime.now();
      secondsElapsed = 0;
    });

    // إعادة خلط القطع لبداية جديدة
    _shufflePieces();

    // بدء مؤقت اللعبة
    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        secondsElapsed++;
        if (secondsElapsed >= 60 && !gameCompleted) {
          // انتهت المهلة الزمنية -> العودة للرئيسية تلقائيا
          _endGame(false);
        }
      });
    });
  }

  void _endGame(bool won) {
    gameTimer?.cancel();

    if (won && secondsElapsed < 60) {
      // اللاعب فاز في الوقت المحدد
      _showCompletedImageOnDisplay();
      setState(() {
        gameCompleted = true;
        showWinScreen = true;
      });

      // عرض الاسم والصورة على الشاشة الثانية
      _showCompletedImageOnDisplay();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'مبروك $playerName! أكملت البازل في $secondsElapsed ثانية',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // انتهى الوقت (خسارة) - **منطق العودة التلقائية هنا**
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('انتهى الوقت! حاول مرة أخرى'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // تأخير بسيط لعرض الـ Snackbar ثم **العودة للشاشة الرئيسية (الرتيسة)**
      Timer(Duration(seconds: 2), () {
        if (mounted) {
          _resetToStart(); // العودة التلقائية للرئيسية
        }
      });

      setState(() {
        gameCompleted = false; // تأكد من عدم عرض شاشة الفوز
      });
    }
  }

  void _showCompletedImageOnDisplay() {
    // إظهار الصورة والاسم على شاشة العرض
    final notesService = Provider.of<NotesService>(context, listen: false);
    notesService.triggerPuzzleSuccessDisplay(
      playerName,
      puzzleImage!,
      secondsElapsed,
    );
  }

  bool _checkIfCompleted() {
    for (final piece in puzzlePieces) {
      if (piece.currentRow != piece.correctRow ||
          piece.currentCol != piece.correctCol) {
        return false;
      }
    }
    return true;
  }

  void _onPieceSwapped() {
    if (_checkIfCompleted()) {
      setState(() {
        gameCompleted = true;
      });
      _endGame(true);
    }
  }

  // دالة للعودة لشاشة البداية وبدء لعبة جديدة
  void _resetToStart() {
    setState(() {
      gameStarted = false;
      gameCompleted = false;
      showWinScreen = false;
      secondsElapsed = 0;
      selectedPiece = null;
    });
    gameTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/WhatsApp Image 2025-09-27 at 7.44.50 AM (1).jpeg',
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: showWinScreen
              ? _buildWinScreen()
              : !gameStarted
              ? _buildStartScreen()
              : _buildGameScreen(),
        ),
      ),
    );
  }

  // شاشة الفوز الجديدة
  Widget _buildWinScreen() {
    return Center(
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
              child: Icon(Icons.emoji_events, size: 50, color: Colors.white),
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
              '$playerName',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 10),

            Text(
              'أكملت البازل بنجاح في $secondsElapsed ثانية!',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

            // عرض الصورة المكتملة
            if (puzzleImage != null)
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
                    painter: PuzzlePiecePainter(
                      puzzleImage!,
                      Rect.fromLTWH(
                        0,
                        0,
                        puzzleImage!.width.toDouble(),
                        puzzleImage!.height.toDouble(),
                      ),
                    ),
                    size: Size(300, 200),
                  ),
                ),
              ),

            SizedBox(height: 30),

            // أزرار التحكم
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _startGame, // بدء لعبة جديدة
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'لعبة جديدة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetToStart, // العودة للشاشة الرئيسية
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: Icon(Icons.home, color: Colors.white),
                  label: Text(
                    'الرئيسية',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(30),
        margin: EdgeInsets.symmetric(horizontal: 50),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لعبة البازل',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'اكمل البازل في أقل من دقيقة!',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: TextField(
                onChanged: (value) => playerName = value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'أدخل اسمك هنا',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: imageLoaded ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'العب الآن',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (!imageLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: CircularProgressIndicator(),
              ),

            // ----------------------------------------------------
            // 🌟 الإضافة الجديدة: زرار الرجوع
            // ----------------------------------------------------
            SizedBox(height: 20), // مسافة بين الزرين
            TextButton.icon(
              onPressed: () {
                // تحتاج إلى التأكد من أن InteractiveTabletScreen موجودة ومستوردة
                // إذا لم تكن مستوردة، قم بإضافة: import 'package:your_project_path/interactive_tablet_screen.dart';
                // افترضت أن الشاشة الجديدة موجودة واسمها InteractiveTabletScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => InteractiveTabletScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: Icon(Icons.arrow_back, color: Colors.blue.shade600),
              label: Text(
                'العودة إلى الشاشة الرئيسية',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // ----------------------------------------------------
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        // شريط المعلومات العلوي
        Container(
          padding: EdgeInsets.all(15),
          color: Colors.black.withOpacity(0.7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اللاعب: $playerName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: secondsElapsed > 45
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'الوقت: ${60 - secondsElapsed}s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // نصائح اللعب
        Container(
          padding: EdgeInsets.all(10),
          color: Colors.blue.shade800.withOpacity(0.8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'اسحب القطع لتبديلها أو اضغط عليها للتحديد',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),

        // منطقة اللعب
        Expanded(
          child: Center(
            child: Container(
              width: math.min(MediaQuery.of(context).size.width * 0.9, 450),
              height:
                  math.min(MediaQuery.of(context).size.width * 0.9, 450) *
                  2 /
                  3,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _buildPuzzleGrid(),
            ),
          ),
        ),

        // أزرار التحكم
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _resetToStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: Icon(Icons.exit_to_app, color: Colors.white),
                label: Text(
                  'إنهاء اللعبة',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _shufflePieces();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: Icon(Icons.shuffle, color: Colors.white),
                label: Text('خلط القطع', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // إظهار الصورة الأصلية لثواني قليلة
                  _showHint();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: Icon(Icons.help_outline, color: Colors.white),
                label: Text('مساعدة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // دالة لإظهار تلميح (الصورة الأصلية)
  void _showHint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الصورة الأصلية', textAlign: TextAlign.center),
        content: Container(
          width: 250,
          height: 167,
          child: CustomPaint(
            painter: PuzzlePiecePainter(
              puzzleImage!,
              Rect.fromLTWH(
                0,
                0,
                puzzleImage!.width.toDouble(),
                puzzleImage!.height.toDouble(),
              ),
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );

    // أغلق التلميح تلقائياً بعد 3 ثوانٍ
    Timer(Duration(seconds: 1), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildPuzzleGrid() {
    if (puzzleImage == null) return CircularProgressIndicator();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildPuzzlePieceWidget(index);
      },
    );
  }

  Widget _buildPuzzlePieceWidget(int gridIndex) {
    // العثور على القطعة في هذا الموضع
    final piece = puzzlePieces.firstWhere(
      (p) => p.currentRow * 3 + p.currentCol == gridIndex,
    );

    final bool isSelected = selectedPiece == piece;

    return Draggable<PuzzlePiece>(
      data: piece,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 120, // حجم أكبر قليلاً أثناء السحب
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.yellow, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: PuzzlePiecePainter(puzzleImage!, piece.sourceRect),
            size: Size.infinite,
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Icon(Icons.crop_free, size: 30, color: Colors.grey.shade400),
        ),
      ),
      child: DragTarget<PuzzlePiece>(
        onWillAccept: (data) => data != null && data != piece,
        onAccept: (draggedPiece) {
          _swapPieces(draggedPiece, piece);
        },
        builder: (context, candidateData, rejectedData) {
          final bool isHovering = candidateData.isNotEmpty;

          return GestureDetector(
            onTap: () => _onPieceTapped(piece),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isHovering
                      ? Colors.blue.shade600
                      : isSelected
                      ? Colors.yellow.shade600
                      : piece.isInCorrectPosition()
                      ? Colors.green
                      : Colors.white,
                  width: isHovering
                      ? 3
                      : isSelected
                      ? 4
                      : 2,
                ),
                boxShadow: isSelected || isHovering
                    ? [
                        BoxShadow(
                          color: (isHovering ? Colors.blue : Colors.yellow)
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
                color: isHovering ? Colors.blue.withOpacity(0.1) : null,
              ),
              child: CustomPaint(
                painter: PuzzlePiecePainter(puzzleImage!, piece.sourceRect),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }

  PuzzlePiece? selectedPiece;

  void _onPieceTapped(PuzzlePiece piece) {
    if (selectedPiece == null) {
      // تحديد القطعة الأولى
      setState(() {
        selectedPiece = piece;
      });
    } else if (selectedPiece == piece) {
      // إلغاء التحديد
      setState(() {
        selectedPiece = null;
      });
    } else {
      // تبديل القطعتين
      _swapPieces(selectedPiece!, piece);
      setState(() {
        selectedPiece = null;
      });
    }
  }

  void _swapPieces(PuzzlePiece piece1, PuzzlePiece piece2) {
    final tempRow = piece1.currentRow;
    final tempCol = piece1.currentCol;

    piece1.currentRow = piece2.currentRow;
    piece1.currentCol = piece2.currentCol;

    piece2.currentRow = tempRow;
    piece2.currentCol = tempCol;

    setState(() {});
    _onPieceSwapped();
  }
}

class PuzzlePiece {
  final int id;
  final int correctRow;
  final int correctCol;
  int currentRow;
  int currentCol;
  final Rect sourceRect;

  PuzzlePiece({
    required this.id,
    required this.correctRow,
    required this.correctCol,
    required this.currentRow,
    required this.currentCol,
    required this.sourceRect,
  });

  bool isInCorrectPosition() {
    return currentRow == correctRow && currentCol == correctCol;
  }
}

class PuzzlePiecePainter extends CustomPainter {
  final ui.Image image;
  final Rect sourceRect;

  PuzzlePiecePainter(this.image, this.sourceRect);

  @override
  void paint(Canvas canvas, Size size) {
    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, sourceRect, destRect, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
