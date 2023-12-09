import 'dart:typed_data';

import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_content_file.dart';

class EpubByteContentFile extends EpubContentFile {
  Uint8List? Content;

  EpubByteContentFile({super.FileName, super.ContentMimeType, super.ContentType, this.Content});

  @override
  int get hashCode {
    var objects = [
      ContentMimeType.hashCode,
      ContentType.hashCode,
      FileName.hashCode,
      ...Content?.map((content) => content.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubByteContentFile) {
      return false;
    }
    return collections.listsEqual(Content, other.Content) &&
        ContentMimeType == other.ContentMimeType &&
        ContentType == other.ContentType &&
        FileName == other.FileName;
  }
}
