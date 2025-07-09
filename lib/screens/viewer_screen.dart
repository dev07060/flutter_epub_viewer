import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../notifiers/book_notifier.dart';
import 'toc_screen.dart';
import 'metadata_screen.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final bookNotifier = Provider.of<BookNotifier>(context, listen: false);
    final book = bookNotifier.currentBook;
    if (book == null) return;

    final firstChapterPath = book.chapters[bookNotifier.currentChapterIndex].contentFilePath;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // When the page is loaded, apply the current styles.
            // This is crucial for when the user navigates between chapters.
            Provider.of<BookNotifier>(context, listen: false).applyWebViewStyles();
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadFile(firstChapterPath);
    
    // Link controller to notifier for external control
    bookNotifier.webViewController = _controller;
  }

  @override
  void dispose() {
    // Avoid memory leaks by clearing the reference in the notifier.
    // This is important when the screen is permanently removed.
    final notifier = Provider.of<BookNotifier>(context, listen: false);
    notifier.webViewController = null;
    notifier.clearBook();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookNotifier>(
      builder: (context, notifier, child) {
        final book = notifier.currentBook;
        if (book == null) {
          // This case should ideally not be reached if navigation is handled correctly,
          // but as a fallback, we navigate back.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // WillPopScope handles the Android back button.
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TocScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Bookmark current page',
                  onPressed: () {
                    notifier.saveBookmark();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bookmark saved!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Book Info',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const MetadataScreen()
                    ));
                  },
                )
              ],
            ),
            body: WebViewWidget(controller: _controller),
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