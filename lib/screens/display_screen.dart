// import 'package:flutter/material.dart';
// import 'package:testwhiteboard/main.dart';
// import 'package:testwhiteboard/screens/device_card.dart';
// import 'package:testwhiteboard/screens/display_test.dart';
// import 'package:testwhiteboard/screens/interactive_tablet_screen.dart';

// class DeviceSelectionScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.green.shade400, Colors.green.shade600],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 padding: EdgeInsets.all(30),
//                 child: Column(
//                   children: [
//                     Icon(Icons.sticky_note_2, size: 80, color: Colors.white),
//                     SizedBox(height: 20),
//                     Text(
//                       'نظام الملاحظات التفاعلي',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       'مدعوم بتقنية Firebase',
//                       style: TextStyle(fontSize: 16, color: Colors.white70),
//                     ),
//                   ],
//                 ),
//               ),

//               // Device selection cards
//               Expanded(
//                 child: Container(
//                   margin: EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'اختر نوع الجهاز',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       SizedBox(height: 40),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: DeviceCard(
//                               title: 'التابلت التفاعلي',
//                               subtitle: 'للكتابة وإضافة الملاحظات',
//                               icon: Icons.tablet_android,
//                               color: Colors.blue,
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => InteractiveTabletScreen(),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Expanded(
//                             child: DeviceCard(
//                               title: 'شاشة العرض الكبيرة',
//                               subtitle: 'لعرض جميع الملاحظات',
//                               icon: Icons.tv,
//                               color: Colors.orange,
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => DisplayScreen(),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // Footer
//               Container(
//                 padding: EdgeInsets.all(20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.cloud, color: Colors.white70, size: 16),
//                     SizedBox(width: 8),
//                     Text(
//                       'متصل بالسحابة الإلكترونية',
//                       style: TextStyle(color: Colors.white70),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
