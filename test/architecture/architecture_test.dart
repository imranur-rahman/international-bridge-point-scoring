import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_rules.dart';

void main() {
  test('all files under lib/ follow the module boundary rules', () {
    final lib = Directory('lib');
    final errors = <String>[];
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = entity.path
          .replaceAll(r'\', '/')
          .substring('lib/'.length);
      errors.addAll(checkFile(relative, entity.readAsStringSync()));
    }
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  group('rule checker', () {
    test('rejects Flutter in a pure module', () {
      final errors = checkFile(
        'scoring/src/x.dart',
        "import 'package:flutter/material.dart';",
      );
      expect(errors, hasLength(1));
    });

    test('rejects dart:io in a pure module', () {
      expect(checkFile('core/src/x.dart', "import 'dart:io';"), hasLength(1));
    });

    test('rejects a src import of another module', () {
      final errors = checkFile(
        'session/src/x.dart',
        "import '../../scoring/src/deal_scorer.dart';",
      );
      expect(errors.single, contains('barrel'));
    });

    test('accepts the barrel file of an allowed module', () {
      expect(
        checkFile('session/src/x.dart', "import '../../scoring/scoring.dart';"),
        isEmpty,
      );
      expect(
        checkFile(
          'ui/src/x.dart',
          "import 'package:bridge_scorekeeper/session/session.dart';",
        ),
        isEmpty,
      );
    });

    test('rejects auction importing scoring', () {
      final errors = checkFile(
        'auction/src/x.dart',
        "import '../../scoring/scoring.dart';",
      );
      expect(errors.single, contains('must not depend'));
    });

    test('rejects the storage plugin outside storage', () {
      final errors = checkFile(
        'ui/src/x.dart',
        "import 'package:shared_preferences/shared_preferences.dart';",
      );
      expect(errors.single, contains('only "storage"'));
    });

    test('accepts imports inside one module', () {
      expect(
        checkFile('auction/src/a.dart', "import 'b.dart';\nexport 'c.dart';"),
        isEmpty,
      );
    });
  });
}
