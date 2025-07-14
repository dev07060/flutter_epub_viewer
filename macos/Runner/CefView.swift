//
//  CefView.swift
//  Runner
//
//  Created by dev_bh on 7/14/25.
//

import Cocoa
import FlutterMacOS

class CefView: NSObject {
    private var _view: NSView
    private var _cefBrowser: UnsafeMutablePointer<cef_browser_t>?
    private var _client: UnsafeMutablePointer<cef_client_t>?
    private let viewId: Int64
    private let methodChannel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        self.viewId = viewId
        
        // Flutter와의 통신을 위한 method channel 설정
        self.methodChannel = FlutterMethodChannel(
            name: "com.example.flutter_epub_viewer/cef_view_\(viewId)",
            binaryMessenger: messenger!
        )
        
        // CEF 브라우저를 담을 컨테이너 뷰 생성
        self._view = NSView(frame: frame)
        self._view.wantsLayer = true
        
        super.init()
        
        // Method channel 핸들러 설정
        setupMethodChannel()
        
        // CEF 브라우저 생성
        createCefBrowser(frame: frame, args: args)
    }
    
    private func setupMethodChannel() {
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "navigate":
                if let arguments = call.arguments as? [String: Any],
                   let url = arguments["url"] as? String {
                    self.navigate(to: url)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "URL is required", details: nil))
                }
                
            case "executeJavaScript":
                if let arguments = call.arguments as? [String: Any],
                   let script = arguments["script"] as? String {
                    self.executeJavaScript(script)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Script is required", details: nil))
                }
                
            case "goBack":
                self.goBack()
                result(nil)
                
            case "goForward":
                self.goForward()
                result(nil)
                
            case "reload":
                self.reload()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func createCefBrowser(frame: CGRect, args: Any?) {
        // CEF 클라이언트 생성
        self._client = createCefClient()
        
        // 윈도우 정보 설정
        var windowInfo = cef_window_info_t()
        windowInfo.bounds.x = Int32(frame.origin.x)
        windowInfo.bounds.y = Int32(frame.origin.y)
        windowInfo.bounds.width = Int32(frame.size.width)
        windowInfo.bounds.height = Int32(frame.size.height)
        windowInfo.parent_view = unsafeBitCast(self._view, to: UnsafeMutableRawPointer.self)
        windowInfo.windowless_rendering_enabled = 0
        
        // 브라우저 설정
        var browserSettings = cef_browser_settings_t()
        browserSettings.size = MemoryLayout<cef_browser_settings_t>.size
        
        // 초기 URL 설정
        var initialUrl = "about:blank"
        if let argsDict = args as? [String: Any],
           let url = argsDict["initialUrl"] as? String {
            initialUrl = url
        }
        
        let cefUrl = createCefString(initialUrl)
        
        // CEF 브라우저 생성 (비동기)
        cef_browser_host_create_browser(&windowInfo, self._client, &cefUrl, &browserSettings, nil, nil)
    }
    
    func view() -> NSView {
        return _view
    }
    
    // MARK: - Public Methods
    
    func navigate(to url: String) {
        guard let browser = _cefBrowser else { return }
        
        let mainFrame = browser.pointee.get_main_frame(browser)
        let cefUrl = createCefString(url)
        mainFrame?.pointee.load_url(mainFrame, &cefUrl)
    }
    
    func executeJavaScript(_ script: String) {
        guard let browser = _cefBrowser else { return }
        
        let mainFrame = browser.pointee.get_main_frame(browser)
        let cefScript = createCefString(script)
        let cefUrl = createCefString("") // 빈 URL
        mainFrame?.pointee.execute_java_script(mainFrame, &cefScript, &cefUrl, 0)
    }
    
    func goBack() {
        guard let browser = _cefBrowser else { return }
        browser.pointee.go_back(browser)
    }
    
    func goForward() {
        guard let browser = _cefBrowser else { return }
        browser.pointee.go_forward(browser)
    }
    
    func reload() {
        guard let browser = _cefBrowser else { return }
        browser.pointee.reload(browser)
    }
    
    // MARK: - Helper Methods
    
    private func createCefString(_ str: String) -> cef_string_t {
        let utf16 = Array(str.utf16)
        let buffer = UnsafeMutablePointer<unichar>.allocate(capacity: utf16.count)
        buffer.initialize(from: utf16, count: utf16.count)
        
        return cef_string_t(
            str: buffer,
            length: utf16.count,
            dtor: { ptr in
                ptr?.deallocate()
            }
        )
    }
    
    private func createCefClient() -> UnsafeMutablePointer<cef_client_t> {
        let client = UnsafeMutablePointer<cef_client_t>.allocate(capacity: 1)
        
        // 기본 ref counted 구조체 초기화
        client.pointee.base = cef_base_ref_counted_t(
            size: MemoryLayout<cef_client_t>.size,
            add_ref: { base in
                // Reference count 증가
                return 1
            },
            release: { base in
                // Reference count 감소 및 메모리 해제
                return 1
            },
            has_one_ref: { base in
                return 1
            },
            has_at_least_one_ref: { base in
                return 1
            }
        )
        
        // Life span handler 설정
        client.pointee.get_life_span_handler = { client in
            return createLifeSpanHandler()
        }
        
        // Load handler 설정
        client.pointee.get_load_handler = { client in
            return createLoadHandler()
        }
        
        return client
    }
    
    deinit {
        _client?.deallocate()
    }
}

// MARK: - CEF Handlers

func createLifeSpanHandler() -> UnsafeMutablePointer<cef_life_span_handler_t>? {
    let handler = UnsafeMutablePointer<cef_life_span_handler_t>.allocate(capacity: 1)
    
    handler.pointee.base = cef_base_ref_counted_t(
        size: MemoryLayout<cef_life_span_handler_t>.size,
        add_ref: { _ in return 1 },
        release: { _ in return 1 },
        has_one_ref: { _ in return 1 },
        has_at_least_one_ref: { _ in return 1 }
    )
    
    handler.pointee.on_after_created = { handler, browser in
        // 브라우저가 생성된 후 호출
        print("Browser created")
    }
    
    handler.pointee.on_before_close = { handler, browser in
        // 브라우저가 닫히기 전 호출
        print("Browser closing")
    }
    
    return handler
}

func createLoadHandler() -> UnsafeMutablePointer<cef_load_handler_t>? {
    let handler = UnsafeMutablePointer<cef_load_handler_t>.allocate(capacity: 1)
    
    handler.pointee.base = cef_base_ref_counted_t(
        size: MemoryLayout<cef_load_handler_t>.size,
        add_ref: { _ in return 1 },
        release: { _ in return 1 },
        has_one_ref: { _ in return 1 },
        has_at_least_one_ref: { _ in return 1 }
    )
    
    handler.pointee.on_load_end = { handler, browser, frame, httpStatusCode in
        // 페이지 로딩 완료시 호출
        print("Page load completed with status: \(httpStatusCode)")
    }
    
    return handler
}

// CEF API는 이제 Bridging Header를 통해 사용할 수 있습니다
