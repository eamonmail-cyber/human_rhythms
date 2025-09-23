import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  bool firebaseReady = false;

  try {
    if (Platform.isAndroid) {
      // Uses google-services.json from android/app/
      await Firebase.initializeApp();
      firebaseReady = true;
    } else {
      firebaseReady = false; // other platforms skipped for now
    }
  } catch (e) {
    initError = e.toString();
  }

  runApp(App(initError: initError, firebaseReady: firebaseReady));
}

class App extends StatelessWidget {
  final String? initError;
  final bool firebaseReady;
  App({super.key, this.initError, required this.firebaseReady});

  final _router = GoRouter(
    initialLocation: '/',
    routes: [ GoRoute(path: '/', builder: (_, __) => const HomeScreen()) ],
  );

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('Init error')),
          body: Center(child: Text(initError!, textAlign: TextAlign.center)),
        ),
      );
    }
    if (!firebaseReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text('Firebase skipped (non-Android or missing JSON)')),
        ),
      );
    }
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Firebase OK + Router OK')),
    );
  }
}
