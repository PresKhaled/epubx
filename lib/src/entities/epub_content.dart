import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_byte_content_file.dart';
import 'epub_content_file.dart';
import 'epub_text_content_file.dart';

class EpubContent {
  final Map<String, EpubTextContentFile> Html;
  final Map<String, EpubTextContentFile> Css;
  final Map<String, EpubByteContentFile> Images;
  final Map<String, EpubByteContentFile> Fonts;
  Map<String, EpubContentFile> AllFiles = {};

  EpubContent({
    required this.Html,
    required this.Css,
    required this.Images,
    required this.Fonts,
  });

  @override
  int get hashCode {
    var objects = [
      ...Html.keys.map((key) => key.hashCode),
      ...Html.values.map((value) => value.hashCode),
      ...Css.keys.map((key) => key.hashCode),
      ...Css.values.map((value) => value.hashCode),
      ...Images.keys.map((key) => key.hashCode),
      ...Images.values.map((value) => value.hashCode),
      ...Fonts.keys.map((key) => key.hashCode),
      ...Fonts.values.map((value) => value.hashCode),
      ...AllFiles.keys.map((key) => key.hashCode),
      ...AllFiles.values.map((value) => value.hashCode),
    ];

    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubContent) {
      return false;
    }
    return collections.mapsEqual(Html, other.Html) &&
        collections.mapsEqual(Css, other.Css) &&
        collections.mapsEqual(Images, other.Images) &&
        collections.mapsEqual(Fonts, other.Fonts) &&
        collections.mapsEqual(AllFiles, other.AllFiles);
  }
}
