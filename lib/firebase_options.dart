// Fichier généré manuellement depuis les clés Firebase
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
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return web; 
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyARitybYjGZo8gF5uylngTAN4Swly_AqdU',
    appId: '1:685421875292:web:76daee5da3b1ed55765699',
    messagingSenderId: '685421875292',
    projectId: 'schoolflow-steve',
    authDomain: 'schoolflow-steve.firebaseapp.com',
    storageBucket: 'schoolflow-steve.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD072-B96sFVX2cRxGqzhOT8Dq1lowti5g',
    appId: '1:685421875292:android:4b47e16edc12bdcc765699',
    messagingSenderId: '685421875292',
    projectId: 'schoolflow-steve',
    storageBucket: 'schoolflow-steve.firebasestorage.app',
  );
}
