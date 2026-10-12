import 'dart:convert';

/// The current data format version of stored sessions and presets.
const int currentFormatVersion = 1;

/// Changes the JSON of one format version to the next version.
typedef Migration = Map<String, Object?> Function(Map<String, Object?> data);

/// Thrown when stored data cannot be read.
class UnreadableDataException implements Exception {
  UnreadableDataException(this.message);

  final String message;

  @override
  String toString() => 'UnreadableDataException: $message';
}

/// Wraps [data] in an envelope with the format version.
String encodeEnvelope(Object? data, {int version = currentFormatVersion}) =>
    jsonEncode({'formatVersion': version, 'data': data});

/// Reads an envelope and runs the migrations from its version up to
/// [targetVersion]. [migrations] maps a version N to the step from N to
/// N + 1.
Object? decodeEnvelope(
  String raw, {
  Map<int, Migration> migrations = const {},
  int targetVersion = currentFormatVersion,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    throw UnreadableDataException('Not valid JSON: ${e.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw UnreadableDataException('Not an envelope');
  }
  final version = decoded['formatVersion'];
  if (version is! int || version < 1 || version > targetVersion) {
    throw UnreadableDataException('Unknown format version $version');
  }
  var data = decoded['data'];
  for (var v = version; v < targetVersion; v++) {
    final step = migrations[v];
    if (step == null) {
      throw UnreadableDataException('No migration from version $v');
    }
    if (data is! Map<String, Object?>) {
      throw UnreadableDataException('Data is not an object');
    }
    data = step(data);
  }
  return data;
}
