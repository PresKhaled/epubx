import 'package:archive/archive.dart';

import '../entities/epub_schema.dart';
import '../utils/zip_path_utils.dart';
import 'navigation_reader.dart';
import 'package_reader.dart';
import 'root_file_path_reader.dart';

class SchemaReader {
  static EpubSchema readSchema(Archive epubArchive) {
    var rootFilePath = RootFilePathReader.getRootFilePath(epubArchive)!;
    var contentDirectoryPath = ZipPathUtils.getDirectoryPath(rootFilePath);
    var package = PackageReader.readPackage(epubArchive, rootFilePath);
    var navigation = NavigationReader.readNavigation(epubArchive, contentDirectoryPath, package);
    return EpubSchema(ContentDirectoryPath: contentDirectoryPath, Package: package, Navigation: navigation);
  }
}
