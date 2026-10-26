import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

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
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
