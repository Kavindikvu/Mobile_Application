import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/svg.dart' as svg;
import 'package:vector_graphics/vector_graphics.dart' as vector_graphics;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate launcher icon from SVG', () async {
    if (!Platform.environment.containsKey('GENERATE_LAUNCHER_ICON')) {
      return;
    }

    final svgFile = File('assets/app_icon/skillora_icon.svg');
    final svgString = await svgFile.readAsString();
    final loader = svg.SvgStringLoader(svgString);
    final pictureInfo = await vector_graphics.vg.loadPicture(loader, null);
    final image = await pictureInfo.picture.toImage(1024, 1024);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final outputFile = File('assets/app_icon/skillora_icon.png');
    await outputFile.create(recursive: true);
    await outputFile.writeAsBytes(byteData!.buffer.asUint8List());

    pictureInfo.picture.dispose();
  });
}

