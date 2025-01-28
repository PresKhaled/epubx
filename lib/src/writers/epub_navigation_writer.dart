import 'package:epubx/src/schema/navigation/epub_navigation.dart';
import 'package:epubx/src/schema/navigation/epub_navigation_doc_title.dart';
import 'package:epubx/src/schema/navigation/epub_navigation_head.dart';
import 'package:epubx/src/schema/navigation/epub_navigation_map.dart';
import 'package:epubx/src/schema/navigation/epub_navigation_point.dart';
import 'package:xml/xml.dart' show XmlBuilder;

class EpubNavigationWriter {
  static const String _namespace = 'http://www.daisy.org/z3986/2005/ncx/';

  static String writeNavigation(EpubNavigation navigation) {
    var builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');

    builder.element('ncx', attributes: {
      'version': '2005-1',
      'lang': 'en',
    }, nest: () {
      builder.namespace(_namespace);

      writeNavigationHead(builder, navigation.Head!);
      writeNavigationDocTitle(builder, navigation.DocTitle!);
      writeNavigationMap(builder, navigation.NavMap!);
    });

    return builder.buildDocument().toXmlString(pretty: false);
  }

  static void writeNavigationDocTitle(XmlBuilder builder, EpubNavigationDocTitle title) {
    builder.element('docTitle', nest: () {
      for (var element in title.Titles) {
        builder.text(element);
      }
    });
  }

  static void writeNavigationHead(XmlBuilder builder, EpubNavigationHead head) {
    builder.element('head', nest: () {
      for (var item in head.Metadata) {
        builder.element('meta', attributes: {'content': item.Content!, 'name': item.Name!});
      }
    });
  }

  static void writeNavigationMap(XmlBuilder builder, EpubNavigationMap map) {
    builder.element('navMap', nest: () {
      for (var item in map.Points) {
        writeNavigationPoint(builder, item);
      }
    });
  }

  static void writeNavigationPoint(XmlBuilder builder, EpubNavigationPoint point) {
    builder.element('navPoint', attributes: {
      'id': point.Id!,
      'playOrder': point.PlayOrder!,
    }, nest: () {
      for (var element in point.NavigationLabels) {
        builder.element('navLabel', nest: () {
          builder.element('text', nest: () {
            builder.text(element.Text!);
          });
        });
      }
      builder.element('content', attributes: {'src': point.Content!.Source!});
    });
  }
}
