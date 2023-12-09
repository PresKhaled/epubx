import 'package:archive/archive.dart';
import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import '../entities/epub_schema.dart';
import '../readers/book_cover_reader.dart';
import '../readers/chapter_reader.dart';
import '../schema/opf/epub_metadata_title.dart';
import 'epub_byte_content_file_ref.dart';
import 'epub_chapter_ref.dart';
import 'epub_content_ref.dart';

class EpubBookRef {
  final Archive epubArchive;

  /// Main title.
  EpubMetadataTitle Title;
  String Author;
  List<String?> AuthorList;
  EpubSchema Schema;
  EpubContentRef Content;
  EpubBookRef(
    this.epubArchive, {
    required this.Schema,
    required this.Title,
    required this.AuthorList,
    required this.Author,
    required this.Content,
  });

  @override
  int get hashCode {
    var objects = [
      Title.hashCode,
      Author.hashCode,
      Schema.hashCode,
      Content.hashCode,
      ...AuthorList.map((author) => author.hashCode),
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubBookRef) {
      return false;
    }

    return Title == other.Title &&
        Author == other.Author &&
        Schema == other.Schema &&
        Content == other.Content &&
        collections.listsEqual(AuthorList, other.AuthorList);
  }

  List<EpubChapterRef> getChapters() {
    return ChapterReader.getChapters(this);
  }

  EpubByteContentFileRef? readCover() {
    return BookCoverReader.readBookCover(this);
  }
}
