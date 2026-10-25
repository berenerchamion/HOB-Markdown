import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Install the file-open channel now, on the same call stack that starts
    // the engine, so it exists before Dart's main() can call getInitialFile.
    FileOpenBridge.shared.install(on: flutterViewController.engine.binaryMessenger)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
