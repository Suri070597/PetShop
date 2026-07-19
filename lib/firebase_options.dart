import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGyvPdYyKGB18U61BR-NDCZRAQCgJla38',
    appId: '1:590763056596:android:b1c866d61dee7cb4880a41',
    messagingSenderId: '590763056596',
    projectId: 'pet-shop-55b98',
    storageBucket: 'pet-shop-55b98.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTSNQazTg-BGHCzF1Iq-ivoPlfoo47x4o',
    appId: '1:590763056596:ios:6f9e6c5fe1527a70880a41',
    messagingSenderId: '590763056596',
    projectId: 'pet-shop-55b98',
    storageBucket: 'pet-shop-55b98.firebasestorage.app',
    iosBundleId: 'com.example.petShop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCGyvPdYyKGB18U61BR-NDCZRAQCgJla38',
    appId: '1:590763056596:android:b1c866d61dee7cb4880a41',
    messagingSenderId: '590763056596',
    projectId: 'pet-shop-55b98',
    authDomain: 'pet-shop-55b98.firebaseapp.com',
    storageBucket: 'pet-shop-55b98.firebasestorage.app',
  );
}
