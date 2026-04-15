/// Filesystem-backed [StorageBackendPort] — writes archive bytes to a
/// local directory under [rootPath].
///
/// Layout: `{rootPath}/{path}` exactly as the caller supplies it. The
/// retention worker uses paths like
/// `auditEvent/{tenant}/{year}/Declaration/DUA-001.json`.
///
/// Companion `.meta.json` file alongside each archived blob carries
/// the metadata map (so future restore-from-archive can rebuild the
/// audit chain context).
///
/// This adapter is deliberately a placeholder for the production
/// S3 / GCS / MinIO adapters — the same port lets us swap them in
/// without touching the use-case layer. Tracked under separate issues
/// (one per provider).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aduanext_domain/aduanext_domain.dart';

class FilesystemArchiveAdapter implements StorageBackendPort {
  /// Root directory under which all archive paths are resolved.
  final Directory rootPath;

  FilesystemArchiveAdapter({required this.rootPath});

  @override
  Future<void> putBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String> metadata = const {},
  }) async {
    if (!_isSafePath(path)) {
      throw StorageBackendException(
        'Refusing to write outside the archive root',
        path: path,
      );
    }
    final blob = File('${rootPath.path}/$path');
    await blob.parent.create(recursive: true);

    // Idempotency: skip if same bytes already present.
    if (await blob.exists()) {
      final existing = await blob.readAsBytes();
      if (_bytesEqual(existing, bytes)) return;
      throw StorageBackendException(
        'Archive blob exists with different bytes — refusing to overwrite',
        path: path,
      );
    }

    try {
      await blob.writeAsBytes(bytes, flush: true);
      final meta = File('${blob.path}.meta.json');
      await meta.writeAsString(
        jsonEncode({
          'content_type': contentType,
          'metadata': metadata,
          'archived_at': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
    } on FileSystemException catch (e) {
      throw StorageBackendException(
        'Filesystem write failed: ${e.message}',
        path: path,
      );
    }
  }

  @override
  Future<bool> exists(String path) async {
    if (!_isSafePath(path)) return false;
    return File('${rootPath.path}/$path').exists();
  }

  /// Reject `..` traversal and absolute paths — the archive root is
  /// the security boundary.
  static bool _isSafePath(String path) {
    if (path.isEmpty) return false;
    if (path.startsWith('/')) return false;
    if (path.startsWith(r'\')) return false;
    final segments = path.split(RegExp(r'[/\\]'));
    for (final seg in segments) {
      if (seg == '..' || seg == '.') return false;
    }
    return true;
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
