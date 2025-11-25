import 'dart:typed_data';
import 'parser_base.dart';

/// Basic ASCII text extractor for legacy .doc files.
class DocParser extends ParserBase {
  @override
  Future<String> parse(Uint8List bytes) async {
    final buffer = StringBuffer();
    bool inText = false;

    for (final b in bytes) {
      if (b >= 32 && b <= 126) {
        buffer.writeCharCode(b);
        inText = true;
      } else if ((b == 10 || b == 13) && inText) {
        buffer.write('\n');
        inText = false;
      }
    }

    final text = buffer.toString().trim();

    if (text.isEmpty) {
      throw Exception("No readable text in .doc file");
    }

    return text;
  }
}
