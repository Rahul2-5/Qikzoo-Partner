import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

abstract class DocumentImagePicker {
  Future<String?> pickImage(ImageSource source);
}

class DeviceDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    return file?.path;
  }
}

final documentImagePickerProvider =
    Provider<DocumentImagePicker>((ref) => DeviceDocumentImagePicker());
