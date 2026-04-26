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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDSqBOpzIMUX1Zzqm6OR7lo2em0Bk5LiT4',
    appId: '1:698853743248:web:c7a24fe3d201bbd38d5615',
    messagingSenderId: '698853743248',
    projectId: 'synthora-ai-7b44f',
    authDomain: 'synthora-ai-7b44f.firebaseapp.com',
    storageBucket: 'synthora-ai-7b44f.firebasestorage.app',
    measurementId: 'G-GF04MQP7L0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSqBOpzIMUX1Zzqm6OR7lo2em0Bk5LiT4',
    appId: '1:698853743248:android:c7a24fe3d201bbd38d5615', // Fake values based on user web options for now
    messagingSenderId: '698853743248',
    projectId: 'synthora-ai-7b44f',
    storageBucket: 'synthora-ai-7b44f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDSqBOpzIMUX1Zzqm6OR7lo2em0Bk5LiT4',
    appId: '1:698853743248:ios:c7a24fe3d201bbd38d5615', // Fake values based on user web options for now
    messagingSenderId: '698853743248',
    projectId: 'synthora-ai-7b44f',
    storageBucket: 'synthora-ai-7b44f.firebasestorage.app',
    iosBundleId: 'com.example.synthoraAi',
  );
}
