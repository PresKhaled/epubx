class EnumFromString<T> {
  List<T> enumValues;

  EnumFromString(this.enumValues);

  T? get(String value) {
    value = '$T.$value';
    try {
      var x = enumValues.firstWhere((f) => f.toString().toUpperCase() == value.toUpperCase());
      print(x);
      return x;
    } catch (e) {
      return null;
    }
  }
}
