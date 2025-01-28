import 'package:quiver/core.dart';

import 'epub_text_content_file_ref.dart';

class EpubChapterRef {
  EpubTextContentFileRef? epubTextContentFileRef;
  String ContentFileName;

  EpubChapterRef(
    this.epubTextContentFileRef, {
    required this.ContentFileName,
  });

  @override
  int get hashCode {
    var objects = [
      ContentFileName.hashCode,
      epubTextContentFileRef.hashCode,
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubChapterRef) {
      return false;
    }
    return ContentFileName == other.ContentFileName && epubTextContentFileRef == other.epubTextContentFileRef;
  }

  String readHtmlContent() {
    return epubTextContentFileRef!.readContentAsText();
  }

  // @override
  // String toString() {
  //   return 'Title: $Title, Subchapter count: ${SubChapters.length}';
  // }
}
