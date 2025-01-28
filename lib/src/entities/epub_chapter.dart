import 'package:quiver/core.dart';

class EpubChapter {
  String ContentFileName;
  String HtmlContent;

  EpubChapter({required this.ContentFileName, required this.HtmlContent});

  @override
  int get hashCode {
    var objects = [
      ContentFileName.hashCode,
      HtmlContent.hashCode,
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (other is! EpubChapter) {
      return false;
    }
    return ContentFileName == other.ContentFileName && HtmlContent == other.HtmlContent;
  }

  @override
  String toString() {
    return 'FileName: $ContentFileName';
  }
}
