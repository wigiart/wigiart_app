// This is a stub file that will be used when not running on web
// The actual implementation will come from dart:html when running on web
class Blob {
  Blob(List<dynamic> data);
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement extends Element {
  AnchorElement({String? href});

  void setAttribute(String name, String value) {}
  dynamic style = _Style();
  void click() {}
  void remove() {}
}

class _Style {
  String display = '';
}

class Document {
  Element? get body => null;
}

class Element {
  void append(Element element) {}
}

final Document document = Document();
