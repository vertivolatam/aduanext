/// Unit tests for [FilesystemArchiveAdapter].
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aduanext_adapters/storage.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FilesystemArchiveAdapter', () {
    late Directory root;
    late FilesystemArchiveAdapter adapter;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('aduanext-archive-');
      adapter = FilesystemArchiveAdapter(rootPath: root);
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('writes the blob + a sibling .meta.json with metadata', () async {
      final bytes = Uint8List.fromList(utf8.encode('{"hello":"world"}'));
      await adapter.putBytes(
        path: 'auditEvent/t1/2018/Declaration/A-1.json',
        bytes: bytes,
        contentType: 'application/json',
        metadata: {'tenant_id': 't1', 'entity_id': 'A-1'},
      );
      final blob = File(
        '${root.path}/auditEvent/t1/2018/Declaration/A-1.json',
      );
      final meta = File('${blob.path}.meta.json');
      expect(await blob.exists(), isTrue);
      expect(await meta.exists(), isTrue);
      final readBack = await blob.readAsBytes();
      expect(readBack, bytes);
      final metaJson = jsonDecode(await meta.readAsString())
          as Map<String, dynamic>;
      expect(metaJson['content_type'], 'application/json');
      expect(metaJson['metadata'], {
        'tenant_id': 't1',
        'entity_id': 'A-1',
      });
      expect(metaJson['archived_at'], isA<String>());
    });

    test('idempotent: same bytes at same path is a no-op', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      await adapter.putBytes(
        path: 'a/b.bin',
        bytes: bytes,
        contentType: 'application/octet-stream',
      );
      await adapter.putBytes(
        path: 'a/b.bin',
        bytes: bytes,
        contentType: 'application/octet-stream',
      );
      // Did not throw — that's the contract.
    });

    test('rejects overwriting with different bytes', () async {
      await adapter.putBytes(
        path: 'a/b.bin',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'application/octet-stream',
      );
      await expectLater(
        adapter.putBytes(
          path: 'a/b.bin',
          bytes: Uint8List.fromList([9, 9, 9]),
          contentType: 'application/octet-stream',
        ),
        throwsA(isA<StorageBackendException>()),
      );
    });

    test('refuses ".." traversal', () async {
      await expectLater(
        adapter.putBytes(
          path: '../escape/secrets.txt',
          bytes: Uint8List.fromList([0]),
          contentType: 'text/plain',
        ),
        throwsA(isA<StorageBackendException>()),
      );
    });

    test('refuses absolute paths', () async {
      await expectLater(
        adapter.putBytes(
          path: '/etc/passwd',
          bytes: Uint8List.fromList([0]),
          contentType: 'text/plain',
        ),
        throwsA(isA<StorageBackendException>()),
      );
    });

    test('exists() returns false for unsafe paths without throwing',
        () async {
      expect(await adapter.exists('../escape'), isFalse);
      expect(await adapter.exists('/etc/passwd'), isFalse);
    });
  });
}
