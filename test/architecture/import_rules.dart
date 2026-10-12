// Module boundary rules from design.md, decision D1.

const String packageName = 'bridge_scorekeeper';

const List<String> modules = [
  'core',
  'auction',
  'scoring',
  'session',
  'storage',
  'ui',
];

/// The modules that each module may import (through their barrel files).
const Map<String, Set<String>> allowedModuleDeps = {
  'core': {},
  'auction': {'core'},
  'scoring': {'core'},
  'session': {'core', 'auction', 'scoring'},
  'storage': {'core', 'auction', 'scoring', 'session'},
  'ui': {'core', 'auction', 'scoring', 'session', 'storage'},
  // lib/main.dart
  'main': {'ui', 'storage'},
};

/// Modules that hold bridge rules only. They must not import Flutter or
/// any plugin.
const Set<String> pureModules = {'core', 'auction', 'scoring', 'session'};

const Set<String> forbiddenDartLibsInPure = {'dart:ui', 'dart:io', 'dart:html'};

const Set<String> storagePlugins = {'shared_preferences'};

/// One import or export line of a Dart file.
class ImportLine {
  ImportLine(this.uri, this.line);
  final String uri;
  final int line;
}

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
);

List<ImportLine> parseImports(String source) {
  final result = <ImportLine>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final m = _directive.firstMatch(lines[i]);
    if (m != null) result.add(ImportLine(m.group(1)!, i + 1));
  }
  return result;
}

/// Returns the module of a path relative to `lib/` (for example
/// `scoring/src/deal_scorer.dart` gives `scoring`, `main.dart` gives `main`).
String? moduleOf(String libRelativePath) {
  final parts = libRelativePath.split('/');
  if (parts.length == 1) return parts.first == 'main.dart' ? 'main' : null;
  return modules.contains(parts.first) ? parts.first : null;
}

/// Resolves [uri] from the file at [fromLibPath] to a path relative to
/// `lib/`. Returns null for `dart:` URIs and for other packages.
String? resolveToLibPath(String fromLibPath, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    final prefix = 'package:$packageName/';
    return uri.startsWith(prefix) ? uri.substring(prefix.length) : null;
  }
  final dir = fromLibPath.contains('/')
      ? fromLibPath.substring(0, fromLibPath.lastIndexOf('/'))
      : '';
  final segments = dir.isEmpty ? <String>[] : dir.split('/');
  for (final part in uri.split('/')) {
    if (part == '..') {
      if (segments.isEmpty) return null;
      segments.removeLast();
    } else if (part != '.') {
      segments.add(part);
    }
  }
  return segments.join('/');
}

String? externalPackageOf(String uri) {
  if (!uri.startsWith('package:')) return null;
  final name = uri.substring('package:'.length).split('/').first;
  return name == packageName ? null : name;
}

/// Checks one file. Returns a list of violations in readable form.
List<String> checkFile(String libRelativePath, String source) {
  final from = moduleOf(libRelativePath);
  if (from == null) {
    return ['$libRelativePath: file is not in a known module folder'];
  }
  final errors = <String>[];
  for (final imp in parseImports(source)) {
    final where = '$libRelativePath:${imp.line} (${imp.uri})';
    final uri = imp.uri;

    if (uri.startsWith('dart:')) {
      if (pureModules.contains(from) && forbiddenDartLibsInPure.contains(uri)) {
        errors.add('$where: module "$from" must not import $uri');
      }
      continue;
    }

    final external = externalPackageOf(uri);
    if (external != null) {
      if (pureModules.contains(from)) {
        errors.add('$where: module "$from" must not import other packages');
      } else if (storagePlugins.contains(external) && from != 'storage') {
        errors.add('$where: only "storage" may import $external');
      } else if (from == 'storage' &&
          (external == 'flutter' || external == 'flutter_riverpod')) {
        errors.add('$where: "storage" must not import Flutter widgets');
      }
      continue;
    }

    final target = resolveToLibPath(libRelativePath, uri);
    if (target == null) {
      errors.add('$where: import leaves lib/');
      continue;
    }
    final to = moduleOf(target);
    if (to == null) {
      errors.add('$where: target is not in a known module folder');
      continue;
    }
    if (to == from) continue;
    if (!(allowedModuleDeps[from] ?? const {}).contains(to)) {
      errors.add('$where: module "$from" must not depend on "$to"');
      continue;
    }
    if (target != '$to/$to.dart') {
      errors.add('$where: import the barrel file "$to/$to.dart", not $target');
    }
  }
  return errors;
}
