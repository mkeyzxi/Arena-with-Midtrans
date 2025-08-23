// File ini dihasilkan oleh FlutterFire CLI.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak mendukung platform ini.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak mendukung platform ini.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6JoaJF9SStEEdNCMmvHh60IH_02lx8IA',
    appId: '1:374216151534:web:ee4e14b101c3210e2d3eff',
    messagingSenderId: '374216151534',
    projectId: 'arena-b32ac',
    authDomain: 'arena-b32ac.firebaseapp.com',
    storageBucket: 'arena-b32ac.firebasestorage.app',
    measurementId: 'G-4Y5V9TFCCD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQOgq6DkfOX3ESdF_rOabzMT5LEvMlOTs',
    appId: '1:374216151534:android:bd3210f7e0abcb792d3eff',
    messagingSenderId: '374216151534',
    projectId: 'arena-b32ac',
    storageBucket: 'arena-b32ac.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBaq9O9wdlULOlg1Ivtg1_DtJsNUG7xZsQ',
    appId: '1:374216151534:ios:5fe7ed6c379f68542d3eff',
    messagingSenderId: '374216151534',
    projectId: 'arena-b32ac',
    storageBucket: 'arena-b32ac.firebasestorage.app',
    iosBundleId: 'com.example.arenaApp',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = web;
}
