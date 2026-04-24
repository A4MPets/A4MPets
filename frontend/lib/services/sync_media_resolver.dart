import 'dart:convert';

import 'package:http/http.dart' as http;

import 'media_source_encoder.dart' as media_source_encoder;

typedef SyncPostRequest =
    Future<http.Response?> Function({
      required String path,
      required Object body,
      String? bearerToken,
    });

class SyncMediaResolver {
  SyncMediaResolver({required SyncPostRequest postRequest})
    : _postRequest = postRequest;

  final SyncPostRequest _postRequest;

  bool isRemoteImageUrl(String source) {
    return source.startsWith('http://') || source.startsWith('https://');
  }

  bool shouldKeepLocalAvatarSource(String source) {
    if (source.startsWith('data:image')) {
      return true;
    }

    return !isRemoteImageUrl(source);
  }

  String? preferProfileAvatarForPull({
    required String? currentAvatar,
    required String? remoteAvatar,
  }) {
    if (currentAvatar == null || currentAvatar.isEmpty) {
      return remoteAvatar;
    }

    if (remoteAvatar == null || remoteAvatar.isEmpty) {
      return currentAvatar;
    }

    if (shouldKeepLocalAvatarSource(currentAvatar)) {
      return currentAvatar;
    }

    return remoteAvatar;
  }

  Future<String?> resolveImageUrlForSync({
    required String source,
    required String bucket,
    String? bearerToken,
  }) async {
    if (source.trim().isEmpty) {
      return null;
    }

    if (isRemoteImageUrl(source)) {
      return source;
    }

    final String? dataUri = await media_source_encoder
        .encodeImageSourceToDataUri(source);
    if (dataUri == null || dataUri.isEmpty) {
      return null;
    }

    final http.Response? response = await _postRequest(
      path: '/media/upload',
      body: <String, Object?>{'bucket': bucket, 'image_data': dataUri},
      bearerToken: bearerToken,
    );

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      return null;
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic>? data = payload['data'] as Map<String, dynamic>?;
    final String? url = data?['url']?.toString();
    if (url == null || url.isEmpty) {
      return null;
    }

    return url;
  }
}
