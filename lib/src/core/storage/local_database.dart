import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  LocalDatabase({String? fileName})
      : _fileName = fileName ?? 'catat_untung.json';
  
  final String _fileName;

  Future<File> _resolveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_fileName';
    return File(path);
  }

  Future<Map<String, dynamic>> read() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return <String, dynamic>{};
      }
      final raw = await file.readAsString();
      if (raw.isEmpty) {
        return <String, dynamic>{};
      }
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    final file = await _resolveFile();
    final encoded = json.encode(data);
    await file.writeAsString(encoded, flush: true);
  }
}
