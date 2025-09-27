import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:testwhiteboard/screens/puzzle_screen.dart';
// تأكد من وجود هذا المسار في مشروعك
import 'package:testwhiteboard/services.dart/sercives.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 700;
        final mainPadding = isLargeScreen ? 30.0 : 15.0;

        return Scaffold(
          // ⚠️ إزالة لون الخلفية من Scaffold لأن الصورة ستكون هي الخلفية
          // backgroundColor: Color(0xFFE0F2F7),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/WhatsApp Image 2025-09-27 at 7.44.50 AM (1).jpeg',
                  fit: BoxFit.fill,
                ),
              ),
              // طبقة التعتيم
              Positioned.fill(
                child: Container(
                  // يمكنك تغيير 0.5 إلى قيمة بين 0.3 (خفيف) و 0.7 (داكن)
                  color: Colors.black.withOpacity(0.3),
                ),
              ),

              // 1. صورة الخلفية تغطي الشاشة بالكامل
              // Container(
              //   width: double.infinity, // العرض كله
              //   height: double.infinity,
              //   decoration: BoxDecoration(
              //     image: DecorationImage(
              //       // تأكد من أن هذا المسار صحيح تمامًا لصورتك
              //       image: AssetImage(
              //         'assets/images/WhatsApp Image 2025-09-27 at 7.44.50 AM (1).jpeg',
              //       ),
              //       fit: BoxFit.fill,
              //       alignment: Alignment.center,

              //       // لتغطية الشاشة بالكامل
              //       // توسيط الصورة
              //     ),
              //   ),
              // ),

              // 2. المحتوى الأساسي (الأزرار، لوحة الكتابة، الأدوات) فوق الخلفية
              Padding(
                padding: EdgeInsets.all(mainPadding),
                child: Column(
                  children: [
                    // العنوان والأزرار العلوية
                    _buildHeader(context, isLargeScreen),
                    SizedBox(height: isLargeScreen ? 20 : 10),

                    // المنطقة الرئيسية: لوحة الكتابة والنص والأدوات
                    Expanded(
                      child: isLargeScreen
                          ? _buildLargeScreenLayout()
                          : _buildSmallScreenLayout(),
                    ),

                    // المسافة الفاصلة (يمكن تعديلها أو إزالتها حسب الحاجة)
                    SizedBox(height: isLargeScreen ? 10 : 5),
                  ],
                ),
              ),

              // ⚠️ إزالة Positioned السابقة للخلفية السفلية لأن الخلفية أصبحت كاملة
            ],
          ),
        );
      },
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // الشعار في الزاوية العلوية اليسرى
              Image.asset(
                'assets/images/logo.png',
                height: isLargeScreen ? 180 : 40,
                width: isLargeScreen ? 350 : 40,
                color: Colors.white,
              ),

              // محتوى الرأس مع إضافة زر لعبة البازل
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusChip(
                    isConnected: notesService.isConnected,
                    count: notesService.notes.length,
                  ),
                  SizedBox(width: 15),

                  // زر لعبة البازل الجديد
                  // _buildActionButton(
                  //   icon: Icons.games_rounded,
                  //   text: isLargeScreen ? 'العب الآن' : 'لعبة',
                  //   color: Colors.purple.shade400,
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => PuzzleGameScreen(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  SizedBox(width: 15),

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
  // #region Building Widgets
  // Widget _buildHeader(BuildContext context, bool isLargeScreen) {
  //   return Consumer<NotesService>(
  //     builder: (context, notesService, child) {
  //       // 💡 التعديل: تغليف الـ Row بـ SizedBox لضمان العرض الكامل
  //       // هذا يضمن أن الـ Row سيتلقى قيود عرض محدودة
  //       return SizedBox(
  //         width: double.infinity,
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // 1. الشعار في الزاوية العلوية اليسرى
  //             Image.asset(
  //               'assets/images/logo.png', // ⚠️ تحقق من المسار
  //               // 💡 التعديل: زيادة الطول والعرض لملء المساحة العلوية بشكل أكبر في الشاشات الكبيرة
  //               height: isLargeScreen ? 180 : 40, // زِد هذه القيمة
  //               width: isLargeScreen ? 350 : 40, // زِد هذه القيمة
  //               color: Colors.white,
  //             ),

  //             // Spacer() لضمان أن العناصر التالية ستكون في أقصى اليمين
  //             // تم إزالة Spacer() بما أننا نستخدم mainAxisAlignment: MainAxisAlignment.spaceBetween
  //             // ولكن سنستخدم Spacer إذا أردنا دفعه أكثر

  //             // 2. محتوى الرأس القديم (حالة الاتصال والأزرار) في الزاوية العلوية اليمنى
  //             Row(
  //               mainAxisSize: MainAxisSize.min, // مهم جداً
  //               children: [
  //                 _buildStatusChip(
  //                   isConnected: notesService.isConnected,
  //                   count: notesService.notes.length,
  //                 ),
  //                 SizedBox(width: 15),
  //                 _buildActionButton(
  //                   icon: Icons.refresh_rounded,
  //                   text: isLargeScreen ? 'مسح اللوحة' : 'مسح',
  //                   color: Colors.red.shade400,
  //                   onPressed: () {
  //                     _signaturePadKey.currentState?.clear();
  //                   },
  //                 ),
  //                 SizedBox(width: 15),
  //                 _buildActionButton(
  //                   icon: Icons.send_rounded,
  //                   text: isLargeScreen ? 'إرسال الحلم' : 'إرسال',
  //                   color: Colors.green.shade400,
  //                   onPressed: _isSubmitting ? null : _submitNote,
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

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
  // Widget _buildActionButton({
  //   required IconData icon,
  //   required String text,
  //   required Color color,
  //   required VoidCallback? onPressed,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       // 💡 التعديل هنا: زيادة قيمة الشفافية (Opacity) إلى 0.8
  //       // هذا يجعل الخلفية أكثر صلابة وتبرز النص الأبيض
  //       color: color.withOpacity(0.8),
  //       borderRadius: BorderRadius.circular(10),
  //       // 💡 تعديل الإطار: يمكن استخدام لون أبيض للإطار الخارجي لزيادة الإبراز
  //       border: Border.all(color: Colors.white, width: 2),
  //     ),
  //     child: Material(
  //       color: Colors.transparent,

  //       child: InkWell(
  //         onTap: onPressed,
  //         borderRadius: BorderRadius.circular(8),
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               if (_isSubmitting && text.contains('إرسال'))
  //                 SizedBox(
  //                   width: 15,
  //                   height: 15,
  //                   child: CircularProgressIndicator(
  //                     strokeWidth: 2,
  //                     valueColor: AlwaysStoppedAnimation<Color>(
  //                       Colors.white,
  //                     ), // نجعل المؤشر أبيض أيضاً
  //                   ),
  //                 )
  //               else
  //                 // 💡 التعديل هنا: استخدام اللون الأبيض للأيقونة (الأفضل للتباين)
  //                 Icon(icon, size: 20, color: Colors.white),
  //               SizedBox(width: 5),
  //               Text(
  //                 _isSubmitting && text.contains('إرسال') ? 'جاري...' : text,
  //                 style: TextStyle(
  //                   // 🟢 لون النص الأبيض ممتاز على الخلفية الداكنة الجديدة
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.w900,
  //                   fontSize: 20,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // *** دالة التخطيط للشاشة الكبيرة (Large Screen Layout) ***
  Widget _buildLargeScreenLayout() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. أدوات الألوان على اليسار
          Container(
            width: 50,
            child: _buildColorToolsSidebar(isVertical: true),
          ),
          SizedBox(width: 20),

          // 2. لوحة الكتابة (الملاحظة الصفراء)
          Container(width: 450, height: 350, child: _buildSignaturePad()),
          SizedBox(width: 20),

          // 3. النص المطلوب بجانب لوحة الكتابة على اليمين
          Container(
            width: 300,
            child: Text(
              'اكتب حلماً تَتَمناهُ لوطنك:',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // #region Responsive Layouts

  Widget _buildSmallScreenLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // النص في الأعلى في وضع الشاشة الصغيرة
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'اكتب حلماً تَتَمناهُ لوطنك:',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF38A169),
              backgroundColor: Colors.white,
            ),
          ),
        ),
        // لوحة الكتابة
        Expanded(flex: 4, child: _buildSignaturePad()),
        SizedBox(height: 15),
        // أدوات الألوان في الأسفل (أفقي)
        _buildColorToolsSidebar(isVertical: false),
      ],
    );
  }

  // #endregion Responsive Layouts

  // لوحة التوقيع/الكتابة
  Widget _buildSignaturePad() {
    return Transform.rotate(
      angle: 0.01745 * 1.5, // دوران خفيف (1.5 درجة) لتبدو كملصق
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Color(0xFFFEF08A), // لون الملاحظة الصفراء
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

  // شريط أدوات الألوان
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

  // خيار اللون
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

  // #endregion Building Widgets

  // #region Submission Logic

  void _submitNote() async {
    final signature = _signaturePadKey.currentState;
    if (signature == null ||
        signature.points == null ||
        signature.points!.isEmpty) {
      _showSnackBar('يرجى كتابة حلمك أولاً', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notesService = Provider.of<NotesService>(context, listen: false);
      bool success = false;

      await Future.delayed(Duration(milliseconds: 100));
      final renderObject = _repaintBoundaryKey.currentContext
          ?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Render object is not RepaintBoundary');
      }

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to ByteData');
      }

      final bytes = byteData.buffer.asUint8List();
      final base64Image = base64Encode(bytes);

      success = await notesService.addNoteWithImage(
        imageData: base64Image,
        color: _selectedColor,
        author: _author,
      );

      setState(() => _isSubmitting = false);
      if (success) {
        signature.clear();
        _showSnackBar('تم إرسال حلمك بنجاح! ✓', Colors.green);
      } else {
        _showSnackBar('حدث خطأ أثناء الإرسال', Colors.red);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar('حدث خطأ فني أثناء المعالجة', Colors.red);
      print('Error: $e');
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

  // #endregion Submission Logic

  @override
  void dispose() {
    super.dispose();
  }
}
