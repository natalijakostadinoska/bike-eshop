import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAKpTqx1S-WwtWfoUC3h8Xv_IUWbGp-nDg',
    appId: '1:1004322533169:web:b61f788e8e5021b74dca10',
    messagingSenderId: '1004322533169',
    projectId: 'bicikla-eshop',
    authDomain: 'bicikla-eshop.firebaseapp.com',
    storageBucket: 'bicikla-eshop.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKpTqx1S-WwtWfoUC3h8Xv_IUWbGp-nDg',
    appId: '1:1004322533169:android:YOUR_ANDROID_APP_ID', // Get this from Firebase Android settings
    messagingSenderId: '1004322533169',
    projectId: 'bicikla-eshop',
    storageBucket: 'bicikla-eshop.firebasestorage.app',
  );
}