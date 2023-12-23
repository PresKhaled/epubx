class ZipPathUtils {
  static String combine(String? directory, String? fileName) {
    String? path;
    if (directory == null || directory == '') {
      path = fileName;
    } else {
      path = '$directory/${fileName!}';
    }
    return Uri.parse(path!).normalizePath().path;
  }
}
