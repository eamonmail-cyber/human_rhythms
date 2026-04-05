import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'services/reminder_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }

    try {
      await ReminderService.initialize();
    } catch (e) {
      debugPrint('Reminder init error: $e');
    }

    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    runApp(const ProviderScope(child: HumanRhythmsApp()));
  }, (error, stack) {
    // Catches any uncaught exception (e.g. PlatformException from Firebase)
    // so the app always renders something instead of a white screen.
    debugPrint('Fatal error: $error\n$stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('App failed to start: $error')),
      ),
    ));
  });
}
