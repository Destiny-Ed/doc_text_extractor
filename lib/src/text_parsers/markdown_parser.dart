import 'package:markdown/markdown.dart';

import 'parser_base.dart';
import 'dart:typed_data';
import 'dart:convert';

class MarkdownParser extends ParserBase {
  @override
  Future<String> parse(
    Uint8List bytes,
    Function(double progress)? onProgress,
  ) async {
    final markdown = utf8.decode(bytes);

    final doc = Document();

    final nodes = doc.parseLines(markdown.split('\n'));

    return nodes.map((n) => n.textContent).join('\n').trim();
  }
}
