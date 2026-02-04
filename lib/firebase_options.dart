import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHEuq-MAU-qnSegx21ZMJXvGmjOt77s30',
    appId: '1:882819855244:android:24fff60a20431abe405ca9',
    messagingSenderId: '882819855244',
    projectId: 'prima2',
    storageBucket: 'prima2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDHEuq-MAU-qnSegx21ZMJXvGmjOt77s30',
    appId: '1:882819855244:ios:24fff60a20431abe405ca9',
    messagingSenderId: '882819855244',
    projectId: 'prima2',
    storageBucket: 'prima2.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDHEuq-MAU-qnSegx21ZMJXvGmjOt77s30',
    appId: '1:882819855244:macos:24fff60a20431abe405ca9',
    messagingSenderId: '882819855244',
    projectId: 'prima2',
    storageBucket: 'prima2.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDHEuq-MAU-qnSegx21ZMJXvGmjOt77s30',
    appId: '1:882819855244:web:24fff60a20431abe405ca9',
    messagingSenderId: '882819855244',
    projectId: 'prima2',
    storageBucket: 'prima2.firebasestorage.app',
  );
}
