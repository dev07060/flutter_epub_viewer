import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/notifiers/book_notifier.dart';
import 'package:flutter_epub_viewer/screens/viewer_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickAndLoadEpub(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        print('Selected file path: $filePath');

        // Check if the file actually exists and is a file (not a directory)
        final file = File(filePath);
        if (!await file.exists()) {
          print('File does not exist: $filePath');
          throw Exception('Selected file does not exist');
        }

        if (await FileSystemEntity.isDirectory(filePath)) {
          print('Selected path is a directory, not a file: $filePath');
          throw Exception('Selected path is a directory, not a file');
        }

        final bookNotifier = Provider.of<BookNotifier>(context, listen: false);
        final success = await bookNotifier.loadBook(filePath);

        // Check mount status again after async gap
        if (context.mounted) {
          if (success) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewerScreen()));
          } else {
            // Show error message if book loading failed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load EPUB. The file may be corrupt or unsupported.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error in _pickAndLoadEpub: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting file: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Epub Viewer')),
      body: Center(
        child: Consumer<BookNotifier>(
          builder: (context, notifier, child) {
            return notifier.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: () => _pickAndLoadEpub(context), child: const Text('Open EPUB File'));
          },
        ),
      ),
    );
  }
}
