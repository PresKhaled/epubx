import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:xml/xml.dart' as xml;

class RootFilePathReader {
  static String? getRootFilePath(Archive epubArchive) {
    const epubContainerFilePath = 'META-INF/container.xml';

    var containerFileEntry = epubArchive.findFile(epubContainerFilePath);
    if (containerFileEntry == null) {
      throw Exception('EPUB parsing error: $epubContainerFilePath file not found in archive.');
    }

    var containerDocument = xml.XmlDocument.parse(convert.utf8.decode(containerFileEntry.content));
    var packageElement =
        containerDocument.getElement('container', namespace: 'urn:oasis:names:tc:opendocument:xmlns:container');

    if (packageElement == null) {
      throw Exception('EPUB parsing error: Invalid epub container');
    }

    var rootFileElement = packageElement.descendants.firstWhereOrNull(
        (xml.XmlNode testElem) => (testElem is xml.XmlElement) && 'rootfile' == testElem.name.local) as xml.XmlElement;

    return rootFileElement.getAttribute('full-path');
  }
}
