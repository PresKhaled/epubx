import 'dart:async';

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
  Archive? _epubArchive;

  /// Main title.
  EpubMetadataTitle? Title;
  String? Author;
  List<String?>? AuthorList;
  EpubSchema? Schema;
  EpubContentRef? Content;
  EpubBookRef(Archive epubArchive) {
    _epubArchive = epubArchive;
  }

  @override
  int get hashCode {
    var objects = [
      Title.hashCode,
      Author.hashCode,
      Schema.hashCode,
      Content.hashCode,
      ...AuthorList?.map((author) => author.hashCode) ?? [0],
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

  Archive? EpubArchive() {
    return _epubArchive;
  }

  Future<List<EpubChapterRef>> getChapters() async {
    return ChapterReader.getChapters(this);
  }

  Future<EpubByteContentFileRef?> readCover() async {
    return await BookCoverReader.readBookCover(this);
  }
}
