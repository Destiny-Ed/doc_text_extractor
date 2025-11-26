import 'package:doc_text_extractor/src/isolates/doc_isolate.dart';
import 'package:flutter/foundation.dart';

import 'parser_base.dart';

/// Basic ASCII text extractor for legacy .doc files.
class DocParser extends ParserBase {
  @override
  Future<String> parse(
    Uint8List bytes,
    Function(double progress)? onProgress,
  ) async {
    // If file is large (>1.5 MB), isolate is MUCH safer
    final isLarge = bytes.lengthInBytes > 1.5 * 1024 * 1024;

    if (isLarge) {
      return compute(extractDocInIsolate, bytes);
    }

    final total = bytes.length;
    final buffer = StringBuffer();
    bool inText = false;

    for (int i = 0; i < total; i++) {
      final b = bytes[i];

      if (b >= 32 && b <= 126) {
        buffer.writeCharCode(b);
        inText = true;
      } else if ((b == 10 || b == 13) && inText) {
        buffer.write('\n');
        inText = false;
      }

      // Update progress every ~2%
      if (onProgress != null && i % 5000 == 0) {
        onProgress(i / total);
      }
    }

    // Complete progress
    onProgress?.call(1.0);

    final text = buffer.toString().trim();

    if (text.isEmpty) {
      throw Exception("No readable text in .doc file");
    }

    return text;
  }
}
