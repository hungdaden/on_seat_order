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
        return web; // fallback to web config
      case TargetPlatform.iOS:
        return web; // fallback to web config
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQxMQJ5M89wzrSTKELlL6SINydQo0gNDA',
    appId: '1:1097569314991:web:243f464ac6452890c14c5a',
    messagingSenderId: '1097569314991',
    projectId: 'on-seat-order',
    authDomain: 'on-seat-order.firebaseapp.com',
    storageBucket: 'on-seat-order.firebasestorage.app',
    measurementId: 'G-YYJ9GB7VTT',
  );
}
