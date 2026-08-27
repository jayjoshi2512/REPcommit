import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'data/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  // On web, the config may not exist if only android/ios were selected
  // during `flutterfire configure`. Handle gracefully.
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
    // App will still launch — auth state will be null, showing auth screen.
    // Google Sign-In will fail gracefully with an error message.
  }

  // Lock to portrait for phone-first experience (skip on web).
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0F0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  runApp(const ProviderScope(child: RepCommitApp()));
}
