import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the suit font is the small subset', () {
    final font = File('assets/fonts/NotoSansSymbols2-Regular.ttf');
    expect(font.existsSync(), isTrue);
    // The full font is about 1.2 MB. The subset with four glyphs is a few KB.
    expect(font.lengthSync(), lessThan(20 * 1024));
  });

  test('the heading font files are small Latin subsets', () {
    for (final name in ['Montserrat-SemiBold', 'Montserrat-Bold']) {
      final font = File('assets/fonts/$name.ttf');
      expect(font.existsSync(), isTrue, reason: name);
      expect(font.lengthSync(), lessThan(40 * 1024), reason: name);
    }
  });
}
