import 'epub_content_file_ref.dart';

class EpubByteContentFileRef extends EpubContentFileRef {
  EpubByteContentFileRef(super.epubArchive, super.schema,
      {required super.FileName, required super.ContentMimeType, required super.ContentType});

  List<int> readContent() {
    return readContentAsBytes();
  }
}
