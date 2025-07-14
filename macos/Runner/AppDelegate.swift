import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    // CEF 초기화
    CefManager.shared.initialize()

    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
        fatalError("Could not get FlutterViewController")
    }

    let viewFactory = CefViewFactory(messenger: controller.engine.binaryMessenger)
    // "com.example.flutter_epub_viewer/cef_view"는 Dart 코드에서 사용할 고유 ID입니다.
    controller.registrar(forPlugin: "CefView").register(viewFactory, withId: "com.example.flutter_epub_viewer/cef_view")
  }
  
  override func applicationWillTerminate(_ aNotification: Notification) {
    // CEF 정리
    CefManager.shared.shutdown()
  }
}
