import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAw5PF899jvM3ZTSP67619kxw5UzoAVMVc',
    appId: '1:838668599164:android:8aa554aa058927adcceef9',
    messagingSenderId: '838668599164',
    projectId: 'human-rhythms',
    storageBucket: 'human-rhythms.firebasestorage.app',
  );
}
