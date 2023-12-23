import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:epubx/src/schema/opf/epub_version.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path/path.dart' as path;

import '../schema/navigation/epub_metadata.dart';
import '../schema/navigation/epub_navigation.dart';
import '../schema/navigation/epub_navigation_doc_author.dart';
import '../schema/navigation/epub_navigation_doc_title.dart';
import '../schema/navigation/epub_navigation_head.dart';
import '../schema/navigation/epub_navigation_head_meta.dart';
import '../schema/navigation/epub_navigation_label.dart';
import '../schema/navigation/epub_navigation_list.dart';
import '../schema/navigation/epub_navigation_map.dart';
import '../schema/navigation/epub_navigation_page_list.dart';
import '../schema/navigation/epub_navigation_page_target.dart';
import '../schema/navigation/epub_navigation_page_target_type.dart';
import '../schema/navigation/epub_navigation_point.dart';
import '../schema/navigation/epub_navigation_target.dart';
import '../schema/opf/epub_manifest_item.dart';
import '../schema/opf/epub_package.dart';
import '../utils/enum_from_string.dart';
import '../utils/zip_path_utils.dart';

class NavigationReader {
  static String _tocFileEntryPath = '/';

  static EpubNavigation readNavigation(Archive epubArchive, String contentDirectoryPath, EpubPackage package) {
    var result = EpubNavigation();
    if (package.Version == EpubVersion.Epub2) {
      var tocId = package.Spine.TableOfContents;
      if (tocId == null || tocId.isEmpty) {
        throw Exception('EPUB parsing error: TOC ID is empty.');
      }
      var tocManifestItem = package.Manifest.Items.firstWhereOrNull(
        (EpubManifestItem? item) => item!.Id.toLowerCase() == tocId.toLowerCase(),
      );
      if (tocManifestItem == null) {
        throw Exception('EPUB parsing error: TOC item $tocId not found in EPUB manifest.');
      }

      _tocFileEntryPath = ZipPathUtils.combine(contentDirectoryPath, tocManifestItem.Href);
      var tocFileEntry = epubArchive.findFile(_tocFileEntryPath);
      if (tocFileEntry == null) {
        throw Exception('EPUB parsing error: TOC file $_tocFileEntryPath not found in archive.');
      }

      var containerDocument = xml.XmlDocument.parse(convert.utf8.decode(tocFileEntry.content));

      var ncxNamespace = 'http://www.daisy.org/z3986/2005/ncx/';
      var ncxNode = containerDocument.getElement('ncx', namespace: ncxNamespace);

      if (ncxNode == null) {
        throw Exception('EPUB parsing error: TOC file does not contain ncx element.');
      }

      var headNode = ncxNode.getElement('head', namespace: ncxNamespace);
      if (headNode == null) {
        throw Exception('EPUB parsing error: TOC file does not contain head element.');
      }

      var navigationHead = readNavigationHead(headNode);
      result.Head = navigationHead;
      var docTitleNode = ncxNode.getElement('docTitle', namespace: ncxNamespace);

      if (docTitleNode == null) {
        throw Exception('EPUB parsing error: TOC file does not contain docTitle element.');
      }

      var navigationDocTitle = readNavigationDocTitle(docTitleNode);
      result.DocTitle = navigationDocTitle;
      result.DocAuthors = <EpubNavigationDocAuthor>[];
      for (var docAuthorNode in ncxNode.findElements('docAuthor', namespace: ncxNamespace)) {
        var navigationDocAuthor = readNavigationDocAuthor(docAuthorNode);
        result.DocAuthors!.add(navigationDocAuthor);
      }

      var navMapNode = ncxNode.getElement('navMap', namespace: ncxNamespace);

      if (navMapNode == null) {
        throw Exception('EPUB parsing error: TOC file does not contain navMap element.');
      }

      var navMap = readNavigationMap(navMapNode);
      result.NavMap = navMap;
      var pageListNode = ncxNode.getElement('pageList', namespace: ncxNamespace);

      if (pageListNode != null) {
        var pageList = readNavigationPageList(pageListNode);
        result.PageList = pageList;
      }

      result.NavLists = <EpubNavigationList>[];
      for (var navigationListNode in ncxNode.findElements('navList', namespace: ncxNamespace)) {
        var navigationList = readNavigationList(navigationListNode);
        result.NavLists!.add(navigationList);
      }
    } else {
      //Version 3
      var tocManifestItem = package.Manifest.Items.firstWhereOrNull((element) => element.Properties == 'nav');
      if (tocManifestItem == null) {
        throw Exception('EPUB parsing error: TOC item not found in EPUB manifest.');
      }
      _tocFileEntryPath = ZipPathUtils.combine(contentDirectoryPath, tocManifestItem.Href);
      var tocFileEntry = epubArchive.findFile(_tocFileEntryPath);
      if (tocFileEntry == null) {
        throw Exception('EPUB parsing error: TOC file $_tocFileEntryPath not found in archive.');
      }
      //Get relative toc file path
      _tocFileEntryPath = '${((_tocFileEntryPath.split('/')..removeLast())).skip(1).join('/')}/';

      var containerDocument = xml.XmlDocument.parse(convert.utf8.decode(tocFileEntry.content));
      var headNode = containerDocument.findAllElements('head').firstOrNull;

      if (headNode == null) {
        throw Exception('EPUB parsing error: TOC file does not contain head element.');
      }

      result.DocTitle = EpubNavigationDocTitle();
      // Again same as List.generate(). I dislike map()
      result.DocTitle!.Titles = [
        for (var titleElement in package.Metadata.Titles) titleElement.Title,
      ];
      result.DocAuthors = <EpubNavigationDocAuthor>[];

      var navNode = containerDocument.findAllElements('nav').firstOrNull;

      if (navNode == null) {
        throw Exception('EPUB parsing error: TOC file does not contain head element.');
      }
      var navMapNode = navNode.getElement('ol');

      if (navMapNode == null) {
        throw Exception('EPUB parsing error: Nav does not contain ol element');
      }

      var navMap = readNavigationMapV3(navMapNode);
      result.NavMap = navMap;

      //TODO : Implement pagesLists
//      xml.XmlElement pageListNode = ncxNode
//          .findElements("pageList", namespace: ncxNamespace)
//          .firstWhere((xml.XmlElement elem) => elem != null,
//          orElse: () => null);
//      if (pageListNode != null) {
//        EpubNavigationPageList pageList = readNavigationPageList(pageListNode);
//        result.PageList = pageList;
//      }
    }

    return result;
  }

  static EpubNavigationContent readNavigationContent(xml.XmlElement navigationContentNode) {
    var result = EpubNavigationContent();
    for (var navigationContentNodeAttribute in navigationContentNode.attributes) {
      var attributeValue = navigationContentNodeAttribute.value;
      switch (navigationContentNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
        case 'href':
          result.Source = path.normalize("$_tocFileEntryPath/$attributeValue");
        // if (_tocFileEntryPath.length < 2 || attributeValue.contains(_tocFileEntryPath)) {
        //   result.Source = attributeValue.replaceFirst('../', '');
        // } else {
        //   result.Source = path.normalize(_tocFileEntryPath + attributeValue);
        // }
        case 'src':
          result.Source = attributeValue;
      }
    }
    // element with span, the content will be null;
    // if (result.Source == null || result.Source!.isEmpty) {
    //   throw Exception('Incorrect EPUB navigation content: content source is missing.');
    // }
    return result;
  }

  static EpubNavigationDocAuthor readNavigationDocAuthor(xml.XmlElement docAuthorNode) {
    var result = EpubNavigationDocAuthor();
    result.Authors = <String>[];
    for (var textNode in docAuthorNode.childElements) {
      if (textNode.name.local.toLowerCase() == 'text') {
        result.Authors!.add(textNode.innerText);
      }
    }
    return result;
  }

  static EpubNavigationDocTitle readNavigationDocTitle(xml.XmlElement docTitleNode) {
    var result = EpubNavigationDocTitle();
    result.Titles = <String>[];
    docTitleNode.children.whereType<xml.XmlElement>().forEach((xml.XmlElement textNode) {
      if (textNode.name.local.toLowerCase() == 'text') {
        result.Titles!.add(textNode.innerText);
      }
    });
    return result;
  }

  static EpubNavigationHead readNavigationHead(xml.XmlElement headNode) {
    var result = EpubNavigationHead();
    result.Metadata = <EpubNavigationHeadMeta>[];

    for (var metaNode in headNode.childElements) {
      if (metaNode.name.local.toLowerCase() == 'meta') {
        var meta = EpubNavigationHeadMeta();
        for (var metaNodeAttribute in metaNode.attributes) {
          var attributeValue = metaNodeAttribute.value;
          switch (metaNodeAttribute.name.local.toLowerCase()) {
            case 'name':
              meta.Name = attributeValue;
              break;
            case 'content':
              meta.Content = attributeValue;
              break;
            case 'scheme':
              meta.Scheme = attributeValue;
              break;
          }
        }

        if (meta.Name == null || meta.Name!.isEmpty) {
          throw Exception('Incorrect EPUB navigation meta: meta name is missing.');
        }
        if (meta.Content == null) {
          throw Exception('Incorrect EPUB navigation meta: meta content is missing.');
        }

        result.Metadata!.add(meta);
      }
    }
    return result;
  }

  static EpubNavigationLabel readNavigationLabel(xml.XmlElement navigationLabelNode) {
    var result = EpubNavigationLabel();

    var navigationLabelTextNode =
        navigationLabelNode.getElement('text', namespace: navigationLabelNode.name.namespaceUri);

    if (navigationLabelTextNode == null) {
      throw Exception('Incorrect EPUB navigation label: label text element is missing.');
    }

    result.Text = navigationLabelTextNode.innerText;

    return result;
  }

  static EpubNavigationLabel readNavigationLabelV3(xml.XmlElement navigationLabelNode) {
    var result = EpubNavigationLabel();
    result.Text = navigationLabelNode.innerText.trim();
    return result;
  }

  static EpubNavigationList readNavigationList(xml.XmlElement navigationListNode) {
    var result = EpubNavigationList();
    for (var navigationListNodeAttribute in navigationListNode.attributes) {
      var attributeValue = navigationListNodeAttribute.value;
      switch (navigationListNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'class':
          result.Class = attributeValue;
          break;
      }
    }
    for (var navigationListChildNode in navigationListNode.childElements) {
      switch (navigationListChildNode.name.local.toLowerCase()) {
        case 'navlabel':
          var navigationLabel = readNavigationLabel(navigationListChildNode);
          result.NavigationLabels!.add(navigationLabel);
          break;
        case 'navtarget':
          var navigationTarget = readNavigationTarget(navigationListChildNode);
          result.NavigationTargets!.add(navigationTarget);
          break;
      }
    }
    // if (result.NavigationLabels!.isEmpty) {
    //   throw Exception(
    //       'Incorrect EPUB navigation page target: at least one navLabel element is required.');
    // }
    return result;
  }

  static EpubNavigationMap readNavigationMap(xml.XmlElement navigationMapNode) {
    var result = EpubNavigationMap();
    result.Points = <EpubNavigationPoint>[];
    for (var navigationPointNode in navigationMapNode.childElements) {
      if (navigationPointNode.name.local.toLowerCase() == 'navpoint') {
        var navigationPoint = readNavigationPoint(navigationPointNode);
        result.Points!.add(navigationPoint);
      }
    }
    return result;
  }

  static EpubNavigationMap readNavigationMapV3(xml.XmlElement navigationMapNode) {
    var result = EpubNavigationMap();
    result.Points = <EpubNavigationPoint>[];
    for (var navigationPointNode in navigationMapNode.childElements) {
      if (navigationPointNode.name.local.toLowerCase() == 'li') {
        var navigationPoint = readNavigationPointV3(navigationPointNode);
        result.Points!.add(navigationPoint);
      }
    }
    return result;
  }

  static EpubNavigationPageList readNavigationPageList(xml.XmlElement navigationPageListNode) {
    var result = EpubNavigationPageList();
    result.Targets = <EpubNavigationPageTarget>[];
    for (var pageTargetNode in navigationPageListNode.childElements) {
      if (pageTargetNode.name.local == 'pageTarget') {
        var pageTarget = readNavigationPageTarget(pageTargetNode);
        result.Targets!.add(pageTarget);
      }
    }

    return result;
  }

  static EpubNavigationPageTarget readNavigationPageTarget(xml.XmlElement navigationPageTargetNode) {
    var result = EpubNavigationPageTarget();
    result.NavigationLabels = <EpubNavigationLabel>[];
    for (var navigationPageTargetNodeAttribute in navigationPageTargetNode.attributes) {
      var attributeValue = navigationPageTargetNodeAttribute.value;
      switch (navigationPageTargetNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'value':
          result.Value = attributeValue;
          break;
        case 'type':
          var converter = EnumFromString<EpubNavigationPageTargetType>(EpubNavigationPageTargetType.values);
          var type = converter.get(attributeValue);
          result.Type = type;
          break;
        case 'class':
          result.Class = attributeValue;
          break;
        case 'playorder':
          result.PlayOrder = attributeValue;
          break;
      }
    }
    if (result.Type == EpubNavigationPageTargetType.UNDEFINED) {
      throw Exception('Incorrect EPUB navigation page target: page target type is missing.');
    }

    for (var navigationPageTargetChildNode in navigationPageTargetNode.childElements) {
      switch (navigationPageTargetChildNode.name.local.toLowerCase()) {
        case 'navlabel':
          var navigationLabel = readNavigationLabel(navigationPageTargetChildNode);
          result.NavigationLabels!.add(navigationLabel);
          break;
        case 'content':
          var content = readNavigationContent(navigationPageTargetChildNode);
          result.Content = content;
          break;
      }
    }
    if (result.NavigationLabels!.isEmpty) {
      throw Exception('Incorrect EPUB navigation page target: at least one navLabel element is required.');
    }

    return result;
  }

  static EpubNavigationPoint readNavigationPoint(xml.XmlElement navigationPointNode) {
    var result = EpubNavigationPoint();
    for (var navigationPointNodeAttribute in navigationPointNode.attributes) {
      var attributeValue = navigationPointNodeAttribute.value;
      switch (navigationPointNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'class':
          result.Class = attributeValue;
          break;
        case 'playorder':
          result.PlayOrder = attributeValue;
          break;
      }
    }
    if (result.Id == null || result.Id!.isEmpty) {
      throw Exception('Incorrect EPUB navigation point: point ID is missing.');
    }

    for (var navigationPointChildNode in navigationPointNode.childElements) {
      switch (navigationPointChildNode.name.local.toLowerCase()) {
        case 'navlabel':
          var navigationLabel = readNavigationLabel(navigationPointChildNode);
          result.NavigationLabels.add(navigationLabel);
          break;
        case 'content':
          var content = readNavigationContent(navigationPointChildNode);
          result.Content = content;
          break;
        case 'navpoint':
          var childNavigationPoint = readNavigationPoint(navigationPointChildNode);
          result.ChildNavigationPoints.add(childNavigationPoint);
          break;
      }
    }

    if (result.NavigationLabels.isEmpty) {
      throw Exception(
          'EPUB parsing error: navigation point ${result.Id} should contain at least one navigation label.');
    }
    if (result.Content == null) {
      throw Exception('EPUB parsing error: navigation point ${result.Id} should contain content.');
    }

    return result;
  }

  static EpubNavigationPoint readNavigationPointV3(xml.XmlElement navigationPointNode) {
    var result = EpubNavigationPoint();
    for (var navigationPointChildNode in navigationPointNode.descendantElements) {
      switch (navigationPointChildNode.name.local.toLowerCase()) {
        case 'a':
        case 'span':
          var navigationLabel = readNavigationLabelV3(navigationPointChildNode);
          result.NavigationLabels.add(navigationLabel);
          var content = readNavigationContent(navigationPointChildNode);
          result.Content = content;
          break;
        case 'ol':
          for (var point in readNavigationMapV3(navigationPointChildNode).Points!) {
            result.ChildNavigationPoints.add(point);
          }
          break;
      }
    }
    if (result.NavigationLabels.isEmpty) {
      throw Exception(
          'EPUB parsing error: navigation point ${result.Id} should contain at least one navigation label.');
    }
    if (result.Content == null) {
      throw Exception('EPUB parsing error: navigation point ${result.Id} should contain content.');
    }

    return result;
  }

  static EpubNavigationTarget readNavigationTarget(xml.XmlElement navigationTargetNode) {
    var result = EpubNavigationTarget();
    for (var navigationPageTargetNodeAttribute in navigationTargetNode.attributes) {
      var attributeValue = navigationPageTargetNodeAttribute.value;
      switch (navigationPageTargetNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'value':
          result.Value = attributeValue;
          break;
        case 'class':
          result.Class = attributeValue;
          break;
        case 'playorder':
          result.PlayOrder = attributeValue;
          break;
      }
    }
    if (result.Id == null || result.Id!.isEmpty) {
      throw Exception('Incorrect EPUB navigation target: navigation target ID is missing.');
    }
    for (var navigationTargetChildNode in navigationTargetNode.childElements) {
      switch (navigationTargetChildNode.name.local.toLowerCase()) {
        case 'navlabel':
          var navigationLabel = readNavigationLabel(navigationTargetChildNode);
          result.NavigationLabels!.add(navigationLabel);
          break;
        case 'content':
          var content = readNavigationContent(navigationTargetChildNode);
          result.Content = content;
          break;
      }
    }
    if (result.NavigationLabels!.isEmpty) {
      throw Exception('Incorrect EPUB navigation target: at least one navLabel element is required.');
    }

    return result;
  }
}
