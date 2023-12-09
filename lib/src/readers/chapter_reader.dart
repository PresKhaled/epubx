import 'package:epubx/src/schema/opf/epub_spine_item_ref.dart';

import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_chapter_ref.dart';

class ChapterReader {
  static List<EpubChapterRef> getChapters(EpubBookRef bookRef) {
    return getChaptersImpl(bookRef, bookRef.Schema.Package.Spine.Items);
  }

  static List<EpubChapterRef> getChaptersImpl(EpubBookRef bookRef, List<EpubSpineItemRef> spineRefs) {
    var result = <EpubChapterRef>[];
    for (var spineRef in spineRefs) {
      var contentFileName = spineRef.IdRef;
      if (!bookRef.Content.Html.containsKey(contentFileName)) {
        throw Exception('Incorrect EPUB manifest: item with href = "$contentFileName" is missing.');
      }
      var htmlContentFileRef = bookRef.Content.Html[contentFileName];
      var chapterRef = EpubChapterRef(
        htmlContentFileRef,
        ContentFileName: htmlContentFileRef!.FileName,
      );
      result.add(chapterRef);
    }
    return result;
  }
}


      // String? contentFileName;
      // String? anchor;
      // if (navigationPoint.Content?.Source == null) continue;
      // var contentSourceAnchorCharIndex = navigationPoint.Content!.Source!.indexOf('#');
      // if (contentSourceAnchorCharIndex == -1) {
      //   contentFileName = navigationPoint.Content!.Source;
      //   anchor = null;
      // } else {
      //   contentFileName = navigationPoint.Content!.Source!.substring(0, contentSourceAnchorCharIndex);
      //   anchor = navigationPoint.Content!.Source!.substring(contentSourceAnchorCharIndex + 1);
      // }
      // contentFileName = Uri.decodeFull(contentFileName!);
      // EpubTextContentFileRef? htmlContentFileRef;
      // if (!bookRef.Content.Html.containsKey(contentFileName)) {
      //   throw Exception('Incorrect EPUB manifest: item with href = "$contentFileName" is missing.');
      // }