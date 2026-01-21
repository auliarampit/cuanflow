final class Translations {
  const Translations(this._map);

  final Map<String, String> _map;

  String tr(String key, [Map<String, String> params = const {}]) {
    final raw = _map[key] ?? key;
    return _applyParams(raw, params);
  }

  String _applyParams(String input, Map<String, String> params) {
    var result = input;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}
