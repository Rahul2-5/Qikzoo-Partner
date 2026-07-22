import 'package:file_picker/file_picker.dart';
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

/// Separate from [DocumentImagePicker] (image_picker only ever returns
/// photos) — used where the backend also accepts a PDF, e.g. KYC document
/// uploads (`common/media/document-validation.ts`'s `ALLOWED_DOCUMENT_MIME_TYPES`
/// includes `application/pdf`).
abstract class KycDocumentFilePicker {
  Future<String?> pickPdf();
}

class DeviceKycDocumentFilePicker implements KycDocumentFilePicker {
  @override
  Future<String?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single.path;
  }
}

final kycDocumentFilePickerProvider =
    Provider<KycDocumentFilePicker>((ref) => DeviceKycDocumentFilePicker());
