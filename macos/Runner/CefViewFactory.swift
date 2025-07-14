//
//  CefViewFactory.swift
//  Runner
//
//  Created by dev_bh on 7/14/25.
//


import FlutterMacOS

class CefViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        let cefView = CefView(
            frame: CGRect.zero,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
        return cefView.view()
    }

    // Dart에서 PlatformView로 전달된 데이터를 디코딩하는 부분입니다.
    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}