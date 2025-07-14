import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/notifiers/book_notifier.dart';
import 'package:provider/provider.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  // late final WebViewController _controller; // 기존 컨트롤러 삭제
  BookNotifier? _notifier;

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
              // ... 기존 AppBar 코드는 동일 ...
            ),
            // body: WebViewWidget(controller: _controller), // 기존 웹뷰 위젯을 아래의 PlatformView로 교체
            body: CefPlatformView(initialUrl: "file://$firstChapterPath"), // 새로운 CEF 뷰 위젯
            bottomNavigationBar: _buildControlPanel(context, notifier),
          ),
        );
      },
    );
  }

  Widget _buildControlPanel(BuildContext context, BookNotifier notifier) {
    // ... 기존 BottomAppBar 코드는 동일 ...
    return SizedBox();
  }
}

// 새로운 CEF 뷰를 래핑하는 StatelessWidget
class CefPlatformView extends StatelessWidget {
  final String initialUrl;

  const CefPlatformView({super.key, required this.initialUrl});

  @override
  Widget build(BuildContext context) {
    // 네이티브 코드에 정의한 ViewType ID
    const String viewType = 'com.example.flutter_epub_viewer/cef_view';
    // 네이ティブ 뷰에 전달할 파라미터
    final Map<String, dynamic> creationParams = <String, dynamic>{'initialUrl': initialUrl};

    // macOS 환경에서만 이 위젯을 사용합니다.
    if (Theme.of(context).platform == TargetPlatform.macOS) {
      return UiKitView(
        // macOS에서는 UiKitView를 사용합니다.
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      // 다른 플랫폼에서는 기존 웹뷰나 다른 구현을 사용합니다.
      return const Center(child: Text('CEF View is only available on macOS.'));
    }
  }
}
