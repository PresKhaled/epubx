import 'package:epubx/src/schema/opf/epub_manifest.dart';
import 'package:xml/xml.dart' show XmlBuilder;

class EpubManifestWriter {
  static void writeManifest(XmlBuilder builder, EpubManifest manifest) {
    builder.element('manifest', nest: () {
      for (var item in manifest.Items) {
        builder.element('item', nest: () {
          builder
            ..attribute('id', item.Id)
            ..attribute('href', item.Href)
            ..attribute('media-type', item.MediaType);
        });
      }
    });
  }
}
