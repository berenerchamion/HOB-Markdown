import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel service for managing file open events initiated by the OS
/// (e.g. macOS Finder 'Open With', double-clicking markdown files, etc.).
class FileOpenService {
  static const MethodChannel _channel =
      MethodChannel('com.antigravity.md_reader/file_open');

  static void Function(String filePath)? _listener;
  static bool _handlerInitialized = false;

  /// Retrieves any initial file path that was requested when the app was launched
  /// (cold start).
  static Future<String?> getInitialFile() async {
    try {
      final String? path = await _channel.invokeMethod<String>('getInitialFile');
      if (path != null && path.trim().isNotEmpty) {
        return path.trim();
      }
    } catch (_) {
      // Platform channel not supported on this platform or error occurred
    }
    return null;
  }

  /// Registers a callback for files opened while the app is already running
  /// (warm start).
  static void setFileOpenListener(void Function(String filePath) onFileOpened) {
    _listener = onFileOpened;
    if (!_handlerInitialized) {
      _handlerInitialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onFileOpened') {
          final dynamic arg = call.arguments;
          if (arg is String && arg.trim().isNotEmpty) {
            _listener?.call(arg.trim());
          }
        }
      });
    }
  }

  /// Resets the listener (primarily useful for testing).
  @visibleForTesting
  static void resetListenerForTesting() {
    _listener = null;
    _handlerInitialized = false;
  }
}
