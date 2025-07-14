//
//  CefView.swift
//  Runner
//
//  Created by dev_bh on 7/14/25.
//


import Cocoa
import FlutterMacOS
import WebKit // 임시로 사용, 실제로는 CEF 헤더를 import 해야 합니다.

class CefView: NSObject {
    private var _view: NSView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        // 실제로는 여기서 CEF 뷰를 초기화해야 합니다.
        // 지금은 CEF 초기화 코드가 복잡하므로, 임시로 WKWebView를 사용해 구조만 보여드립니다.
        // 실제 CEF 초기화는 아래 'CEF 연동 심화' 부분을 참고하세요.
        let webView = WKWebView(frame: frame)
        self._view = webView

        super.init()

        // URL 로드 예시
        if let urlString = (args as? [String: Any])?["initialUrl"] as? String,
           let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }

    func view() -> NSView {
        return _view
    }

    // TODO: 여기에 Dart로부터 메시지를 받아 처리하는 로직 추가
}
