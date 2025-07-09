import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/epub_book.dart';
import '../services/epub_service.dart';

class BookNotifier extends ChangeNotifier {
  final EpubService _epubService = EpubService();

  EpubBook? _currentBook;
  EpubBook? get currentBook => _currentBook;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentChapterIndex = 0;
  int get currentChapterIndex => _currentChapterIndex;

  double _fontSize = 100.0; // Using percentage for easier scaling
  double get fontSize => _fontSize;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  WebViewController? webViewController;

  Future<bool> loadBook(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentBook = await _epubService.openEpub(filePath);
      // After loading the book, try to load a bookmark for it.
      final bookmarkedChapter = await _loadBookmark(filePath);
      if (bookmarkedChapter != null && bookmarkedChapter < _currentBook!.chapters.length) {
        _currentChapterIndex = bookmarkedChapter;
      }
      _currentChapterIndex = 0;
    } catch (e, s) {
      // Handle error appropriately in a real app
      debugPrint("Error loading book: $e\n$s");
      _currentBook = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      return _currentBook != null;
    }
  }

  void goToChapter(int index) {
    if (_currentBook == null || index < 0 || index >= _currentBook!.chapters.length) {
      return;
    }
    _currentChapterIndex = index;
    _loadChapterIntoWebView();
    notifyListeners();
  }

  void _loadChapterIntoWebView() {
    final chapter = _currentBook!.chapters[_currentChapterIndex];
    // Using `loadFile` is correct for local files.
    // The webview_flutter plugin handles creating a local server on Android
    // and using file URLs on iOS.
    webViewController?.loadFile(chapter.contentFilePath);
  }

  void changeFontSize(bool increase) {
    if (increase) {
      _fontSize += 10.0;
    } else {
      _fontSize -= 10.0;
    }
    if (_fontSize < 50) _fontSize = 50; // Set a min size
    if (_fontSize > 200) _fontSize = 200; // Set a max size

    applyWebViewStyles();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    applyWebViewStyles();
    notifyListeners();
  }

  /// Injects JavaScript into the webview to apply current font size and theme.
  void applyWebViewStyles() {
    if (webViewController == null) return;

    final String bgColor = _isDarkMode ? '#121212' : '#FFFFFF';
    final String textColor = _isDarkMode ? '#FFFFFF' : '#000000';

    // This JS code will be executed in the webview.
    // It sets the font size on the body and changes background/text color.
    // Using a try-catch block inside JS is a safeguard.
    final script = """
      try {
        document.body.style.fontSize = '${_fontSize}%';
        document.body.style.backgroundColor = '$bgColor';
        document.body.style.color = '$textColor';
        
        // Also change link colors for visibility
        var links = document.getElementsByTagName('a');
        for(var i=0; i<links.length; i++) {
          links[i].style.color = '$textColor';
        }
      } catch (e) {
        // window.flutter_inappwebview might not be available on all platforms
        // or versions, so we can use a simple alert for debugging.
        // alert('Error applying styles: ' + e);
      }
    """;
    webViewController!.runJavaScript(script);
  }

  /// Clears the current book data when the viewer is closed.
  void clearBook() {
    // We keep the webViewController reference until the screen is disposed
    // but clear the book data.
    _currentBook = null;
    // Reset settings to default
    _fontSize = 100.0;
    _isDarkMode = false;
    // Notify to clear the UI before popping the screen
    notifyListeners();
  }

  /// Saves the current chapter index as a bookmark.
  Future<void> saveBookmark() async {
    if (_currentBook == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Use the unzipped path as a unique key for the book.
    final key = 'bookmark_${_currentBook!.unzippedPath.hashCode}';
    await prefs.setInt(key, _currentChapterIndex);
  }

  /// Loads the bookmark for a given book file path.
  Future<int?> _loadBookmark(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bookmark_${filePath.hashCode}';
    return prefs.getInt(key);
  }
}