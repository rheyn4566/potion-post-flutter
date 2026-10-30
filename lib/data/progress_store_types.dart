import 'dart:convert';

abstract interface class ProgressStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
}

class MemoryProgressStore implements ProgressStore {
  Map<String, dynamic>? data;
  @override
  Future<Map<String, dynamic>?> load() async => data;
  @override
  Future<void> save(Map<String, dynamic> value) async {
    data = Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  }
}
