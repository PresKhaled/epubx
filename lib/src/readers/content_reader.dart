import 'package:archive/archive.dart';
import 'package:epubx/src/entities/epub_schema.dart';

import '../entities/epub_content_type.dart';
import '../ref_entities/epub_byte_content_file_ref.dart';
import '../ref_entities/epub_content_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';

class ContentReader {
  static EpubContentRef parseContentMap(EpubSchema schema, Archive epubArchive) {
    var result = EpubContentRef();

    for (var manifestItem in schema.Package.Manifest.Items) {
      var fileName = manifestItem.Href;
      var fileId = manifestItem.Id;
      var contentMimeType = manifestItem.MediaType;
      var contentType = getContentTypeByContentMimeType(contentMimeType);
      switch (contentType) {
        case EpubContentType.OEB1_DOCUMENT:
        case EpubContentType.OEB1_CSS:
        case EpubContentType.XML:
        case EpubContentType.DTBOOK:
        case EpubContentType.DTBOOK_NCX:
        case EpubContentType.XHTML_1_1:
          var epubTextContentFile = EpubTextContentFileRef(
            epubArchive,
            schema,
            FileName: Uri.decodeFull(fileName),
            ContentMimeType: contentMimeType,
            ContentType: contentType,
          );
          result.Html[fileId] = epubTextContentFile;
          result.AllFiles[fileId] = epubTextContentFile;
        case EpubContentType.CSS:
          var epubTextContentFile = EpubTextContentFileRef(
            epubArchive,
            schema,
            FileName: Uri.decodeFull(fileName),
            ContentMimeType: contentMimeType,
            ContentType: contentType,
          );
          result.Css[fileName] = epubTextContentFile;
          result.AllFiles[fileName] = epubTextContentFile;
        case EpubContentType.IMAGE_GIF:
        case EpubContentType.IMAGE_JPEG:
        case EpubContentType.IMAGE_PNG:
        case EpubContentType.IMAGE_SVG:
        case EpubContentType.IMAGE_BMP:
          var epubByteContentFile = EpubByteContentFileRef(
            epubArchive,
            schema,
            FileName: Uri.decodeFull(fileName),
            ContentType: contentType,
            ContentMimeType: contentMimeType,
          );
          result.Images[fileName] = epubByteContentFile;
          result.AllFiles[fileName] = epubByteContentFile;
        case EpubContentType.FONT_TRUETYPE:
        case EpubContentType.FONT_OPENTYPE:
          var epubByteContentFile = EpubByteContentFileRef(
            epubArchive,
            schema,
            FileName: Uri.decodeFull(fileName),
            ContentType: contentType,
            ContentMimeType: contentMimeType,
          );
          result.Fonts[fileName] = epubByteContentFile;
          result.AllFiles[fileName] = epubByteContentFile;
        default:
          break;
      }
    }
    return result;
  }

  static EpubContentType getContentTypeByContentMimeType(String contentMimeType) {
    switch (contentMimeType.toLowerCase()) {
      case 'application/xhtml+xml':
      case 'text/html':
        return EpubContentType.XHTML_1_1;
      case 'application/x-dtbook+xml':
        return EpubContentType.DTBOOK;
      case 'application/x-dtbncx+xml':
        return EpubContentType.DTBOOK_NCX;
      case 'text/x-oeb1-document':
        return EpubContentType.OEB1_DOCUMENT;
      case 'application/xml':
        return EpubContentType.XML;
      case 'text/css':
        return EpubContentType.CSS;
      case 'text/x-oeb1-css':
        return EpubContentType.OEB1_CSS;
      case 'image/gif':
        return EpubContentType.IMAGE_GIF;
      case 'image/jpeg':
        return EpubContentType.IMAGE_JPEG;
      case 'image/png':
        return EpubContentType.IMAGE_PNG;
      case 'image/svg+xml':
        return EpubContentType.IMAGE_SVG;
      case 'image/bmp':
        return EpubContentType.IMAGE_BMP;
      case 'font/truetype':
        return EpubContentType.FONT_TRUETYPE;
      case 'font/opentype':
        return EpubContentType.FONT_OPENTYPE;
      case 'application/vnd.ms-opentype':
        return EpubContentType.FONT_OPENTYPE;
      default:
        return EpubContentType.OTHER;
    }
  }
}
