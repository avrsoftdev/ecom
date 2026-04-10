import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

abstract class AdminStorageDataSource {
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  });

  Future<void> deleteByUrl(String downloadUrl);
}

class AdminStorageDataSourceImpl implements AdminStorageDataSource {
  AdminStorageDataSourceImpl({required this.storage});

  final FirebaseStorage storage;

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final ref = storage.ref(path);
    final metadata = SettableMetadata(contentType: contentType ?? 'application/octet-stream');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteByUrl(String downloadUrl) async {
    try {
      await storage.refFromURL(downloadUrl).delete();
    } catch (e) {
      debugPrint('Storage delete skipped: $e');
    }
  }
}
