import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var queuedFilePath: String?
  private var isDartReady = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    if let messenger = controller?.engine.binaryMessenger {
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
          self.isDartReady = true
          result(self.queuedFilePath)
          self.queuedFilePath = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      self.methodChannel = channel
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      if url.isFileURL {
        handleOpenFile(url.path)
        break
      }
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
    if isDartReady, let channel = methodChannel {
      channel.invokeMethod("onFileOpened", arguments: path)
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
