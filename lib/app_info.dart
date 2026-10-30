// lib/app_info.dart
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static String version = '';

  static Future<void> load() async {
    version = (await PackageInfo.fromPlatform()).version;
  }
}
