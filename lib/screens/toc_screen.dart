import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/book_notifier.dart';

class TocScreen extends StatelessWidget {
  const TocScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table of Contents'),
      ),
      body: Consumer<BookNotifier>(
        builder: (context, notifier, child) {
          final toc = notifier.currentBook?.tableOfContents ?? [];
          if (toc.isEmpty) {
            return const Center(child: Text('No table of contents found.'));
          }

          return ListView.builder(
            itemCount: toc.length,
            itemBuilder: (context, index) {
              final chapter = toc[index];
              return ListTile(
                title: Text(chapter.title),
                onTap: () {
                  // Find the chapter in the main reading order (spine)
                  // to navigate to the correct linear index.
                  final readingOrderIndex = notifier.currentBook?.chapters.indexWhere(
                    (c) => c.contentFilePath == chapter.contentFilePath
                  ) ?? -1;

                  if (readingOrderIndex != -1) {
                    notifier.goToChapter(readingOrderIndex);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not find chapter in reading order.'))
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}