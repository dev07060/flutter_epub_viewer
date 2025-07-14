import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../notifiers/book_notifier.dart';
import 'metadata_screen.dart';
import 'toc_screen.dart';

// CEF 뷰 컨트롤러 클래스
class CefViewController {
  CefViewController(int viewId) : _channel = MethodChannel('com.example.flutter_epub_viewer/cef_view_$viewId') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;

  Future<void> navigate(String url) async {
    return _channel.invokeMethod('navigate', {'url': url});
  }

  Future<void> executeJavaScript(String script) async {
    return _channel.invokeMethod('executeJavaScript', {'script': script});
  }

  // 네이티브에서 오는 호출을 처리
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPageFinished':
        // 페이지 로딩 완료 이벤트 처리
        final String url = call.arguments['url'];
        print('Page finished loading: $url');
        break;
      // 다른 콜백들...
    }
  }
}

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  // late final WebViewController _controller; // 기존 컨트롤러 삭제
  BookNotifier? _notifier;
  CefViewController? _cefController;

  @override
  void initState() {
    super.initState();
    // 네이티브 뷰는 위젯 트리에서 직접 빌드되므로 initState에서의 초기화가 필요 없습니다.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier ??= Provider.of<BookNotifier>(context, listen: false);
  }

  @override
  void dispose() {
    _notifier?.clearBook(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookNotifier>(
      builder: (context, notifier, child) {
        final book = notifier.currentBook;
        if (book == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final firstChapterPath = book.chapters[notifier.currentChapterIndex].contentFilePath;

        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(book.title, style: const TextStyle(fontSize: 16.0)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TocScreen()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Bookmark current page',
                  onPressed: () {
                    notifier.saveBookmark();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Bookmark saved!'), duration: Duration(seconds: 1)));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Book Info',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MetadataScreen()));
                  },
                ),
              ],
            ),
            // body: WebViewWidget(controller: _controller), // 기존 웹뷰 위젯을 아래의 PlatformView로 교체
            body: CefPlatformView(
              initialUrl: "file://$firstChapterPath",
              onCefViewCreated: (controller) {
                _cefController = controller;
                // 이제 _cefController를 사용해 JS 실행, 페이지 이동 등을 할 수 있습니다.
              },
            ), // 새로운 CEF 뷰 위젯
            bottomNavigationBar: _buildControlPanel(context, notifier),
          ),
        );
      },
    );
  }

  Widget _buildControlPanel(BuildContext context, BookNotifier notifier) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () => notifier.changeFontSize(false),
            tooltip: 'Decrease font size',
          ),
          IconButton(
            icon: Icon(notifier.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => notifier.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () => notifier.changeFontSize(true),
            tooltip: 'Increase font size',
          ),
        ],
      ),
    );
  }
}

// 새로운 CEF 뷰를 래핑하는 StatefulWidget
class CefPlatformView extends StatefulWidget {
  final String initialUrl;
  final Function(CefViewController) onCefViewCreated;

  const CefPlatformView({super.key, required this.initialUrl, required this.onCefViewCreated});

  @override
  State<CefPlatformView> createState() => _CefPlatformViewState();
}

class _CefPlatformViewState extends State<CefPlatformView> {
  @override
  Widget build(BuildContext context) {
    // 네이티브 코드에 정의한 ViewType ID
    const String viewType = 'com.example.flutter_epub_viewer/cef_view';
    // 네이티브 뷰에 전달할 파라미터
    final Map<String, dynamic> creationParams = <String, dynamic>{'initialUrl': widget.initialUrl};

    // macOS 환경에서만 이 위젯을 사용합니다.
    if (Theme.of(context).platform == TargetPlatform.macOS) {
      return UiKitView(
        // macOS에서는 UiKitView를 사용합니다.
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          widget.onCefViewCreated(CefViewController(id));
        },
      );
    } else {
      // 다른 플랫폼에서는 기존 웹뷰나 다른 구현을 사용합니다.
      return const Center(child: Text('CEF View is only available on macOS.'));
    }
  }
}
