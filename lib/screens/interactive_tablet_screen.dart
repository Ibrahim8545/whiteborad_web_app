import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:testwhiteboard/screens/puzzle_screen.dart';
import 'package:testwhiteboard/services.dart/sercives.dart';
import '../models/note_model.dart';

class InteractiveTabletScreen extends StatefulWidget {
  @override
  _InteractiveTabletScreenState createState() =>
      _InteractiveTabletScreenState();
}

class _InteractiveTabletScreenState extends State<InteractiveTabletScreen>
    with TickerProviderStateMixin {
  final _signaturePadKey = GlobalKey<SignatureState>();
  final _repaintBoundaryKey = GlobalKey();

  Color _selectedColor = Colors.black;
  final String _author = 'مستخدم التابلت';
  bool _isSubmitting = false;

  // متحكمات الأنيميشن للكروت
  late AnimationController _cardsController;
  late Animation<double> _cardsAnimation;
  late AnimationController _assemblyController;
  late Animation<double> _assemblyAnimation;

  final List<Offset> _scatteredPositions = [];
  final List<Offset> _assemblyPositions = [];
  final math.Random _random = math.Random();
  bool _showCards = true;
  bool _isAssembling = false;

  final List<Color> _availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue.shade700,
    Colors.green.shade700,
    Colors.purple.shade700,
    Colors.orange.shade800,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();

    _cardsController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _cardsAnimation = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.elasticOut,
    );

    _assemblyController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _assemblyAnimation = CurvedAnimation(
      parent: _assemblyController,
      curve: Curves.easeInOutQuad,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final notesService = Provider.of<NotesService>(context, listen: false);
        _generateScatteredPositions(notesService.notes.length);
        _generateAssemblyPositions(notesService.notes.length);
        notesService.addListener(_onNotesChanged);
      } catch (e) {
        print('Initialization error: $e');
      }
    });
  }

  @override
  void dispose() {
    final notesService = Provider.of<NotesService>(context, listen: false);
    notesService.removeListener(_onNotesChanged);
    _cardsController.dispose();
    _assemblyController.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    final notesService = Provider.of<NotesService>(context, listen: false);
    if (_scatteredPositions.length != notesService.notes.length) {
      _generateScatteredPositions(notesService.notes.length);
      _generateAssemblyPositions(notesService.notes.length);
      _cardsController.forward(from: 0.0);
    }
    setState(() {});
  }

  // void _generateAssemblyPositions(int totalNotes) {
  //   _assemblyPositions.clear();
  //   if (totalNotes == 0) return;

  //   final size = MediaQuery.of(context).size;
  //   final double cardWidth = 60;
  //   final double cardHeight = 80;
  //   final double gap = 8;
  //   final isLargeScreen = size.width > 700;

  //   // نمط رقم 95
  //   final List<List<int>> pattern95 = [
  //     [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
  //     [1, 0, 1, 0, 0, 1, 0, 0, 0, 0],
  //     [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
  //     [0, 0, 1, 0, 0, 0, 0, 0, 0, 1],
  //     [1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
  //   ];

  //   final List<Offset> required95Positions = [];
  //   for (int r = 0; r < pattern95.length; r++) {
  //     for (int c = 0; c < pattern95[0].length; c++) {
  //       if (pattern95[r][c] == 1) {
  //         final double x = c * (cardWidth + gap);
  //         final double y = r * (cardHeight + gap);
  //         required95Positions.add(Offset(x, y));
  //       }
  //     }
  //   }

  //   final int count95 = required95Positions.length;
  //   final double patternWidth = 9 * (cardWidth + gap);
  //   final double patternHeight = 4 * (cardHeight + gap);

  //   // تحديد موقع النمط في المساحة المحددة - على اليمين مع مساحة أكبر
  //   double offsetX, offsetY;
  //   if (isLargeScreen) {
  //     // زيادة المساحة المتاحة للكروت - تحريك النمط أكثر لليمين
  //     offsetX =
  //         size.width - 550 - patternWidth / 2; // زيادة المسافة من 450 إلى 550
  //     offsetY = 180 - patternHeight / 2; // رفع الكروت قليلاً
  //   } else {
  //     // في الشاشات الصغيرة
  //     offsetX = size.width / 2 - patternWidth / 2;
  //     offsetY = 150;
  //   }

  //   for (int i = 0; i < totalNotes; i++) {
  //     final int targetIndex = i % count95;
  //     final Offset basePosition = required95Positions[targetIndex];

  //     final Offset finalOffset = Offset(
  //       basePosition.dx + offsetX,
  //       basePosition.dy + offsetY,
  //     );

  //     final double stackingJitter = (i % 10).toDouble() * 0.5;

  //     _assemblyPositions.add(
  //       Offset(
  //         finalOffset.dx + stackingJitter,
  //         finalOffset.dy + stackingJitter,
  //       ),
  //     );
  //   }
  // }
  void _generateAssemblyPositions(int totalNotes) {
    _assemblyPositions.clear();
    if (totalNotes == 0) return;

    final size = MediaQuery.of(context).size;
    final double cardWidth = 60;
    final double cardHeight = 80;
    final double gap = 8;
    final isLargeScreen = size.width > 700;

    // نمط رقم 95 مع تكبير الرقم 9
    final List<List<int>> pattern95 = [
      [1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
      [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
      [1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
      [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1],
      [1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
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
    final double patternWidth =
        10 * (cardWidth + gap); // تحديث العرض للنمط الجديد
    final double patternHeight = 4 * (cardHeight + gap);

    // تحديد موقع النمط في المساحة المحددة - على اليمين مع مساحة أكبر
    double offsetX, offsetY;
    if (isLargeScreen) {
      // زيادة المساحة المتاحة للكروت - تحريك النمط أكثر لليمين
      offsetX =
          size.width - 550 - patternWidth / 2; // زيادة المسافة من 450 إلى 550
      offsetY = 180 - patternHeight / 2; // رفع الكروت قليلاً
    } else {
      // في الشاشات الصغيرة
      offsetX = size.width / 2 - patternWidth / 2;
      offsetY = 150;
    }

    for (int i = 0; i < totalNotes; i++) {
      final int targetIndex = i % count95;
      final Offset basePosition = required95Positions[targetIndex];

      final Offset finalOffset = Offset(
        basePosition.dx + offsetX,
        basePosition.dy + offsetY,
      );

      final double stackingJitter = (i % 10).toDouble() * 0.5;

      _assemblyPositions.add(
        Offset(
          finalOffset.dx + stackingJitter,
          finalOffset.dy + stackingJitter,
        ),
      );
    }
  }

  void _toggleAssembly() {
    setState(() {
      _isAssembling = !_isAssembling;
      if (_isAssembling) {
        _assemblyController.forward(from: 0.0);
      } else {
        final notesService = Provider.of<NotesService>(context, listen: false);
        _generateScatteredPositions(notesService.notes.length);
        _assemblyController.reverse(from: 1.0);
      }
    });
  }

  void _generateScatteredPositions(int count) {
    _scatteredPositions.clear();
    if (count == 0) return;

    final size = MediaQuery.of(context).size;
    final double cardWidth = 60;
    final double cardHeight = 80;
    final isLargeScreen = size.width > 700;

    if (isLargeScreen) {
      // في الشاشات الكبيرة - المساحة الفارغة في اليمين - مساحة أكبر
      final double availableWidth = 500; // زيادة العرض من 400 إلى 500
      final double availableHeight = 350; // زيادة الارتفاع من 320 إلى 350
      final double startX =
          size.width - 550; // تحريك أكثر لليمين من 450 إلى 550
      final double startY = 120; // بداية المنطقة من الأعلى

      for (int i = 0; i < count; i++) {
        final double randomX =
            startX + (_random.nextDouble() * (availableWidth - cardWidth));
        final double randomY =
            startY + (_random.nextDouble() * (availableHeight - cardHeight));

        _scatteredPositions.add(Offset(randomX, randomY));
      }
    } else {
      // في الشاشات الصغيرة - المساحة أعلى لوحة الكتابة
      final double availableWidth = size.width - 100;
      final double availableHeight = 120;
      final double startX = 50;
      final double startY = 100;

      for (int i = 0; i < count; i++) {
        final double randomX =
            startX + (_random.nextDouble() * (availableWidth - cardWidth));
        final double randomY =
            startY + (_random.nextDouble() * (availableHeight - cardHeight));

        _scatteredPositions.add(Offset(randomX, randomY));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 700;
        final mainPadding = isLargeScreen ? 30.0 : 15.0;

        return Scaffold(
          body: Stack(
            children: [
              // صورة الخلفية
              Positioned.fill(
                child: Image.asset(
                  'assets/images/WhatsApp Image 2025-09-27 at 7.44.50 AM (1).jpeg',
                  fit: BoxFit.fill,
                ),
              ),
              // طبقة التعتيم مع تقليل الشفافية لإخفاء رقم 95
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ), // زيادة التعتيم من 0.3 إلى 0.5
              ),

              // المحتوى الأساسي
              Padding(
                padding: EdgeInsets.all(mainPadding),
                child: Column(
                  children: [
                    // العنوان والأزرار العلوية
                    _buildHeader(context, isLargeScreen),
                    SizedBox(height: isLargeScreen ? 20 : 10),

                    // المنطقة الرئيسية
                    Expanded(
                      child: Stack(
                        children: [
                          // عرض الكروت في الخلفية
                          _buildCardsDisplay(),

                          // لوحة الكتابة والأدوات في المقدمة
                          if (isLargeScreen)
                            _buildLargeScreenLayout()
                          else
                            _buildSmallScreenLayout(),
                        ],
                      ),
                    ),

                    SizedBox(height: isLargeScreen ? 10 : 5),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardsDisplay() {
    return Consumer<NotesService>(
      builder: (context, notesService, child) {
        if (!_showCards || notesService.notes.isEmpty) {
          return SizedBox.shrink();
        }

        return Stack(
          children: [
            // الكروت
            ...notesService.notes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;

              if (index >= _scatteredPositions.length ||
                  index >= _assemblyPositions.length) {
                return SizedBox.shrink();
              }

              final scatteredPosition = _scatteredPositions[index];
              final assemblyPosition = _assemblyPositions[index];

              return AnimatedBuilder(
                animation: _assemblyAnimation,
                builder: (context, child) {
                  // حساب الموقع الحالي بناء على التجميع أو التفكيك
                  final currentX =
                      scatteredPosition.dx +
                      (_assemblyAnimation.value *
                          (assemblyPosition.dx - scatteredPosition.dx));
                  final currentY =
                      scatteredPosition.dy +
                      (_assemblyAnimation.value *
                          (assemblyPosition.dy - scatteredPosition.dy));

                  return Positioned(
                    left: currentX,
                    top: currentY,
                    child: AnimatedBuilder(
                      animation: _cardsAnimation,
                      builder: (context, cardChild) {
                        // التأكد من أن قيمة opacity صحيحة (بين 0.0 و 1.0)
                        final opacityValue = _cardsAnimation.value.clamp(
                          0.0,
                          1.0,
                        );
                        final scaleValue = (0.3 + (_cardsAnimation.value * 0.7))
                            .clamp(0.1, 1.0);

                        return Transform.scale(
                          scale: scaleValue,
                          child: Opacity(
                            opacity: opacityValue,
                            child: cardChild!,
                          ),
                        );
                      },
                      child: child!,
                    ),
                  );
                },
                child: _buildNoteCard(note, index),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildNoteCard(NoteModel note, int index) {
    return Transform.rotate(
      angle: (index % 10) * 0.02 - 0.1,
      child: Container(
        width: 60,
        height: 80,
        child: Material(
          color: Colors.yellow.shade500,
          elevation: 4,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: note.isImage
                  ? _buildImageDisplay(note.imageData)
                  : _buildSignatureDisplay(note),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return Center(child: Icon(Icons.error, size: 15, color: Colors.grey));
    }

    try {
      final bytes = base64Decode(imageData);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(Icons.broken_image, size: 15, color: Colors.orange),
        ),
      );
    } catch (e) {
      return Center(
        child: Icon(Icons.broken_image, size: 15, color: Colors.orange),
      );
    }
  }

  Widget _buildSignatureDisplay(NoteModel note) {
    return CustomPaint(
      painter: MiniSignaturePainter(
        note.drawingPoints,
        strokeColor: note.color,
      ),
      child: Container(),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLargeScreen) {
    return Consumer<NotesService>(
      builder: (context, notesService, child) {
        return SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الشعار
              Image.asset(
                'assets/images/logo.png',
                height: isLargeScreen ? 180 : 40,
                width: isLargeScreen ? 350 : 40,
                color: Colors.white,
              ),

              // الأدوات والأزرار
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusChip(
                    isConnected: notesService.isConnected,
                    count: notesService.notes.length,
                  ),
                  SizedBox(width: 15),

                  // أزرار التجميع والتفكيك
                  if (notesService.notes.isNotEmpty) ...[
                    _buildActionButton(
                      icon: _isAssembling ? Icons.scatter_plot : Icons.grid_on,
                      text: _isAssembling ? 'تفكيك' : 'تجميع 95',
                      color: Colors.orange.shade400,
                      onPressed: _toggleAssembly,
                    ),
                    SizedBox(width: 15),
                  ],

                  _buildActionButton(
                    icon: Icons.refresh_rounded,
                    text: isLargeScreen ? 'مسح اللوحة' : 'مسح',
                    color: Colors.red.shade400,
                    onPressed: () {
                      _signaturePadKey.currentState?.clear();
                    },
                  ),
                  SizedBox(width: 15),
                  _buildActionButton(
                    icon: Icons.send_rounded,
                    text: isLargeScreen ? 'إرسال الحلم' : 'إرسال',
                    color: Colors.green.shade400,
                    onPressed: _isSubmitting ? null : _submitNote,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip({required bool isConnected, required int count}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 14,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                isConnected ? 'متصل' : 'غير متصل',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          '$count حلم',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSubmitting && text.contains('إرسال'))
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(icon, size: 20, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  _isSubmitting && text.contains('إرسال') ? 'جاري...' : text,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Column(
      children: [
        SizedBox(height: 40), // مساحة للنص أعلى لوحة الكتابة
        // النص فوق لوحة الكتابة مباشرة
        Text(
          'اكتب حلماً تَتَمناهُ لوطنك:',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        // لوحة الكتابة والأدوات
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // أدوات الألوان على اليسار
            Container(
              width: 50,
              child: _buildColorToolsSidebar(isVertical: true),
            ),
            SizedBox(width: 20),

            // لوحة الكتابة - تحريك أكثر لليسار لإفساح مجال أكبر للكروت
            Container(
              width: 300,
              height: 280,
              child: _buildSignaturePad(),
            ), // تقليل العرض من 350 إلى 300 والارتفاع من 300 إلى 280
            SizedBox(
              width: 100,
            ), // زيادة المسافة من 50 إلى 100 لمساحة أكبر للكروت
          ],
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return Column(
      children: [
        // النص في الأعلى
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'اكتب حلماً تَتَمناهُ لوطنك:',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        // لوحة الكتابة
        Expanded(flex: 2, child: _buildSignaturePad()),
        SizedBox(height: 15),
        // أدوات الألوان
        _buildColorToolsSidebar(isVertical: false),
      ],
    );
  }

  Widget _buildSignaturePad() {
    return Transform.rotate(
      angle: 0.01745 * 1.5,
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Color(0xFFFEF08A),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Signature(
            key: _signaturePadKey,
            color: _selectedColor,
            strokeWidth: 5.0,
            backgroundPainter: null,
          ),
        ),
      ),
    );
  }

  Widget _buildColorToolsSidebar({required bool isVertical}) {
    return Container(
      padding: EdgeInsets.all(isVertical ? 10 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: isVertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _availableColors
                  .map((color) => _buildColorOption(color))
                  .toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _availableColors
                  .map((color) => _buildColorOption(color))
                  .toList(),
            ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: isSelected ? 30 : 25,
        height: isSelected ? 30 : 25,
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue.shade800 : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? Center(child: Icon(Icons.edit, color: Colors.white, size: 16))
            : null,
      ),
    );
  }

  void _submitNote() async {
    final signature = _signaturePadKey.currentState;
    if (signature == null) {
      _showSnackBar('خطأ في الوصول للوحة الكتابة', Colors.orange);
      return;
    }

    if (signature.points == null || signature.points!.isEmpty) {
      _showSnackBar('يرجى كتابة حلمك أولاً', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notesService = Provider.of<NotesService>(context, listen: false);

      // التأكد من وجود السياق
      if (!mounted) {
        return;
      }

      // إضافة تأخير للتأكد من اكتمال الرسم
      await Future.delayed(Duration(milliseconds: 500));

      final currentContext = _repaintBoundaryKey.currentContext;
      if (currentContext == null) {
        throw Exception('Context not available');
      }

      final renderObject = currentContext.findRenderObject();
      if (renderObject == null) {
        throw Exception('Render object not found');
      }

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Invalid render object type');
      }

      // التحقق من أن الكائن جاهز للرسم
      if (!renderObject.debugNeedsPaint) {
        // محاولة التقاط الصورة مع معالجة الأخطاء المحسنة
        ui.Image? image;
        try {
          image = await renderObject.toImage(pixelRatio: 1.5);
        } catch (e) {
          print('Image capture error: $e');
          throw Exception('فشل في التقاط الصورة');
        }

        if (image == null) {
          throw Exception('الصورة فارغة');
        }

        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw Exception('فشل في تحويل الصورة');
        }

        final bytes = byteData.buffer.asUint8List();
        if (bytes.isEmpty) {
          throw Exception('بيانات الصورة فارغة');
        }

        final base64Image = base64Encode(bytes);
        if (base64Image.isEmpty) {
          throw Exception('فشل في ترميز الصورة');
        }

        print('Image processed successfully, size: ${base64Image.length}');

        bool success = await notesService.addNoteWithImage(
          imageData: base64Image,
          color: _selectedColor,
          author: _author,
        );

        if (mounted) {
          setState(() => _isSubmitting = false);

          if (success) {
            signature.clear();
            _showSnackBar('تم إرسال حلمك بنجاح! ✓', Colors.green);
          } else {
            _showSnackBar('حدث خطأ أثناء الإرسال - حاول مرة أخرى', Colors.red);
          }
        }
      } else {
        throw Exception('العنصر ليس جاهزاً للرسم');
      }
    } catch (e) {
      print('Submit error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        String errorMessage = 'حدث خطأ فني';

        // رسائل خطأ مخصصة
        if (e.toString().contains('Context')) {
          errorMessage = 'خطأ في السياق - حاول مرة أخرى';
        } else if (e.toString().contains('Image')) {
          errorMessage = 'خطأ في معالجة الصورة';
        } else if (e.toString().contains('فشل')) {
          errorMessage = e.toString().split('Exception: ').last;
        }

        _showSnackBar(errorMessage, Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// رسام مصغر للتوقيعات
class MiniSignaturePainter extends CustomPainter {
  final List<List<Map<String, double>>> drawingPoints;
  final Color strokeColor;

  MiniSignaturePainter(this.drawingPoints, {this.strokeColor = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final stroke in drawingPoints) {
      if (stroke.isEmpty) continue;

      final path = Path();
      bool first = true;

      for (final point in stroke) {
        final x = point['x']?.toDouble();
        final y = point['y']?.toDouble();
        if (x != null && y != null && x.isFinite && y.isFinite) {
          // تحويل المقياس ليناسب الحجم الصغير
          final scaledX =
              (x / 300) *
              size.width; // تغيير من 400 إلى 300 لمطابقة الحجم الجديد
          final scaledY =
              (y / 280) *
              size.height; // تغيير من 300 إلى 280 لمطابقة الحجم الجديد

          if (first) {
            path.moveTo(scaledX, scaledY);
            first = false;
          } else {
            path.lineTo(scaledX, scaledY);
          }
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
