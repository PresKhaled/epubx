import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:xml/xml.dart';

import '../schema/opf/epub_guide.dart';
import '../schema/opf/epub_guide_reference.dart';
import '../schema/opf/epub_language_related_attributes.dart';
import '../schema/opf/epub_manifest.dart';
import '../schema/opf/epub_manifest_item.dart';
import '../schema/opf/epub_metadata.dart';
import '../schema/opf/epub_metadata_contributor.dart';
import '../schema/opf/epub_metadata_creator.dart';
import '../schema/opf/epub_metadata_creator_alternate_script.dart';
import '../schema/opf/epub_metadata_date.dart';
import '../schema/opf/epub_metadata_description.dart';
import '../schema/opf/epub_metadata_identifier.dart';
import '../schema/opf/epub_metadata_meta.dart';
import '../schema/opf/epub_metadata_publisher.dart';
import '../schema/opf/epub_metadata_right.dart';
import '../schema/opf/epub_metadata_title.dart';
import '../schema/opf/epub_package.dart';
import '../schema/opf/epub_spine.dart';
import '../schema/opf/epub_spine_item_ref.dart';
import '../schema/opf/epub_version.dart';

class PackageReader {
  static EpubGuide readGuide(XmlElement guideNode) {
    var result = EpubGuide();
    result.Items = <EpubGuideReference>[];
    guideNode.children.whereType<XmlElement>().forEach((XmlElement guideReferenceNode) {
      if (guideReferenceNode.name.local.toLowerCase() == 'reference') {
        var guideReference = EpubGuideReference();
        for (var guideReferenceNodeAttribute in guideReferenceNode.attributes) {
          var attributeValue = guideReferenceNodeAttribute.value;
          switch (guideReferenceNodeAttribute.name.local.toLowerCase()) {
            case 'type':
              guideReference.Type = attributeValue;
              break;
            case 'title':
              guideReference.Title = attributeValue;
              break;
            case 'href':
              guideReference.Href = attributeValue;
              break;
          }
        }
        if (guideReference.Type == null || guideReference.Type!.isEmpty) {
          throw Exception('Incorrect EPUB guide: item type is missing');
        }
        if (guideReference.Href == null || guideReference.Href!.isEmpty) {
          throw Exception('Incorrect EPUB guide: item href is missing');
        }
        result.Items!.add(guideReference);
      }
    });
    return result;
  }

  static EpubManifest readManifest(XmlElement manifestNode) {
    var result = EpubManifest();
    for (final manifestItemNode in manifestNode.children.whereType<XmlElement>()) {
      late String id, href, mediaType;
      String? mediaOverlay, requiredNamespace, requiredModules, fallback, fallbackStyle, properties;
      for (var manifestItemNodeAttribute in manifestItemNode.attributes) {
        var attributeValue = manifestItemNodeAttribute.value;
        switch (manifestItemNodeAttribute.name.local.toLowerCase()) {
          case 'id':
            id = attributeValue;
          case 'href':
            href = attributeValue;
          case 'media-type':
            mediaType = attributeValue;
          case 'media-overlay':
            mediaOverlay = attributeValue;
          case 'required-namespace':
            requiredNamespace = attributeValue;
          case 'required-modules':
            requiredModules = attributeValue;
          case 'fallback':
            fallback = attributeValue;
          case 'fallback-style':
            fallbackStyle = attributeValue;
          case 'properties':
            properties = attributeValue;
        }
      }
      var manifestItem = EpubManifestItem(
        Id: id,
        Href: href,
        MediaType: mediaType,
        MediaOverlay: mediaOverlay,
        RequiredNamespace: requiredNamespace,
        RequiredModules: requiredModules,
        Fallback: fallback,
        FallbackStyle: fallbackStyle,
        Properties: properties,
      );
      if (manifestItem.Id.isEmpty) {
        throw Exception('Incorrect EPUB manifest: item ID is missing');
      }
      if (manifestItem.Href.isEmpty) {
        throw Exception('Incorrect EPUB manifest: item href is missing');
      }
      if (manifestItem.MediaType.isEmpty) {
        throw Exception('Incorrect EPUB manifest: item media type is missing');
      }
      result.Items.add(manifestItem);
    }
    return result;
  }

  static EpubMetadata readMetadata(XmlElement metadataNode, EpubVersion? epubVersion) {
    var result = EpubMetadata();

    for (var metadataMetaNode in metadataNode.findAllElements('meta')) {
      result.MetaItems.add(readMetadataMeta(metadataMetaNode));
    }

    for (var metadataItemNode in metadataNode.childElements) {
      var innerText = metadataItemNode.innerText;
      switch (metadataItemNode.name.local.toLowerCase()) {
        case 'title':
          result.Titles.add(
            EpubMetadataTitle(
              Id: metadataItemNode.getAttribute('id'),
              Title: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                Lang: metadataItemNode.getAttribute('lang'),
                Dir: metadataItemNode.getAttribute('dir'),
              ),
            ),
          );
          break;
        case 'creator':
        case 'contributor':
          final String tagName = metadataItemNode.name.local.toLowerCase();
          dynamic creatorOrContributor;

          if (tagName == 'creator') {
            creatorOrContributor = readMetadataCreator(metadataItemNode);
          } else {
            creatorOrContributor = readMetadataContributor(metadataItemNode);
          }

          if (epubVersion == EpubVersion.Epub3) {
            final List<EpubMetadataMeta> associatedMetaItems = [
              for (var meta in result.MetaItems)
                if (creatorOrContributor.Id != null && meta.Refines == '#${creatorOrContributor.Id}') meta,
            ];

            creatorOrContributor.Role = associatedMetaItems
                .firstWhereOrNull(
                  (EpubMetadataMeta meta) => (meta.Property == 'role'),
                )
                ?.TextContent;

            creatorOrContributor.FileAs = associatedMetaItems
                .firstWhereOrNull(
                  (EpubMetadataMeta meta) => (meta.Property == 'file-as'),
                )
                ?.TextContent;

            creatorOrContributor.AlternateScripts = (associatedMetaItems
                .where(
              (EpubMetadataMeta meta) => (meta.Property == 'alternate-script'),
            )
                .map(
              (EpubMetadataMeta meta) {
                final EpubLanguageRelatedAttributes languageRelatedAttributes = EpubLanguageRelatedAttributes()
                  ..Lang = meta.Attributes?['lang']
                  ..Dir = meta.Attributes?['dir'];
                final EpubMetadataCreatorAlternateScript alternateScript = EpubMetadataCreatorAlternateScript()
                  ..name = meta.TextContent // Name in another language.
                  ..LanguageRelatedAttributes = languageRelatedAttributes;

                return alternateScript;
              },
            ).toList());

            creatorOrContributor.DisplaySeq = int.tryParse(associatedMetaItems
                    .firstWhereOrNull(
                      (EpubMetadataMeta meta) => (meta.Property == 'display-seq'),
                    )
                    ?.TextContent ??
                '');
          }

          if (tagName == 'creator') {
            result.Creators.add(creatorOrContributor);
          } else {
            result.Contributors.add(creatorOrContributor);
          }
          break;
        case 'subject':
          result.Subjects.add(innerText);
          break;
        case 'description':
          result.Descriptions.add(
            EpubMetadataDescription(
              Id: metadataItemNode.getAttribute('id'),
              Description: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                Lang: metadataItemNode.getAttribute('lang'),
                Dir: metadataItemNode.getAttribute('dir'),
              ),
            ),
          );
          break;
        case 'publisher':
          result.Publishers.add(
            EpubMetadataPublisher(
              Id: metadataItemNode.getAttribute('id'),
              Publisher: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                Lang: metadataItemNode.getAttribute('lang'),
                Dir: metadataItemNode.getAttribute('dir'),
              ),
            ),
          );
          break;

        case 'date':
          var date = readMetadataDate(metadataItemNode);
          result.Dates.add(date);
          break;
        case 'type':
          result.Types.add(innerText);
          break;
        case 'format':
          result.Formats.add(innerText);
          break;
        case 'identifier':
          var identifier = readMetadataIdentifier(metadataItemNode);
          result.Identifiers.add(identifier);
          break;
        case 'source':
          result.Sources.add(innerText);
          break;
        case 'language':
          result.Languages.add(innerText);
          break;
        case 'relation':
          result.Relations.add(innerText);
          break;
        case 'coverage':
          result.Coverages.add(innerText);
          break;
        case 'rights':
          result.Rights.add(
            EpubMetadataRight(
              Id: metadataItemNode.getAttribute('id'),
              Right: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                Lang: metadataItemNode.getAttribute('lang'),
                Dir: metadataItemNode.getAttribute('dir'),
              ),
            ),
          );
          break;
        /*case 'meta':
          if (epubVersion == EpubVersion.Epub2) {
            var meta = readMetadataMetaVersion2(metadataItemNode);
            result.MetaItems!.add(meta);
          } else if (epubVersion == EpubVersion.Epub3) {
            var meta = readMetadataMetaVersion3(metadataItemNode);
            result.MetaItems!.add(meta);
          }
          break;*/
      }
    }
    return result;
  }

  static EpubMetadataContributor readMetadataContributor(XmlElement metadataContributorNode) {
    final languageRelatedAttributes = EpubLanguageRelatedAttributes();
    var result = EpubMetadataContributor();
    for (var metadataContributorNodeAttribute in metadataContributorNode.attributes) {
      var attributeValue = metadataContributorNodeAttribute.value;
      switch (metadataContributorNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'lang':
          languageRelatedAttributes.Lang = attributeValue;
          break;
        case 'role':
          result.Role = attributeValue;
          break;
        case 'file-as':
          result.FileAs = attributeValue;
          break;
      }
    }

    if (languageRelatedAttributes.Lang != null || languageRelatedAttributes.Dir != null) {
      result.LanguageRelatedAttributes = languageRelatedAttributes;
    }

    result.Contributor = metadataContributorNode.innerText;
    return result;
  }

  static EpubMetadataCreator readMetadataCreator(XmlElement metadataCreatorNode) {
    final languageRelatedAttributes = EpubLanguageRelatedAttributes();
    var result = EpubMetadataCreator();
    for (var metadataCreatorNodeAttribute in metadataCreatorNode.attributes) {
      var attributeValue = metadataCreatorNodeAttribute.value;
      switch (metadataCreatorNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'lang':
          languageRelatedAttributes.Lang = attributeValue;
          break;
        case 'role':
          result.Role = attributeValue;
          break;
        case 'file-as':
          result.FileAs = attributeValue;
          break;
      }
    }

    if (languageRelatedAttributes.Lang != null || languageRelatedAttributes.Dir != null) {
      result.LanguageRelatedAttributes = languageRelatedAttributes;
    }

    result.Creator = metadataCreatorNode.innerText;

    return result;
  }

  static EpubMetadataDate readMetadataDate(XmlElement metadataDateNode) {
    var result = EpubMetadataDate();
    var eventAttribute = metadataDateNode.getAttribute('event', namespace: metadataDateNode.name.namespaceUri);
    if (eventAttribute != null && eventAttribute.isNotEmpty) {
      result.Event = eventAttribute;
    }
    result.Date = metadataDateNode.innerText;
    return result;
  }

  static EpubMetadataIdentifier readMetadataIdentifier(XmlElement metadataIdentifierNode) {
    var result = EpubMetadataIdentifier();
    for (var metadataIdentifierNodeAttribute in metadataIdentifierNode.attributes) {
      var attributeValue = metadataIdentifierNodeAttribute.value;
      switch (metadataIdentifierNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'scheme':
          result.Scheme = attributeValue;
          break;
      }
    }
    result.Identifier = metadataIdentifierNode.innerText;
    return result;
  }

  /*static EpubMetadataMeta readMetadataMetaVersion2(XmlElement metadataMetaNode) {
    var result = EpubMetadataMeta();
    metadataMetaNode.attributes.forEach((XmlAttribute metadataMetaNodeAttribute) {
      var attributeValue = metadataMetaNodeAttribute.value;
      switch (metadataMetaNodeAttribute.name.local.toLowerCase()) {
        case 'name':
          result.Name = attributeValue;
          break;
        case 'content':
          result.Content = attributeValue;
          break;
      }
    });
    return result;
  }*/

  /// [readMetadata MetaVersion2] and [readMetadata MetaVersion3] have been merged for backward compatibility.
  static EpubMetadataMeta readMetadataMeta(XmlElement metadataMetaNode) {
    var result = EpubMetadataMeta();
    var languageRelatedAttributes = EpubLanguageRelatedAttributes();

    result.Attributes = {};

    for (var metadataMetaNodeAttribute in metadataMetaNode.attributes) {
      var attributeName = metadataMetaNodeAttribute.name.local.toLowerCase();
      var attributeValue = metadataMetaNodeAttribute.value;

      result.Attributes![attributeName] = attributeValue;

      switch (attributeName) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'name':
          result.Name = attributeValue;
          break;
        case 'content':
          result.Content = attributeValue;
          break;
        case 'refines':
          result.Refines = attributeValue.trim();
          break;
        case 'property':
          result.Property = attributeValue;
          break;
        case 'scheme':
          result.Scheme = attributeValue;
          break;
        case 'lang':
        case 'xml:lang':
          languageRelatedAttributes.Lang = attributeValue;
          break;
        case 'dir':
          languageRelatedAttributes.Dir = attributeValue;
          break;
      }
    }

    result.LanguageRelatedAttributes = languageRelatedAttributes;
    result.TextContent = metadataMetaNode.innerText;

    return result;
  }

  static EpubPackage readPackage(Archive epubArchive, String rootFilePath) {
    var rootFileEntry = epubArchive.findFile(rootFilePath);
    if (rootFileEntry == null) {
      throw Exception('EPUB parsing error: root file not found in archive.');
    }
    var containerDocument = XmlDocument.parse(convert.utf8.decode(rootFileEntry.content));
    var opfNamespace = 'http://www.idpf.org/2007/opf';
    var packageNode = containerDocument.getElement('package', namespace: opfNamespace);
    if (packageNode == null) {
      throw Exception('EPUB parsing error: Package node not found.');
    }
    //.firstWhere((XmlElement? elem) => elem != null);
    var epubVersionValue = packageNode.getAttribute('version');
    late EpubVersion version;
    if (epubVersionValue == '2.0') {
      version = EpubVersion.Epub2;
    } else if (epubVersionValue == '3.0') {
      version = EpubVersion.Epub3;
    } else {
      throw Exception('Unsupported EPUB version: $epubVersionValue.');
    }

    var languageRelatedAttributes = EpubLanguageRelatedAttributes(
      Lang: packageNode.getAttribute('lang'),
      Dir: packageNode.getAttribute('dir'),
    );

    var metadataNode = packageNode.getElement('metadata', namespace: opfNamespace);
    if (metadataNode == null) {
      throw Exception('EPUB parsing error: metadata not found in the package.');
    }
    var metadata = readMetadata(metadataNode, version);
    var manifestNode = packageNode.getElement('manifest', namespace: opfNamespace);

    if (manifestNode == null) {
      throw Exception('EPUB parsing error: manifest not found in the package.');
    }
    var manifest = readManifest(manifestNode);

    var spineNode = packageNode.getElement('spine', namespace: opfNamespace);

    if (spineNode == null) {
      throw Exception('EPUB parsing error: spine not found in the package.');
    }
    var spine = readSpine(spineNode);
    var guideNode = packageNode.getElement('guide', namespace: opfNamespace);
    return EpubPackage(
      Metadata: metadata,
      Manifest: manifest,
      Spine: spine,
      Version: version,
      LanguageRelatedAttributes: languageRelatedAttributes,
      Guide: guideNode == null ? null : readGuide(guideNode),
    );
  }

  static EpubSpine readSpine(XmlElement spineNode) {
    var pageProgression = spineNode.getAttribute('page-progression-direction');
    var ltr = ((pageProgression == null) || pageProgression.toLowerCase() == 'ltr');
    final items = <EpubSpineItemRef>[];
    for (var spineItemNode in spineNode.children.whereType<XmlElement>()) {
      if (spineItemNode.name.local.toLowerCase() == 'itemref') {
        var idRefAttribute = spineItemNode.getAttribute('idref');
        if (idRefAttribute == null || idRefAttribute.isEmpty) {
          throw Exception('Incorrect EPUB spine: item ID ref is missing');
        }
        var linearAttribute = spineItemNode.getAttribute('linear');
        var isLinear = linearAttribute == null || (linearAttribute.toLowerCase() == 'no');
        var spineItemRef = EpubSpineItemRef(IdRef: idRefAttribute, IsLinear: isLinear);
        items.add(spineItemRef);
      }
    }
    return EpubSpine(TableOfContents: spineNode.getAttribute('toc'), ltr: ltr, Items: items);
  }
}
