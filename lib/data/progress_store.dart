import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_progress_store.dart';
import 'progress_store_types.dart';
export 'progress_store_types.dart';

class LocalProgressStore implements ProgressStore {
  LocalProgressStore({
    Future<Directory> Function()? directory,
    ProgressStore? legacy,
  }) : _directory = directory ?? _privateDirectory,
       _legacy = legacy ?? _PreferencesProgressStore();
  final Future<Directory> Function() _directory;
  final ProgressStore _legacy;
  static Future<Directory> _privateDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final path = await const MethodChannel(
        'potion_post/progress',
      ).invokeMethod<String>('supportDirectory');
      if (path == null || path.isEmpty)
        throw const FileSystemException('Private game storage unavailable');
      return Directory(path);
    }
    return getApplicationSupportDirectory();
  }

  FileProgressStore? _opened;
  Future<FileProgressStore> _files() async =>
      _opened ??= FileProgressStore(await _directory());

  @override
  Future<Map<String, dynamic>?> load() async {
    final files = await _files();
    Object? fileError;
    try {
      final data = await files.load();
      if (data != null) return data;
    } catch (error) {
      fileError = error;
    }
    final old = await _legacy.load();
    if (old != null) {
      FileProgressStore.validate(old);
      await files.save(old);
      return old;
    }
    if (fileError != null) throw fileError;
    return null;
  }

  @override
  Future<void> save(Map<String, dynamic> data) async =>
      (await _files()).save(data);
}

class _PreferencesProgressStore implements ProgressStore {
  static const _key = 'potion_post_progress_v1';
  @override
  Future<Map<String, dynamic>?> load() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final raw = await const MethodChannel(
        'potion_post/progress',
      ).invokeMethod<String>('legacyProgress');
      return raw == null ? null : FileProgressStore.validate(jsonDecode(raw));
    }
    Object? error;
    try {
      final raw = await SharedPreferencesAsync().getString(_key);
      if (raw != null) return FileProgressStore.validate(jsonDecode(raw));
    } catch (caught) {
      error = caught;
    }
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) return FileProgressStore.validate(jsonDecode(raw));
    } catch (caught) {
      error = caught;
    }
    if (error != null) throw error;
    return null;
  }

  @override
  Future<void> save(Map<String, dynamic> data) =>
      SharedPreferencesAsync().setString(_key, jsonEncode(data));
}
