import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportPlatformPdf(
  Uint8List bytes,
  String name,
  String groupName,
) async {
  // Android/iOS: Printing ulash oynasi ko'pincha ishonchli ishlaydi.
  try {
    await Printing.sharePdf(bytes: bytes, filename: name);
    return;
  } catch (_) {}

  try {
    final file = await _writeTemp(bytes, name);
    final xFile = XFile(
      file.path,
      mimeType: 'application/pdf',
      name: name,
    );
    final result = await Share.shareXFiles(
      [xFile],
      subject: '$groupName — GAP hisoboti',
      text: 'GAP jamg\'arma hisoboti: $groupName',
    );
    if (result.status == ShareResultStatus.unavailable) {
      throw Exception('Ulashish mavjud emas');
    }
  } catch (e) {
    throw Exception('PDF yuklab bo\'lmadi: $e');
  }
}

Future<void> exportPlatformImages(
  Uint8List pdfBytes,
  String baseName,
  String groupName,
) async {
  final dir = await getTemporaryDirectory();
  final files = <XFile>[];
  var page = 0;

  await for (final raster in Printing.raster(pdfBytes, dpi: 150)) {
    final png = await raster.toPng();
    page++;
    final name = page == 1 ? '$baseName.png' : '${baseName}_$page.png';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(png);
    files.add(
      XFile(
        file.path,
        mimeType: 'image/png',
        name: name,
      ),
    );
  }

  if (files.isEmpty) {
    throw Exception('Rasm yaratilmadi');
  }

  try {
    await Share.shareXFiles(
      files,
      subject: '$groupName — GAP hisoboti (rasm)',
      text: 'GAP jamg\'arma hisoboti: $groupName',
    );
  } catch (_) {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$baseName.pdf');
  }
}

Future<File> _writeTemp(Uint8List bytes, String name) async {
  final dir = await getTemporaryDirectory();
  final safeName = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
