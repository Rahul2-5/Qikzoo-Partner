import 'dart:io';

import 'package:image/image.dart' as image;

/// Prepares front-camera photos for selfie confirmation and upload.
///
/// Camera previews are mirrored, but the JPEG produced by the platform camera
/// is not. Baking the orientation first and then mirroring the pixels makes
/// the saved photo upright and consistent with the preview the rider used to
/// line up their face.
class SelfieImageProcessor {
  const SelfieImageProcessor._();

  static Future<String> prepareForUpload(String sourcePath) async {
    final source = File(sourcePath);
    final bytes = await source.readAsBytes();
    final decoded = image.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('The captured selfie is not a supported image.');
    }

    final upright = image.bakeOrientation(decoded);
    final mirrored = image.flipHorizontal(upright);
    await source.writeAsBytes(
      image.encodeJpg(mirrored, quality: 95),
      flush: true,
    );
    return source.path;
  }
}
