import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epubx/src/entities/epub_schema.dart';
import 'package:quiver/core.dart';

import '../entities/epub_content_type.dart';

abstract class EpubContentFileRef {
  final Archive epubArchive;
  final EpubSchema schema;
  final String FileName;
  final EpubContentType ContentType;
  final String ContentMimeType;

  EpubContentFileRef(this.epubArchive, this.schema,
      {required this.FileName, required this.ContentType, required this.ContentMimeType});

  @override
  int get hashCode => hash3(FileName.hashCode, ContentMimeType.hashCode, ContentType.hashCode);

  @override
  bool operator ==(other) {
    if (other is! EpubContentFileRef) {
      return false;
    }

    return (other.FileName == FileName && other.ContentMimeType == ContentMimeType && other.ContentType == ContentType);
  }

  ArchiveFile getContentFileEntry() {
    var contentFileEntry = epubArchive.findFile('${schema.ContentDirectoryPath}$FileName');
    if (contentFileEntry == null) {
      //return ArchiveFile("stub", 0, '');
      throw Exception('EPUB parsing error: file $FileName not found in archive.');
    }
    return contentFileEntry;
  }

  List<int> getContentStream() {
    return openContentStream(getContentFileEntry());
  }

  Uint8List openContentStream(ArchiveFile contentFileEntry) {
    if (contentFileEntry.content == null) {
      throw Exception('Incorrect EPUB file: content file "$FileName" specified in manifest is not found.');
    }
    return Uint8List.fromList(contentFileEntry.content);
  }

  Uint8List readContentAsBytes() {
    var contentFileEntry = getContentFileEntry();
    var content = openContentStream(contentFileEntry);
    return content;
  }

  String readContentAsText() {
    var contentStream = getContentStream();
    var result = convert.utf8.decode(contentStream);
    return result;
  }
}
