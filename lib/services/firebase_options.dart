import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_SSiiCVSOp436hUyZhMs700qG7hAMMj4',
    appId: '1:25186592790:web:a7c1a60b5c9473845e2d37',
    messagingSenderId: '25186592790',
    projectId: 'unimate-94265',
    authDomain: 'unimate-94265.firebaseapp.com',
    storageBucket: 'unimate-94265.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDowvRCFPllwvjC4WEv0g2VUfa-vlJU24s',
    appId: '1:25186592790:android:c0e02dc489332aef5e2d37',
    messagingSenderId: '25186592790',
    projectId: 'unimate-94265',
    storageBucket: 'unimate-94265.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '25186592790',
    projectId: 'unimate-94265',
    storageBucket: 'unimate-94265.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.unimate',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '25186592790',
    projectId: 'unimate-94265',
    storageBucket: 'unimate-94265.firebasestorage.app',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.unimate',
  );
}
