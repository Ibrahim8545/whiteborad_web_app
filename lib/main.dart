import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:provider/provider.dart';
import 'package:testwhiteboard/screens/display_screen.dart';
import 'package:testwhiteboard/screens/display_test.dart';
import 'package:testwhiteboard/screens/interactive_tablet_screen.dart';
import 'package:testwhiteboard/services.dart/sercives.dart';
import 'firebase_options.dart';
import 'screens/interactive_tablet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isPaid; // null = لسه بيسحب من Remote Config

  @override
  void initState() {
    super.initState();
    // _initRemoteConfig();
  }

  // Future<void> _initRemoteConfig() async {
  //   final remoteConfig = FirebaseRemoteConfig.instance;

  //   await remoteConfig.setConfigSettings(
  //     RemoteConfigSettings(
  //       fetchTimeout: const Duration(seconds: 10),
  //       minimumFetchInterval: const Duration(seconds: 1),
  //     ),
  //   );

  //   await remoteConfig.fetchAndActivate();

  //   setState(() {
  //     isPaid = remoteConfig.getBool("isPaid"); // المفتاح من Firebase Console
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => NotesService())],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'Arial',
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: InteractiveTabletScreen(),
      ),
    );
  }

  // Widget _buildHome() {
  //   if (isPaid == null) {
  //     // لسه بيحمل
  //     return const Scaffold(body: Center(child: CircularProgressIndicator()));
  //   } else if (isPaid == false) {
  //     // مش دافع → شاشة مقفولة
  //     return const Scaffold(
  //       body: Center(
  //         child: Text(
  //           "❌ التطبيق غير متاح حالياً\nبرجاء التواصل مع الدعم.",
  //           textAlign: TextAlign.center,
  //           style: TextStyle(fontSize: 18),
  //         ),
  //       ),
  //     );
  //   } else {
  //     // دافع → يفتح عادي
  //     return DisplayScreen();
  //   }
  // }
}
