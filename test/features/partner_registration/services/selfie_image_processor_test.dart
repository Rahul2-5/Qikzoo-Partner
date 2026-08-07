import 'dart:io';

import 'package:delivery_partner_app/features/partner_registration/services/selfie_image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  test('bakes orientation and mirrors the captured front-camera image',
      () async {
    final directory = await Directory.systemTemp.createTemp('selfie_processor_');
    final selfie = File('${directory.path}${Platform.pathSeparator}selfie.jpg');
    addTearDown(() => directory.delete(recursive: true));

    final source = image.Image(width: 2, height: 1)
      ..setPixelRgb(0, 0, 255, 0, 0)
      ..setPixelRgb(1, 0, 0, 0, 255);
    await selfie.writeAsBytes(image.encodeJpg(source));

    final resultPath = await SelfieImageProcessor.prepareForUpload(selfie.path);
    final result = image.decodeImage(await File(resultPath).readAsBytes())!;

    expect(result.getPixel(0, 0).b, greaterThan(result.getPixel(0, 0).r));
    expect(result.getPixel(1, 0).r, greaterThan(result.getPixel(1, 0).b));
  });
}
