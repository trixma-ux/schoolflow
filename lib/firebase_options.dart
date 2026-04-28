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
    apiKey: 'AIzaSyCkDC8BsDtaOTwVtLfmRWcWJEZO4c-IFuM',
    appId: '1:795443441609:web:490da4945078b2b4e30218',
    messagingSenderId: '795443441609',
    projectId: 'schoolflow-42186',
    authDomain: 'schoolflow-42186.firebaseapp.com',
    storageBucket: 'schoolflow-42186.firebasestorage.app',
    measurementId: 'G-XJM1PE30KB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhFRN4l00OBj13nQaffJ-TwyHL9ZqO4oc',
    appId: '1:795443441609:android:d57cbe35ad48ed53e30218',
    messagingSenderId: '795443441609',
    projectId: 'schoolflow-42186',
    storageBucket: 'schoolflow-42186.firebasestorage.app',
  );
}
