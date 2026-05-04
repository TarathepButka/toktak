// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:toktak/app.dart';
import 'package:toktak/core/storage/local_storage_service.dart';
import 'package:toktak/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize local storage
  await LocalStorageService.init();

  // Initialize dependency injection
  await configureDependencies();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize LINE SDK (using env variable)
  final lineChannelId = dotenv.env['LINE_CHANNEL_ID'];
  if (lineChannelId != null) {
    try {
      await LineSDK.instance.setup(lineChannelId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("LINE SDK Setup timed out");
          return;
        },
      );
      debugPrint("LINE SDK Prepared with Channel ID: $lineChannelId");
    } catch (e) {
      debugPrint("LINE SDK Setup error: $e");
    }
  } else {
    debugPrint("⚠️ LINE_CHANNEL_ID not found in .env file");
  }

  runApp(const TokTakApp());
}
