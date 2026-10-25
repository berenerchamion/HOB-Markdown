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
      name: "com.antigravity.md_reader/file_open",
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

/** Instrummented for debugging

import Cocoa
import FlutterMacOS

/// Debug logger. Finder-launched apps have no visible stdout, and NSLog text
/// is redacted as <private> in the unified log, so also append to a file.
private func hobLog(_ message: String) {
  NSLog("HOB: %@", message)
  let line = "\(Date()) \(message)\n"
  let url = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("hob-debug.log")
  guard let data = line.data(using: .utf8) else { return }
  if let handle = try? FileHandle(forWritingTo: url) {
    handle.seekToEndOfFile()
    handle.write(data)
    try? handle.close()
  } else {
    try? data.write(to: url)
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var queuedFilePath: String?
  private var isDartReady = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    hobLog("didFinishLaunching: start")
    let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    hobLog("didFinishLaunching: controller found = \(controller != nil)")
    if let messenger = controller?.engine.binaryMessenger {
      hobLog("didFinishLaunching: got messenger")
      let channel = FlutterMethodChannel(
        name: "com.antigravity.md_reader/file_open",
        binaryMessenger: messenger
      )
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else {
          result(FlutterMethodNotImplemented)
          return
        }
        if call.method == "getInitialFile" {
          hobLog("getInitialFile called, queued = \(String(describing: self.queuedFilePath))")
          self.isDartReady = true
          result(self.queuedFilePath)
          self.queuedFilePath = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      self.methodChannel = channel
      hobLog("didFinishLaunching: channel installed")
    }
    hobLog("didFinishLaunching: calling super")
    super.applicationDidFinishLaunching(notification)
    hobLog("didFinishLaunching: done")
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    hobLog("callback: open urls \(urls.map { $0.path })")
    for url in urls {
      if url.isFileURL {
        handleOpenFile(url.path)
        break
      }
    }
    super.application(application, open: urls)
  }

  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    hobLog("callback: openFile \(filename)")
    handleOpenFile(filename)
    return true
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    hobLog("callback: openFiles \(filenames)")
    if let first = filenames.first {
      handleOpenFile(first)
    }
    sender.reply(toOpenOrPrint: .success)
  }

  private func handleOpenFile(_ path: String) {
    hobLog("handleOpenFile \(path) dartReady=\(isDartReady) channel=\(methodChannel != nil)")
    if isDartReady, let channel = methodChannel {
      channel.invokeMethod("onFileOpened", arguments: path) { result in
        if let err = result as? FlutterError {
          hobLog("Dart handler threw: \(err.code) \(err.message ?? "")")
        } else if let r = result, (r as AnyObject) === FlutterMethodNotImplemented {
          hobLog("no handler registered on the Dart side")
        } else {
          hobLog("Dart handled onFileOpened (result = \(String(describing: result)))")
        }
      }
    } else {
      queuedFilePath = path
    }
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
**/
