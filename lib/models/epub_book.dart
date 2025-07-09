class EpubBook {
  final String title;
  final String author;
  final String coverImagePath; // Path relative to the unzipped directory
  final List<EpubChapter> chapters;
  final List<EpubChapter> tableOfContents;
  final String unzippedPath; // Path to the temporary unzipped directory

  EpubBook({
    required this.title,
    required this.author,
    required this.coverImagePath,
    required this.chapters,
    required this.tableOfContents,
    required this.unzippedPath,
  });
}

class EpubChapter {
  final String title;
  final String contentFilePath; // Path relative to the unzipped directory

  EpubChapter({
    required this.title,
    required this.contentFilePath,
  });
}


