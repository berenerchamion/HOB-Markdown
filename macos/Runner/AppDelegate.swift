import Cocoa
import FlutterMacOS

/// Native side of the "open this file" channel. Queues a path until Dart
/// asks for it (cold start), then pushes later paths directly (warm start).
final class FileOpenBridge {
  static let shared = FileOpenBridge()

  private var channel: FlutterMethodChannel?
  private var queuedPath: String?
  private var isDartReady = false

  func install(on messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.hob.markdown/file_open",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self, call.method == "getInitialFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.isDartReady = true
      let path = self.queuedPath
      self.queuedPath = nil
      result(path)
    }
    self.channel = channel
  }

  func open(_ path: String) {
    if isDartReady, let channel = channel {
      channel.invokeMethod("onFileOpened", arguments: path)
    } else {
      queuedPath = path
    }
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  override func application(_ application: NSApplication, open urls: [URL]) {
    if let url = urls.first(where: { $0.isFileURL }) {
      handleOpenFile(url.path)
    }
    super.application(application, open: urls)
  }

  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    handleOpenFile(filename)
    return true
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    if let first = filenames.first {
      handleOpenFile(first)
    }
    sender.reply(toOpenOrPrint: .success)
  }

  private func handleOpenFile(_ path: String) {
    FileOpenBridge.shared.open(path)
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
