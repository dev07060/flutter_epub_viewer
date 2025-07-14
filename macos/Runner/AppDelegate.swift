import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    // CEF 초기화 코드는 여기에 위치하는 것이 좋습니다.
    // CefManager.shared.initialize() 와 같은 형태로 관리할 수 있습니다.

    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
        fatalError("Could not get FlutterViewController")
    }

    let viewFactory = CefViewFactory(messenger: controller.engine.binaryMessenger)
    // "com.example.flutter_epub_viewer/cef_view"는 Dart 코드에서 사용할 고유 ID입니다.
    controller.registrar(forPlugin: "CefView").register(viewFactory, withId: "com.example.flutter_epub_viewer/cef_view")
  }
}
