import 'epub_content_file_ref.dart';

class EpubTextContentFileRef extends EpubContentFileRef {
  EpubTextContentFileRef(super.epubArchive, super.schema,
      {required super.ContentMimeType, required super.ContentType, required super.FileName});

  String ReadContentAsync() {
    return readContentAsText();
  }
}
