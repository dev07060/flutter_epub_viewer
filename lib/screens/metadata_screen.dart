import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/book_notifier.dart';

class MetadataScreen extends StatelessWidget {
  const MetadataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Information'),
      ),
      body: Consumer<BookNotifier>(
        builder: (context, notifier, child) {
          final book = notifier.currentBook;
          if (book == null) {
            return const Center(child: Text('No book data available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (book.coverImagePath.isNotEmpty)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: Image.file(
                        File(book.coverImagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported, size: 100);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildInfoTile('Title', book.title),
                const Divider(),
                _buildInfoTile('Author', book.author),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      contentPadding: EdgeInsets.zero,
    );
  }
}

