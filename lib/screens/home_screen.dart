import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/book_notifier.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickAndLoadEpub(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null && result.files.single.path != null) {
      final bookNotifier = Provider.of<BookNotifier>(context, listen: false);
      final success = await bookNotifier.loadBook(result.files.single.path!);
      
      // Check mount status again after async gap
      if (context.mounted) {
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewerScreen()),
          );
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
                : ElevatedButton(
                    onPressed: () => _pickAndLoadEpub(context),
                    child: const Text('Open EPUB File'),
                  );
          },
        ),
      ),
    );
  }
}