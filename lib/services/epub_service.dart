import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../models/epub_book.dart';

class EpubService {
  /// Loads an EPUB file, unzips it, parses its contents, and returns an [EpubBook].
  ///
  /// This is a complex operation that should be run asynchronously.
  Future<EpubBook> openEpub(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Unzip the EPUB file to a temporary directory
    final tempDir = await getTemporaryDirectory();
    final unzippedPath = p.join(tempDir.path, 'epub_${DateTime.now().millisecondsSinceEpoch}');
    await Directory(unzippedPath).create(recursive: true);

    for (final file in archive) {
      final filename = p.join(unzippedPath, file.name);
      if (file.isFile) {
        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filename).create(recursive: true);
      }
    }

    // 2. Find and parse container.xml to get the OPF file path
    final containerFile = File(p.join(unzippedPath, 'META-INF', 'container.xml'));
    final containerDoc = XmlDocument.parse(await containerFile.readAsString());
    final opfPath = containerDoc.findAllElements('rootfile').first.getAttribute('full-path');

    if (opfPath == null) {
      throw Exception('Could not find OPF file path in container.xml');
    }

    // 3. Parse the OPF file (.opf)
    final opfFile = File(p.join(unzippedPath, opfPath));
    final opfDoc = XmlDocument.parse(await opfFile.readAsString());
    final opfDir = p.dirname(opfPath);

    // 3a. Extract metadata (title, author)
    final metadata = opfDoc.findAllElements('metadata').first;
    final title = metadata.findAllElements('dc:title').first.innerText;
    final author = metadata.findAllElements('dc:creator').first.innerText;

    // 3b. Extract manifest (map of all files in the book)
    final manifest = opfDoc.findAllElements('manifest').first;
    final manifestItems = {
      for (var item in manifest.findAllElements('item'))
        item.getAttribute('id')!: item.getAttribute('href')!
    };

    // 3c. Extract spine (the linear reading order)
    final spine = opfDoc.findAllElements('spine').first;
    final spineItems = spine.findAllElements('itemref').map((item) => item.getAttribute('idref')!).toList();

    final chapters = spineItems.map((idref) {
      final href = manifestItems[idref]!;
      // For simplicity, we use the href as the title. A real implementation would parse the HTML title.
      return EpubChapter(title: href, contentFilePath: p.join(unzippedPath, opfDir, href));
    }).toList();

    // 4. Find and parse the NCX file for the Table of Contents
    final ncxId = spine.getAttribute('toc');
    final ncxPath = ncxId != null ? manifestItems[ncxId] : null;
    List<EpubChapter> toc = [];
    if (ncxPath != null) {
      final ncxFile = File(p.join(unzippedPath, opfDir, ncxPath));
      final ncxDoc = XmlDocument.parse(await ncxFile.readAsString());
      toc = ncxDoc.findAllElements('navPoint').map((point) {
        final label = point.findAllElements('text').first.innerText;
        final src = point.findAllElements('content').first.getAttribute('src')!;
        return EpubChapter(title: label, contentFilePath: p.join(unzippedPath, opfDir, src));
      }).toList();
    }

    // 5. Find cover image (optional, but good for UI)
    String coverImagePath = '';
    final coverMeta = metadata.findAllElements('meta').where((e) => e.getAttribute('name') == 'cover');
    if (coverMeta.isNotEmpty) {
      final coverId = coverMeta.first.getAttribute('content');
      if (coverId != null && manifestItems.containsKey(coverId)) {
        coverImagePath = p.join(unzippedPath, opfDir, manifestItems[coverId]!);
      }
    }

    return EpubBook(
      title: title,
      author: author,
      coverImagePath: coverImagePath,
      chapters: chapters,
      tableOfContents: toc.isNotEmpty ? toc : chapters, // Fallback to spine if no TOC
      unzippedPath: unzippedPath,
    );
  }
}

