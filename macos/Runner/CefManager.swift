//
//  CefManager.swift
//  Runner
//
//  Created by dev_bh on 7/15/25.
//
import Cocoa
import FlutterMacOS

class CefManager {
    static let shared = CefManager()
    private var isInitialized = false
    private var messageLoopTimer: Timer?
    
    private init() {}
    
    func initialize() {
        guard !isInitialized else { return }
        
        // CEF 프레임워크 경로 설정
        let bundle = Bundle.main
        let frameworkPath = bundle.path(forResource: "Chromium Embedded Framework", ofType: "framework")
        let resourcesPath = bundle.path(forResource: "cef_bin", ofType: nil)
        
        guard let frameworkPath = frameworkPath,
              let resourcesPath = resourcesPath else {
            print("CEF framework or resources not found")
            return
        }
        
        // CEF 설정 초기화
        var settings = cef_settings_t()
        cef_settings_t_init(&settings)
        
        settings.no_sandbox = 1
        settings.multi_threaded_message_loop = 0
        settings.external_message_pump = 1
        settings.windowless_rendering_enabled = 1
        settings.log_severity = LOGSEVERITY_DISABLE
        settings.remote_debugging_port = -1
        
        // 경로 설정
        let frameworkPathCef = cef_string_userfree_alloc()
        cef_string_from_utf8(frameworkPath, frameworkPath.count, frameworkPathCef)
        settings.framework_dir_path = frameworkPathCef.pointee
        
        let resourcesPathCef = cef_string_userfree_alloc()
        cef_string_from_utf8(resourcesPath, resourcesPath.count, resourcesPathCef)
        settings.resources_dir_path = resourcesPathCef.pointee
        
        let localesPath = "\(resourcesPath)/locales"
        let localesPathCef = cef_string_userfree_alloc()
        cef_string_from_utf8(localesPath, localesPath.count, localesPathCef)
        settings.locales_dir_path = localesPathCef.pointee
        
        // Main args 설정
        var args = cef_main_args_t()
        args.argc = 0
        args.argv = nil
        
        // CEF 초기화
        let result = cef_initialize(&args, &settings, nil, nil)
        
        if result == 1 {
            isInitialized = true
            setupMessageLoop()
            print("CEF initialized successfully")
        } else {
            print("CEF initialization failed")
        }
        
        // 메모리 해제
        cef_string_userfree_free(frameworkPathCef)
        cef_string_userfree_free(resourcesPathCef)
        cef_string_userfree_free(localesPathCef)
    }
    
    private func setupMessageLoop() {
        // CEF 메시지 루프를 메인 스레드에서 실행
        messageLoopTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            cef_do_message_loop_work()
        }
    }
    
    func shutdown() {
        guard isInitialized else { return }
        
        messageLoopTimer?.invalidate()
        messageLoopTimer = nil
        
        cef_shutdown()
        isInitialized = false
        print("CEF shutdown completed")
    }
    
    deinit {
        shutdown()
    }
}