import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_config.dart';
import '../supabase_client_factory.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService({SupabaseClient? client})
      : _client = client ?? SupabaseClientFactory.client;

  Future<String> uploadDrawingPngBytes({
    required String path,
    required Uint8List pngBytes,
  }) async {
    final bucket = SupabaseConfig.drawingsBucket;

    await _client.storage.from(bucket).uploadBinary(
          path,
          pngBytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

    // If your bucket is public, this returns a usable public URL.
    // If private, switch to signed URLs.
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }
}
