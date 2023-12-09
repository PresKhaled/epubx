import 'package:quiver/core.dart';

import '../schema/navigation/epub_navigation.dart';
import '../schema/opf/epub_package.dart';

class EpubSchema {
  final EpubPackage Package;
  final EpubNavigation Navigation;
  final String ContentDirectoryPath;

  EpubSchema({required this.Package, required this.Navigation, required this.ContentDirectoryPath});

  @override
  int get hashCode => hash3(Package.hashCode, Navigation.hashCode, ContentDirectoryPath.hashCode);

  @override
  bool operator ==(other) {
    if (other is! EpubSchema) {
      return false;
    }

    return Package == other.Package &&
        Navigation == other.Navigation &&
        ContentDirectoryPath == other.ContentDirectoryPath;
  }
}
