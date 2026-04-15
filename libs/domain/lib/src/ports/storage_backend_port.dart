/// Port: Storage Backend — write-only blob storage for retention
/// archives.
///
/// Today this is implemented by `FilesystemArchiveAdapter` writing to
/// a local path. S3 / GCS / MinIO adapters land in separate issues
/// (one per provider) — keeping the port narrow now means the future
/// adapters do not require a port refactor.
///
/// The port is intentionally write-only: the retention worker writes
/// archives as it purges; READ-back happens via a different port
/// (audit restore use case — VRTV-67/68).
library;

import 'dart:typed_data';

abstract class StorageBackendPort {
  /// Write [bytes] to [path] (logical path, not a filesystem path).
  /// Throws [StorageBackendException] on any I/O failure.
  ///
  /// Implementations MUST be content-addressable-friendly: if [path]
  /// already exists with the same bytes, the call is a no-op (used by
  /// the retention worker's resumability).
  Future<void> putBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String> metadata,
  });

  /// `true` iff [path] exists. Used to skip already-archived records.
  Future<bool> exists(String path);
}

class StorageBackendException implements Exception {
  final String message;
  final String? path;
  const StorageBackendException(this.message, {this.path});
  @override
  String toString() =>
      'StorageBackendException: $message${path == null ? "" : " ($path)"}';
}
