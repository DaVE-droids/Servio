import 'dart:typed_data';

/// Profile photo bytes selected by the user for upload.
class ProfilePhotoUploadRequest {
  /// Creates a profile photo upload request.
  const ProfilePhotoUploadRequest({
    required this.bytes,
    required this.contentType,
  });

  /// Image bytes.
  final Uint8List bytes;

  /// MIME type for Firebase Storage metadata.
  final String contentType;
}
