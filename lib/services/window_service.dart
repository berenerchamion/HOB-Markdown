import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the macOS window channel (`WindowBridge` in
/// `MainFlutterWindow.swift`).
///
/// On macOS the app draws its own toolbar under a transparent title bar, so
/// the window can no longer be dragged or zoomed from a native title bar, and
/// the title isn't shown. This service asks the native window to do those
/// things. On other platforms, and in tests, every call is a quiet no-op.
class WindowService {
  static const MethodChannel _channel = MethodChannel(
    'com.hob.markdown/window',
  );

  /// Whether the window is in full screen, where the traffic lights are
  /// hidden and the toolbar no longer needs to leave room for them.
  static final ValueNotifier<bool> isFullScreen = ValueNotifier<bool>(false);

  static bool _initialized = false;

  /// True where the toolbar shares space with the traffic lights.
  static bool get usesCustomTitleBar =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Width the toolbar leaves free on the left for the traffic lights.
  static const double trafficLightInset = 78;

  /// Height of the native unified toolbar, so the traffic lights are
  /// vertically centred in the Flutter toolbar.
  static const double titleBarHeight = 52;

  /// Starts listening for full screen changes. Safe to call more than once.
  static Future<void> init() async {
    if (!usesCustomTitleBar || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'fullScreenChanged' && call.arguments is bool) {
        isFullScreen.value = call.arguments as bool;
      }
    });
    final value = await _invoke<bool>('isFullScreen');
    if (value != null) isFullScreen.value = value;
  }

  /// Moves the window with the mouse. Call when a drag starts in the toolbar.
  static Future<void> startDrag() => _invoke<void>('startDrag');

  /// Zooms or minimizes the window, following the user's system setting for
  /// double-clicking a title bar.
  static Future<void> titleBarDoubleClicked() =>
      _invoke<void>('titleBarDoubleClicked');

  static String? _lastTitle;
  static String? _lastPath;
  static bool? _lastEdited;

  /// Tells the window which document it shows. macOS uses the title in
  /// Mission Control and the Dock, and [edited] puts the dot in the close
  /// button. Repeated calls with the same values are skipped.
  static Future<void> setDocument({
    required String title,
    String? path,
    required bool edited,
  }) async {
    if (!usesCustomTitleBar) return;
    if (title == _lastTitle && path == _lastPath && edited == _lastEdited) {
      return;
    }
    _lastTitle = title;
    _lastPath = path;
    _lastEdited = edited;
    await _invoke<void>('setDocument', <String, Object?>{
      'title': title,
      'path': path,
      'edited': edited,
    });
  }

  static Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!usesCustomTitleBar) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('Window channel error for $method: $e');
      return null;
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _lastTitle = null;
    _lastPath = null;
    _lastEdited = null;
    isFullScreen.value = false;
  }
}
