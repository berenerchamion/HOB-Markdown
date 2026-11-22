import Cocoa
import FlutterMacOS

/// Native side of the window channel. Flutter draws its own toolbar under a
/// transparent title bar, so it asks the window to drag, zoom and show the
/// document's title and edited state, and hears about full screen changes.
final class WindowBridge {
  static let shared = WindowBridge()

  private weak var window: NSWindow?
  private var channel: FlutterMethodChannel?
  private var observers: [NSObjectProtocol] = []

  func install(on messenger: FlutterBinaryMessenger, window: NSWindow) {
    self.window = window
    let channel = FlutterMethodChannel(
      name: "com.hob.markdown/window",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel

    let center = NotificationCenter.default
    for name in [NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification] {
      observers.append(
        center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
          self?.channel?.invokeMethod("fullScreenChanged", arguments: self?.isFullScreen ?? false)
        })
    }
  }

  private var isFullScreen: Bool {
    window?.styleMask.contains(.fullScreen) ?? false
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let window = window else {
      result(nil)
      return
    }
    switch call.method {
    case "startDrag":
      if let event = window.currentEvent {
        window.performDrag(with: event)
      }
      result(nil)
    case "titleBarDoubleClicked":
      // Respect System Settings > Desktop & Dock > "Double-click a window's title bar to".
      switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
      case "Minimize": window.miniaturize(nil)
      case "None": break
      default: window.zoom(nil)
      }
      result(nil)
    case "setDocument":
      let args = call.arguments as? [String: Any] ?? [:]
      window.title = args["title"] as? String ?? "HOB Markdown"
      if let path = args["path"] as? String, !path.isEmpty {
        window.representedURL = URL(fileURLWithPath: path)
      } else {
        window.representedURL = nil
      }
      window.isDocumentEdited = args["edited"] as? Bool ?? false
      result(nil)
    case "isFullScreen":
      result(isFullScreen)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Let Flutter draw under a transparent title bar so the traffic lights
    // sit inside the app's own toolbar. The empty unified toolbar makes the
    // title bar 52 pt tall, which centres the traffic lights in Flutter's
    // toolbar (AppToolbar uses the same height on macOS).
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    self.toolbar = NSToolbar(identifier: "HOBMainToolbar")
    self.toolbarStyle = .unified
    self.titlebarSeparatorStyle = .none

    // Use the last saved size if there is one, otherwise the default.
    if !self.setFrameUsingName("HOBMainWindow") {
      var windowFrame = self.frame
      windowFrame.size = NSSize(width: 1100, height: 760)
      self.setFrame(windowFrame, display: true)
      self.center()
    }
    // From now on, macOS saves size and position whenever they change.
    self.setFrameAutosaveName("HOBMainWindow")

    FileOpenBridge.shared.install(on: flutterViewController.engine.binaryMessenger)
    WindowBridge.shared.install(on: flutterViewController.engine.binaryMessenger, window: self)
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
