import 'dart:js_interop';
import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

Future<void> exportPlatformPdf(
  Uint8List bytes,
  String name,
  String groupName,
) async {
  try {
    await Printing.sharePdf(bytes: bytes, filename: name);
  } catch (_) {
    _downloadBytes(bytes, name, 'application/pdf');
  }
}

Future<void> exportPlatformImages(
  Uint8List pdfBytes,
  String baseName,
  String groupName,
) async {
  var page = 0;
  await for (final raster in Printing.raster(pdfBytes, dpi: 150)) {
    final png = await raster.toPng();
    page++;
    final name = page == 1 ? '$baseName.png' : '${baseName}_$page.png';
    _downloadBytes(png, name, 'image/png');
  }

  if (page == 0) {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$baseName.pdf',
    );
  }
}

void _downloadBytes(Uint8List bytes, String filename, String mime) {
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
