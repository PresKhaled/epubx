import 'dart:async';

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
        guideReferenceNode.attributes.forEach((XmlAttribute guideReferenceNodeAttribute) {
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
        });
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
    result.Items = <EpubManifestItem>[];
    manifestNode.children.whereType<XmlElement>().forEach((XmlElement manifestItemNode) {
      if (manifestItemNode.name.local.toLowerCase() == 'item') {
        var manifestItem = EpubManifestItem();
        manifestItemNode.attributes.forEach((XmlAttribute manifestItemNodeAttribute) {
          var attributeValue = manifestItemNodeAttribute.value;
          switch (manifestItemNodeAttribute.name.local.toLowerCase()) {
            case 'id':
              manifestItem.Id = attributeValue;
              break;
            case 'href':
              manifestItem.Href = attributeValue;
              break;
            case 'media-type':
              manifestItem.MediaType = attributeValue;
              break;
            case 'media-overlay':
              manifestItem.MediaOverlay = attributeValue;
              break;
            case 'required-namespace':
              manifestItem.RequiredNamespace = attributeValue;
              break;
            case 'required-modules':
              manifestItem.RequiredModules = attributeValue;
              break;
            case 'fallback':
              manifestItem.Fallback = attributeValue;
              break;
            case 'fallback-style':
              manifestItem.FallbackStyle = attributeValue;
              break;
            case 'properties':
              manifestItem.Properties = attributeValue;
              break;
          }
        });

        if (manifestItem.Id == null || manifestItem.Id!.isEmpty) {
          throw Exception('Incorrect EPUB manifest: item ID is missing');
        }
        if (manifestItem.Href == null || manifestItem.Href!.isEmpty) {
          throw Exception('Incorrect EPUB manifest: item href is missing');
        }
        if (manifestItem.MediaType == null || manifestItem.MediaType!.isEmpty) {
          throw Exception('Incorrect EPUB manifest: item media type is missing');
        }
        result.Items!.add(manifestItem);
      }
    });
    return result;
  }

  static EpubMetadata readMetadata(XmlElement metadataNode, EpubVersion? epubVersion) {
    var result = EpubMetadata();
    result.Titles = <EpubMetadataTitle>[];
    result.Descriptions = <EpubMetadataDescription>[];
    result.Creators = <EpubMetadataCreator>[];
    result.Subjects = <String>[];
    result.Publishers = <EpubMetadataPublisher>[];
    result.Contributors = <EpubMetadataContributor>[];
    result.Dates = <EpubMetadataDate>[];
    result.Types = <String>[];
    result.Formats = <String>[];
    result.Identifiers = <EpubMetadataIdentifier>[];
    result.Sources = <String>[];
    result.Languages = <String>[];
    result.Relations = <String>[];
    result.Coverages = <String>[];
    result.Rights = <EpubMetadataRight>[];

    result.MetaItems = metadataNode.children.whereType<XmlElement>().where(
      (XmlElement metadataItemNode) {
        return (metadataItemNode.name.local.toLowerCase() == 'meta');
      },
    ).map(
      (XmlElement metadataMetaNode) {
        switch (epubVersion) {
          case EpubVersion.Epub3:
            return readMetadataMetaVersion3(metadataMetaNode);

          case EpubVersion.Epub2:
          default:
            return readMetadataMetaVersion2(metadataMetaNode);
        }
      },
    ).toList();

    metadataNode.children.whereType<XmlElement>().forEach((XmlElement metadataItemNode) {
      var innerText = metadataItemNode.text;
      switch (metadataItemNode.name.local.toLowerCase()) {
        case 'title':
          result.Titles!.add(
            EpubMetadataTitle(
              Id: metadataItemNode.getAttribute('id'),
              Title: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                XmlLang: metadataItemNode.getAttribute('xml:lang'),
                Dir: metadataItemNode.getAttribute('dir'),
              ),
            ),
          );
          break;
        case 'creator':
        case 'contributor':
          final String tagName = metadataItemNode.name.local.toLowerCase();
          var creatorOrContributor;

          if (tagName == 'creator') {
            creatorOrContributor = readMetadataCreator(metadataItemNode);
          } else {
            creatorOrContributor = readMetadataContributor(metadataItemNode);
          }

          if (epubVersion == EpubVersion.Epub3) {
            final Iterable<EpubMetadataMeta> associatedMetaItems = result.MetaItems!.where(
              (EpubMetadataMeta meta) {
                meta.Refines = meta.Refines?.trim();

                if (creatorOrContributor.Id != null && (meta.Refines == '#${creatorOrContributor.Id}')) return true;

                return false;
              },
            );

            creatorOrContributor.Role = associatedMetaItems
                .firstWhereOrNull(
                  (EpubMetadataMeta meta) => (meta.Property == 'role'),
                )
                ?.Content;

            creatorOrContributor.FileAs = associatedMetaItems
                .firstWhereOrNull(
                  (EpubMetadataMeta meta) => (meta.Property == 'file-as'),
                )
                ?.Content;

            creatorOrContributor.AlternateScripts = (associatedMetaItems
                .where(
              (EpubMetadataMeta meta) => (meta.Property == 'alternate-script'),
            )
                .map(
              (EpubMetadataMeta meta) {
                final EpubLanguageRelatedAttributes languageRelatedAttributes = EpubLanguageRelatedAttributes()
                  ..XmlLang = meta.Attributes?['xml:lang']
                  ..Dir = meta.Attributes?['dir'];
                final EpubMetadataCreatorAlternateScript alternateScript = EpubMetadataCreatorAlternateScript()
                  ..name = meta.Content // Name in another language.
                  ..LanguageRelatedAttributes = languageRelatedAttributes;

                return alternateScript;
              },
            ).toList());

            creatorOrContributor.DisplaySeq = int.tryParse(associatedMetaItems
                    .firstWhereOrNull(
                      (EpubMetadataMeta meta) => (meta.Property == 'display-seq'),
                    )
                    ?.Content ??
                '');
            ;
          }

          if (tagName == 'creator')
            result.Creators!.add(creatorOrContributor);
          else
            result.Contributors!.add(creatorOrContributor);
          break;
        case 'subject':
          result.Subjects!.add(innerText);
          break;
        case 'description':
          result.Descriptions!.add(
            EpubMetadataDescription(
              Id: metadataItemNode.getAttribute('id'),
              Description: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                XmlLang: metadataItemNode.getAttribute('xml:lang'),
                Dir: metadataItemNode.getAttribute('dir'),
              ),
            ),
          );
          break;
        case 'publisher':
          result.Publishers!.add(
            EpubMetadataPublisher(
              Id: metadataItemNode.getAttribute('id'),
              Publisher: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                XmlLang: metadataItemNode.getAttribute('xml:lang'),
                Dir: metadataItemNode.getAttribute('dir'),
              ),
            ),
          );
          break;

        case 'date':
          var date = readMetadataDate(metadataItemNode);
          result.Dates!.add(date);
          break;
        case 'type':
          result.Types!.add(innerText);
          break;
        case 'format':
          result.Formats!.add(innerText);
          break;
        case 'identifier':
          var identifier = readMetadataIdentifier(metadataItemNode);
          result.Identifiers!.add(identifier);
          break;
        case 'source':
          result.Sources!.add(innerText);
          break;
        case 'language':
          result.Languages!.add(innerText);
          break;
        case 'relation':
          result.Relations!.add(innerText);
          break;
        case 'coverage':
          result.Coverages!.add(innerText);
          break;
        case 'rights':
          result.Rights!.add(
            EpubMetadataRight(
              Id: metadataItemNode.getAttribute('id'),
              Right: innerText,
              LanguageRelatedAttributes: EpubLanguageRelatedAttributes(
                XmlLang: metadataItemNode.getAttribute('xml:lang'),
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
    });
    return result;
  }

  static EpubMetadataContributor readMetadataContributor(XmlElement metadataContributorNode) {
    final languageRelatedAttributes = EpubLanguageRelatedAttributes();
    var result = EpubMetadataContributor();
    metadataContributorNode.attributes.forEach((XmlAttribute metadataContributorNodeAttribute) {
      var attributeValue = metadataContributorNodeAttribute.value;
      switch (metadataContributorNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'xml:lang':
          languageRelatedAttributes.XmlLang = attributeValue;
          break;
        case 'role':
          result.Role = attributeValue;
          break;
        case 'file-as':
          result.FileAs = attributeValue;
          break;
      }
    });

    if (languageRelatedAttributes.XmlLang != null || languageRelatedAttributes.Dir != null) {
      result.LanguageRelatedAttributes = languageRelatedAttributes;
    }

    result.Contributor = metadataContributorNode.text;
    return result;
  }

  static EpubMetadataCreator readMetadataCreator(XmlElement metadataCreatorNode) {
    final languageRelatedAttributes = EpubLanguageRelatedAttributes();
    var result = EpubMetadataCreator();
    metadataCreatorNode.attributes.forEach((XmlAttribute metadataCreatorNodeAttribute) {
      var attributeValue = metadataCreatorNodeAttribute.value;
      switch (metadataCreatorNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'xml:lang':
          languageRelatedAttributes.XmlLang = attributeValue;
          break;
        case 'role':
          result.Role = attributeValue;
          break;
        case 'file-as':
          result.FileAs = attributeValue;
          break;
      }
    });

    if (languageRelatedAttributes.XmlLang != null || languageRelatedAttributes.Dir != null) {
      result.LanguageRelatedAttributes = languageRelatedAttributes;
    }

    result.Creator = metadataCreatorNode.text;

    return result;
  }

  static EpubMetadataDate readMetadataDate(XmlElement metadataDateNode) {
    var result = EpubMetadataDate();
    var eventAttribute = metadataDateNode.getAttribute('event', namespace: metadataDateNode.name.namespaceUri);
    if (eventAttribute != null && eventAttribute.isNotEmpty) {
      result.Event = eventAttribute;
    }
    result.Date = metadataDateNode.text;
    return result;
  }

  static EpubMetadataIdentifier readMetadataIdentifier(XmlElement metadataIdentifierNode) {
    var result = EpubMetadataIdentifier();
    metadataIdentifierNode.attributes.forEach((XmlAttribute metadataIdentifierNodeAttribute) {
      var attributeValue = metadataIdentifierNodeAttribute.value;
      switch (metadataIdentifierNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'scheme':
          result.Scheme = attributeValue;
          break;
      }
    });
    result.Identifier = metadataIdentifierNode.text;
    return result;
  }

  static EpubMetadataMeta readMetadataMetaVersion2(XmlElement metadataMetaNode) {
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
  }

  static EpubMetadataMeta readMetadataMetaVersion3(XmlElement metadataMetaNode) {
    var result = EpubMetadataMeta();
    result.Attributes = {};
    metadataMetaNode.attributes.forEach((XmlAttribute metadataMetaNodeAttribute) {
      var attributeValue = metadataMetaNodeAttribute.value;
      result.Attributes![metadataMetaNodeAttribute.name.local.toLowerCase()] = attributeValue;
      switch (metadataMetaNodeAttribute.name.local.toLowerCase()) {
        case 'id':
          result.Id = attributeValue;
          break;
        case 'refines':
          result.Refines = attributeValue;
          break;
        case 'property':
          result.Property = attributeValue;
          break;
        case 'scheme':
          result.Scheme = attributeValue;
          break;
      }
    });
    result.Content = metadataMetaNode.text;
    return result;
  }

  static Future<EpubPackage> readPackage(Archive epubArchive, String rootFilePath) async {
    var rootFileEntry = epubArchive.files.firstWhereOrNull((ArchiveFile testFile) => testFile.name == rootFilePath);
    if (rootFileEntry == null) {
      throw Exception('EPUB parsing error: root file not found in archive.');
    }
    var containerDocument = XmlDocument.parse(convert.utf8.decode(rootFileEntry.content));
    var opfNamespace = 'http://www.idpf.org/2007/opf';
    var packageNode = containerDocument.findElements('package', namespace: opfNamespace).firstWhere((XmlElement? elem) => elem != null);
    var result = EpubPackage();
    var epubVersionValue = packageNode.getAttribute('version');
    if (epubVersionValue == '2.0') {
      result.Version = EpubVersion.Epub2;
    } else if (epubVersionValue == '3.0') {
      result.Version = EpubVersion.Epub3;
    } else {
      throw Exception('Unsupported EPUB version: $epubVersionValue.');
    }

    result.LanguageRelatedAttributes = EpubLanguageRelatedAttributes(
      XmlLang: packageNode.getAttribute('xml:lang'),
      Dir: packageNode.getAttribute('dir'),
    );

    var metadataNode =
        packageNode.findElements('metadata', namespace: opfNamespace).cast<XmlElement?>().firstWhere((XmlElement? elem) => elem != null);
    if (metadataNode == null) {
      throw Exception('EPUB parsing error: metadata not found in the package.');
    }
    var metadata = readMetadata(metadataNode, result.Version);
    result.Metadata = metadata;
    var manifestNode =
        packageNode.findElements('manifest', namespace: opfNamespace).cast<XmlElement?>().firstWhere((XmlElement? elem) => elem != null);
    if (manifestNode == null) {
      throw Exception('EPUB parsing error: manifest not found in the package.');
    }
    var manifest = readManifest(manifestNode);
    result.Manifest = manifest;

    var spineNode = packageNode.findElements('spine', namespace: opfNamespace).cast<XmlElement?>().firstWhere((XmlElement? elem) => elem != null);
    if (spineNode == null) {
      throw Exception('EPUB parsing error: spine not found in the package.');
    }
    var spine = readSpine(spineNode);
    result.Spine = spine;
    var guideNode = packageNode.findElements('guide', namespace: opfNamespace).firstWhereOrNull((XmlElement? elem) => elem != null);
    if (guideNode != null) {
      var guide = readGuide(guideNode);
      result.Guide = guide;
    }
    return result;
  }

  static EpubSpine readSpine(XmlElement spineNode) {
    var result = EpubSpine();
    result.Items = <EpubSpineItemRef>[];
    var tocAttribute = spineNode.getAttribute('toc');
    result.TableOfContents = tocAttribute;
    var pageProgression = spineNode.getAttribute('page-progression-direction');
    result.ltr = ((pageProgression == null) || pageProgression.toLowerCase() == 'ltr');
    spineNode.children.whereType<XmlElement>().forEach((XmlElement spineItemNode) {
      if (spineItemNode.name.local.toLowerCase() == 'itemref') {
        var spineItemRef = EpubSpineItemRef();
        var idRefAttribute = spineItemNode.getAttribute('idref');
        if (idRefAttribute == null || idRefAttribute.isEmpty) {
          throw Exception('Incorrect EPUB spine: item ID ref is missing');
        }
        spineItemRef.IdRef = idRefAttribute;
        var linearAttribute = spineItemNode.getAttribute('linear');
        spineItemRef.IsLinear = linearAttribute == null || (linearAttribute.toLowerCase() == 'no');
        result.Items!.add(spineItemRef);
      }
    });
    return result;
  }

  _getMetaItemsAssociatedWith() {}
}
