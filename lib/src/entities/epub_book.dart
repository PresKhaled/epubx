import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import '../../epubx.dart' show EpubMetadataTitle;
import '../ref_entities/epub_byte_content_file_ref.dart';
import '../schema/navigation/epub_navigation_map.dart';
import '../schema/opf/epub_manifest.dart';
import '../schema/opf/epub_metadata.dart';
import '../schema/opf/epub_spine.dart';
import 'epub_byte_content_file.dart';
import 'epub_chapter.dart';
import 'epub_content.dart';
import 'epub_schema.dart';
import 'epub_text_content_file.dart';

class EpubBook {
  final EpubMetadataTitle MainTitle;
  String? Author;
  List<String> AuthorList;
  final EpubSchema Schema;
  final EpubContent Content;
  EpubByteContentFileRef? CoverImage;
  List<EpubChapter> Chapters;

  EpubBook({
    required this.Schema,
    required this.MainTitle,
    required this.Content,
    required this.AuthorList,
    this.Author,
    this.CoverImage,
    required this.Chapters,
  });

  String get title => MainTitle.Title;
  EpubMetadata get metadata => Schema.Package.Metadata;
  EpubManifest get manifest => Schema.Package.Manifest;
  EpubSpine get spine => Schema.Package.Spine;
  EpubNavigationMap? get navMap => Schema.Navigation.NavMap;
  Map<String, EpubTextContentFile> get html => Content.Html;
  Map<String, EpubByteContentFile> get images => Content.Images;
  Map<String, EpubTextContentFile> get css => Content.Css;
  Map<String, EpubByteContentFile> get fonts => Content.Fonts;

  @override
  int get hashCode {
    var objects = [
      MainTitle.hashCode,
      Author.hashCode,
      Schema.hashCode,
      Content.hashCode,
      ...CoverImage?.getContentStream().map((byte) => byte.hashCode) ?? [0],
      ...AuthorList.map((author) => author.hashCode),
      ...Chapters.map((chapter) => chapter.hashCode),
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
        collections.listsEqual(CoverImage!.getContentStream(), other.CoverImage!.getContentStream()) &&
        collections.listsEqual(Chapters, other.Chapters);
  }
}
