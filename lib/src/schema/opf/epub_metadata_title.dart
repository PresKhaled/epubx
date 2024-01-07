import '../../../epubx.dart' show EpubLanguageRelatedAttributes;

/// Represents an instance of a name for the EPUB publication.
///
/// https://os.vers.one/EpubReader/reference/VersOne.Epub.Schema.EpubMetadataTitle.html
class EpubMetadataTitle {
  String? Id;
  String Title; // The text content of this title.
  EpubLanguageRelatedAttributes LanguageRelatedAttributes;

  EpubMetadataTitle({
    required this.Id,
    required this.Title,
    required this.LanguageRelatedAttributes,
  });

  @override
  bool operator ==(other) {
    final otherAs = (other as EpubMetadataTitle?);

    if (otherAs == null) return false;

    return ((Id == otherAs.Id) &&
        (Title == otherAs.Title) &&
        (LanguageRelatedAttributes == otherAs.LanguageRelatedAttributes));
  }

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
}
