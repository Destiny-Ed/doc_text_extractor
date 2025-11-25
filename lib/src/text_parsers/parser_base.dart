import 'dart:typed_data';

/// Base class for document parsers.
abstract class ParserBase {
  Future<String> parse(Uint8List bytes);
}
