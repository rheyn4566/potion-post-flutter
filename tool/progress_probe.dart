// A fresh Dart process exercises exactly the on-disk checkpoint implementation.
import 'dart:convert';
import 'dart:io';
import '../lib/data/file_progress_store.dart';

Future<void> main(List<String> args) async {
  final store = FileProgressStore(Directory(args[1]));
  await store.load();
  if (args[0] == 'write') {
    await store.save(
      Map<String, dynamic>.from(
        jsonDecode(await File(args[2]).readAsString()) as Map,
      ),
    );
  } else {
    stdout.write(jsonEncode(await store.load()));
  }
}
