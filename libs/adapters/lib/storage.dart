/// Storage adapters implementing [StorageBackendPort].
///
/// * [FilesystemArchiveAdapter] — local-filesystem placeholder used by
///   the retention worker. Production S3 / GCS / MinIO adapters land in
///   per-provider follow-up issues.
library;

export 'src/storage/filesystem_archive_adapter.dart';
