import 'package:archive/archive_io.dart';
import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import '../entities/epub_schema.dart';
import '../readers/book_cover_reader.dart';
import '../readers/chapter_reader.dart';
import '../schema/navigation/epub_navigation_map.dart';
import '../schema/opf/epub_manifest.dart';
import '../schema/opf/epub_metadata.dart';
import '../schema/opf/epub_metadata_title.dart';
import '../schema/opf/epub_spine.dart';
import 'epub_byte_content_file_ref.dart';
import 'epub_chapter_ref.dart';
import 'epub_content_ref.dart';
import 'epub_text_content_file_ref.dart';

class EpubBookRef {
  final Archive epubArchive;

  /// Main title.
  EpubMetadataTitle Title;
  String Author;
  List<String> AuthorList;
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

  String get title => Title.Title;
  EpubMetadata get metadata => Schema.Package.Metadata;
  EpubManifest get manifest => Schema.Package.Manifest;
  EpubSpine get spine => Schema.Package.Spine;
  EpubNavigationMap? get navMap => Schema.Navigation.NavMap;
  Map<String, EpubTextContentFileRef> get html => Content.Html;
  Map<String, EpubByteContentFileRef> get images => Content.Images;
  Map<String, EpubTextContentFileRef> get css => Content.Css;
  Map<String, EpubByteContentFileRef> get fonts => Content.Fonts;

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

  void extractEpub(String path) {
    extractArchiveToDisk(epubArchive, path);
  }

  List<EpubChapterRef> get chapters => ChapterReader.getChapters(this);

  EpubByteContentFileRef? get cover => BookCoverReader.readBookCover(this);
}
