import 'dart:async';

import 'package:archive/archive.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_chapter.dart';
import 'entities/epub_content.dart';
import 'entities/epub_text_content_file.dart';
import 'readers/content_reader.dart';
import 'readers/schema_reader.dart';
import 'ref_entities/epub_book_ref.dart';
import 'ref_entities/epub_byte_content_file_ref.dart';
import 'ref_entities/epub_chapter_ref.dart';
import 'ref_entities/epub_content_file_ref.dart';
import 'ref_entities/epub_content_ref.dart';
import 'ref_entities/epub_text_content_file_ref.dart';

/// A class that provides the primary interface to read Epub files.
///
/// To open an Epub and load all data at once use the [readBook()] method.
///
/// To open an Epub and load only basic metadata use the [openBook()] method.
/// This is a good option to quickly load text-based metadata, while leaving the
/// heavier lifting of loading images and main content for subsequent operations.
///
/// ## Example
/// ```dart
/// // Read the basic metadata.
/// EpubBookRef epub = await EpubReader.openBook(epubFileBytes);
/// // Extract values of interest.
/// String title = epub.Title;
/// String author = epub.Author;
/// var metadata = epub.Schema.Package.Metadata;
/// String genres = metadata.Subjects.join(', ');
/// ```
class EpubReader {
  /// Loads basics metadata.
  ///
  /// Opens the book asynchronously without reading its main content.
  /// Holds the handle to the EPUB file.
  ///
  /// Argument [bytes] should be the bytes of
  /// the epub file you have loaded with something like the [dart:io] package's
  /// [readAsBytes()].
  ///
  /// This is a fast and convenient way to get the most important information
  /// about the book, notably the [Title], [Author] and [AuthorList].
  /// Additional information is loaded in the [Schema] property such as the
  /// Epub version, Publishers, Languages and more.
  static Future<EpubBookRef> openBook(FutureOr<List<int>> bytes) async {
    List<int> loadedBytes;
    if (bytes is Future) {
      loadedBytes = await bytes;
    } else {
      loadedBytes = bytes;
    }

    var epubArchive = ZipDecoder().decodeBytes(loadedBytes);
    var schema = SchemaReader.readSchema(epubArchive);

    // could also use List.generate but this feels better
    var authorList = [for (var creator in schema.Package.Metadata.Creators) creator.Creator!];

    ContentReader.parseContentMap(schema, epubArchive);
    return EpubBookRef(
      epubArchive,
      Schema: schema,
      Title: schema.Package.Metadata.Titles.first,
      AuthorList: authorList,
      Author: authorList.join(', '),
      Content: ContentReader.parseContentMap(schema, epubArchive),
    );
  }

  /// Opens the book asynchronously and reads all of its content into the memory. Does not hold the handle to the EPUB file.
  static Future<EpubBook> readBook(FutureOr<List<int>> bytes) async {
    final List<int> loadedBytes = (bytes is Future) ? await bytes : bytes;

    var epubBookRef = await openBook(loadedBytes);

    return EpubBook(
      Schema: epubBookRef.Schema,
      MainTitle: epubBookRef.Title,
      Content: readContent(epubBookRef.Content),
      AuthorList: epubBookRef.AuthorList,
      Author: epubBookRef.Author,
      CoverImage: epubBookRef.cover,
      Chapters: readChapters(epubBookRef.chapters),
    );
  }

  static EpubContent readContent(EpubContentRef contentRef) {
    var result = EpubContent(
      Html: readTextContentFiles(contentRef.Html),
      Css: readTextContentFiles(contentRef.Css),
      Images: readByteContentFiles(contentRef.Images),
      Fonts: readByteContentFiles(contentRef.Fonts),
    );
    result.AllFiles = {...result.Html, ...result.Css, ...result.Images, ...result.Fonts};

    for (final key in contentRef.AllFiles.keys) {
      if (!result.AllFiles.containsKey(key)) {
        print('why');
        result.AllFiles[key] = readByteContentFile(contentRef.AllFiles[key]!);
      }
    }

    return result;
  }

  static Map<String, EpubTextContentFile> readTextContentFiles(
      Map<String, EpubTextContentFileRef> textContentFileRefs) {
    var result = <String, EpubTextContentFile>{};

    for (final key in textContentFileRefs.keys) {
      EpubContentFileRef value = textContentFileRefs[key]!;
      var textContentFile = EpubTextContentFile();
      textContentFile.FileName = value.FileName;
      textContentFile.ContentType = value.ContentType;
      textContentFile.ContentMimeType = value.ContentMimeType;
      textContentFile.Content = value.readContentAsText();
      result[key] = textContentFile;
    }
    return result;
  }

  static Map<String, EpubByteContentFile> readByteContentFiles(
      Map<String, EpubByteContentFileRef> byteContentFileRefs) {
    var result = <String, EpubByteContentFile>{};
    for (final key in byteContentFileRefs.keys) {
      result[key] = readByteContentFile(byteContentFileRefs[key]!);
    }
    return result;
  }

  static EpubByteContentFile readByteContentFile(EpubContentFileRef contentFileRef) {
    return EpubByteContentFile(
      FileName: contentFileRef.FileName,
      ContentType: contentFileRef.ContentType,
      ContentMimeType: contentFileRef.ContentMimeType,
      Content: contentFileRef.readContentAsBytes(),
    );
  }

  static List<EpubChapter> readChapters(List<EpubChapterRef> chapterRefs) {
    final result = <EpubChapter>[];
    for (final chapterRef in chapterRefs) {
      var chapter = EpubChapter(
        ContentFileName: chapterRef.ContentFileName,
        HtmlContent: chapterRef.readHtmlContent(),
      );
      result.add(chapter);
    }
    return result;
  }
}
