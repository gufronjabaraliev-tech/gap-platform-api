// Launcher ikonkasi: assets/branding/app_icon_source.png (1024x1024) bo‘lishi kerak.
// gap_app: dart run tool/generate_launcher_icon.dart

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final src = File('assets/branding/app_icon_source.png');
  if (!src.existsSync()) {
    stderr.writeln(
      'Yo\'q: ${src.path}\n'
      '1024x1024 PNG qo\'ying, keyin: dart run flutter_launcher_icons',
    );
    exit(1);
  }

  final image = img.decodeImage(src.readAsBytesSync());
  if (image == null) {
    stderr.writeln('PNG o\'qilmadi');
    exit(1);
  }

  var square = image;
  if (image.width != image.height) {
    final side = image.width < image.height ? image.width : image.height;
    square = img.copyCrop(image, x: 0, y: 0, width: side, height: side);
  }
  if (square.width != 1024) {
    square = img.copyResize(
      square,
      width: 1024,
      height: 1024,
      interpolation: img.Interpolation.cubic,
    );
    src.writeAsBytesSync(img.encodePng(square));
    stdout.writeln('Yangilandi: ${src.path} (1024x1024)');
  } else {
    stdout.writeln('Tayyor: ${src.path}');
  }
  stdout.writeln('Keyin: dart run flutter_launcher_icons');
}
