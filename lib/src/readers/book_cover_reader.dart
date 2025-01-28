import 'package:collection/collection.dart' show IterableExtension;
import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_byte_content_file_ref.dart';
import '../schema/opf/epub_manifest_item.dart';
import '../schema/opf/epub_metadata_meta.dart';

class BookCoverReader {
  //images.Image
  static EpubByteContentFileRef? readBookCover(EpubBookRef bookRef) {
    var manifest = bookRef.Schema.Package.Manifest;

    // ------------------- Version 3 method ------------------- //
    // - Read cover image in version 3 method.
    if (manifest.Items.isNotEmpty) {
      var coverImageItem = manifest.Items.firstWhereOrNull(
        (EpubManifestItem epubManifestItem) {
          return (epubManifestItem.Properties?.toLowerCase() == 'cover-image');
        },
      );

      if (coverImageItem != null) {
        var epubByteContentFileRef = bookRef.Content.Images[coverImageItem.Href];

        if (epubByteContentFileRef != null) return epubByteContentFileRef;
      }
    }

    // ------------------- Version 2 method ------------------- //
    // - Read cover image in version 2 method.
    var metaItems = bookRef.Schema.Package.Metadata.MetaItems;
    if (metaItems.isEmpty) return null;

    var coverMetaItem = metaItems.firstWhereOrNull(
        (EpubMetadataMeta metaItem) => metaItem.Name != null && metaItem.Name!.toLowerCase() == 'cover');

    if (coverMetaItem == null) return null;

    if ([null, '', ' '].contains(coverMetaItem.Content)) {
      throw Exception('Incorrect EPUB metadata: cover item content is missing.');
    }

    var coverManifestItem = bookRef.Schema.Package.Manifest.Items.firstWhereOrNull(
      (EpubManifestItem manifestItem) =>
          manifestItem.Id.toLowerCase() == coverMetaItem.Content!.toLowerCase() &&
          manifestItem.MediaType.contains('image'),
    );
    if (coverManifestItem == null) {
      throw Exception('Incorrect EPUB manifest: item with ID = "${coverMetaItem.Content}" is missing.');
    }

    if (!bookRef.Content.Images.containsKey(coverManifestItem.Href)) {
      throw Exception('Incorrect EPUB manifest: item with href = "${coverManifestItem.Href}" is missing.');
    }

    return bookRef.Content.Images[coverManifestItem.Href];
  }
}
