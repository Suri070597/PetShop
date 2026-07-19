import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/platform_helper.dart';

class ImageService {
  ImageService({
    ImagePicker? imagePicker,
    FilePicker? filePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _filePicker = filePicker ?? FilePicker.platform;

  final ImagePicker _imagePicker;
  final FilePicker _filePicker;

  Future<File?> pickImage() {
    if (PlatformHelper.isDesktop) {
      return _pickDesktopImage();
    }
    return _pickMobileImage();
  }

  Future<File?> _pickMobileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null) {
      return null;
    }
    return File(image.path);
  }

  Future<File?> _pickDesktopImage() async {
    final result = await _filePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    return File(path);
  }
}
