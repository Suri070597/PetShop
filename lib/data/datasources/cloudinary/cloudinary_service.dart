import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../app/constants/cloudinary_constants.dart';
import '../../../core/errors/exceptions.dart';

class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> uploadImage({
    required File file,
    required String folder,
    String? publicId,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(CloudinaryConstants.uploadEndpoint),
          )
          ..fields['upload_preset'] = CloudinaryConstants.uploadPreset
          ..fields['folder'] = folder;

    if (publicId != null && publicId.trim().isNotEmpty) {
      request.fields['public_id'] = publicId.trim();
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final message = error is Map<String, dynamic> ? error['message'] : null;
      throw AppException(
        message?.toString() ?? 'Tải ảnh lên Cloudinary không thành công.',
      );
    }

    final secureUrl = payload['secure_url'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw const AppException('Cloudinary không trả về URL ảnh hợp lệ.');
    }
    return secureUrl;
  }

  void close() => _client.close();
}
