import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import '../../epubx.dart' show EpubMetadataTitle;
import '../ref_entities/epub_byte_content_file_ref.dart';
import 'epub_chapter.dart';
import 'epub_content.dart';
import 'epub_schema.dart';

class EpubBook {
  late EpubMetadataTitle MainTitle;
  String? Author;
  List<String?>? AuthorList;
  EpubSchema? Schema;
  EpubContent? Content;
  EpubByteContentFileRef? CoverImage;
  List<EpubChapter>? Chapters;

  @override
  int get hashCode {
    var objects = [
      MainTitle.hashCode,
      Author.hashCode,
      Schema.hashCode,
      Content.hashCode,
      ...CoverImage?.getContentStream().map((byte) => byte.hashCode) ?? [0],
      ...AuthorList?.map((author) => author.hashCode) ?? [0],
      ...Chapters?.map((chapter) => chapter.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubBook) {
      return false;
    }

    return MainTitle == other.MainTitle &&
        Author == other.Author &&
        collections.listsEqual(AuthorList, other.AuthorList) &&
        Schema == other.Schema &&
        Content == other.Content &&
        collections.listsEqual(CoverImage!.getContentStream(),
            other.CoverImage!.getContentStream()) &&
        collections.listsEqual(Chapters, other.Chapters);
  }
}
