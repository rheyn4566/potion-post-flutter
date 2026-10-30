import 'dart:convert';
import 'dart:io';

import 'progress_store_types.dart';

/// Two flushed, checksummed checkpoints in private app storage. A complete
/// pending write can also recover a process stopped just before the rename.
class FileProgressStore implements ProgressStore {
  FileProgressStore(this.directory);
  final Directory directory;
  int _sequence = 0;
  File _file(String name) => File('${directory.path}/potion-post-$name');
  static String _checksum(String input) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(input)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static Map<String, dynamic> validate(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['version'] != 1 ||
        value['stars'] is! Map ||
        value['sessions'] is! Map) {
      throw const FormatException('This game checkpoint is incomplete.');
    }
    return value;
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    Map<String, dynamic>? newest;
    var found = false, newestSequence = -1;
    for (final name in [
      'save-a.json',
      'save-b.json',
      'save-a.tmp',
      'save-b.tmp',
    ]) {
      final file = _file(name);
      if (!await file.exists()) continue;
      found = true;
      try {
        final envelope = jsonDecode(await file.readAsString()) as Map;
        final sequence = envelope['sequence'], payload = envelope['payload'];
        if (sequence is! int ||
            sequence < 1 ||
            payload is! String ||
            envelope['checksum'] != _checksum('$sequence:$payload'))
          continue;
        final data = validate(jsonDecode(payload));
        if (sequence > newestSequence) {
          newestSequence = sequence;
          newest = data;
        }
      } catch (_) {
        // Try the other copy before treating a damaged save as a load failure.
      }
    }
    if (newest != null) {
      _sequence = newestSequence;
      return newest;
    }
    if (found) throw const FormatException('No readable game checkpoint.');
    return null;
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    validate(data);
    await directory.create(recursive: true);
    final next = _sequence + 1, payload = jsonEncode(data);
    final encoded = jsonEncode({
      'sequence': next,
      'payload': payload,
      'checksum': _checksum('$next:$payload'),
    });
    for (final slot in ['a', 'b']) {
      final pending = _file('save-$slot.tmp');
      await pending.writeAsString(encoded, flush: true);
      await pending.rename(_file('save-$slot.json').path);
      _sequence = next;
    }
  }
}
