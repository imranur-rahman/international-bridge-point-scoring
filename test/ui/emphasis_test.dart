import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

/// The style that a text widget really draws with, after the default text
/// styles are merged.
TextStyle drawnStyle(WidgetTester tester, Finder text) {
  final rich = find.descendant(of: text, matching: find.byType(RichText));
  return tester
      .widget<RichText>(rich.evaluate().isEmpty ? text : rich.first)
      .text
      .style!;
}

int weight(TextStyle style) => (style.fontWeight ?? FontWeight.w400).value;

void main() {
  testWidgets('page and section titles are bold, sections in primary', (
    tester,
  ) async {
    final h = await pumpApp(tester, location: '/setup');
    expect(weight(drawnStyle(tester, find.text('New session'))), 700);
    for (var i = 0; i < 4; i++) {
      await h.enter('name-${Seat.values[i].name}', 'P$i');
    }
    await h.tapKey('next');
    final primary = Theme.of(tester.element(find.text('End rule')))
        .colorScheme
        .primary;
    for (final title in ['End rule', 'Options']) {
      final style = drawnStyle(tester, find.text(title));
      expect(weight(style), 700, reason: title);
      expect(style.color, primary, reason: title);
    }
    // Body text stays at normal weight.
    expect(weight(drawnStyle(tester, find.text('Number of deals'))), 400);
    // Headings use the heading font; normal text keeps the default font.
    expect(drawnStyle(tester, find.text('End rule')).fontFamily, 'Montserrat');
    expect(
      drawnStyle(tester, find.text('Number of deals')).fontFamily,
      isNot('Montserrat'),
    );
  });

  testWidgets('score sheet: totals bold, rubber rows normal', (tester) async {
    var s = newSession();
    s = playDeal(s, '4S', Seat.north);
    await pumpApp(tester, active: s, location: '/sheet');
    expect(
      weight(drawnStyle(tester, find.text('Session total'))),
      greaterThanOrEqualTo(600),
    );
    expect(weight(drawnStyle(tester, find.text('Rubber 1 (current)'))), 400);
  });

  testWidgets('final summary: the winner line is bold', (tester) async {
    var s = playDeal(newSession(), '4S', Seat.north);
    s = run(s, [const EndSession()]);
    await pumpApp(tester, active: s, location: '/summary');
    expect(
      weight(drawnStyle(tester, find.byKey(const Key('winner')))),
      greaterThanOrEqualTo(600),
    );
  });

  testWidgets('deal: contract, result, roles, and breakdown are bold', (
    tester,
  ) async {
    final s = run(newSession(), [
      const AdvanceFromStart(),
      SetContract(contract('4S', Seat.south)),
      const ConfirmContract(),
    ]);
    final h = await pumpApp(tester, active: s, location: '/deal');
    expect(
      weight(drawnStyle(tester, find.byKey(const Key('contract-headline')))),
      greaterThanOrEqualTo(600),
    );
    expect(
      weight(drawnStyle(tester, find.byKey(const Key('role-dummy')))),
      greaterThanOrEqualTo(600),
    );
    // The current stage is bolder than the other stages.
    expect(
      weight(drawnStyle(tester, find.byKey(const Key('current-stage')))),
      greaterThan(weight(drawnStyle(tester, find.text('Result')))),
    );
    await h.tapKey('finish-play');
    await h.tapKey('result-Made');
    expect(
      weight(drawnStyle(tester, find.byKey(const Key('full-result')))),
      700,
    );
    await h.tapKey('score-deal');
    expect(
      weight(drawnStyle(tester, find.text('Contract points: 120'))),
      greaterThanOrEqualTo(600),
    );
  });

  testWidgets('auction: the player to call stands out', (tester) async {
    final s = run(newSession(settings(bidding: true)), [
      const AdvanceFromStart(),
    ]);
    await pumpApp(tester, active: s, location: '/deal');
    final auction = s.draft!.auction!;
    expect(auction.toCall, Seat.north);
    expect(weight(drawnStyle(tester, find.byKey(const Key('turn')))), 700);
    expect(weight(drawnStyle(tester, find.text('Bob'))), 400);
  });

  testWidgets('demo: the step and the highlighted value are bold', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      location: '/setup/house-rules?preset=standard',
    );
    await h.tap(find.byKey(const Key('group-rubber')));
    await h.tap(
      find.descendant(
        of: find.byKey(const Key('help-rubberTwoNil')),
        matching: find.byIcon(Icons.info_outline),
      ),
    );
    await h.tapKey('show-demo');
    expect(
      weight(drawnStyle(tester, find.byKey(const Key('demo-step')))),
      greaterThanOrEqualTo(600),
    );
    await h.tapKey('demo-next');
    expect(
      weight(drawnStyle(tester, find.text('Rubber bonus: 700'))),
      greaterThanOrEqualTo(600),
    );
  });

  test('emphasis colors have a contrast of at least 4.5:1', () {
    for (final b in Brightness.values) {
      final scheme = buildTheme(b).colorScheme;
      final pairs = <String, (Color, Color)>{
        for (final bg in [scheme.surface, scheme.surfaceContainerLow]) ...{
          'primary on $bg': (scheme.primary, bg),
          'error on $bg': (scheme.error, bg),
          'tertiary on $bg': (scheme.tertiary, bg),
        },
        'undertrick cell': (scheme.onErrorContainer, scheme.errorContainer),
        'made cell': (scheme.onPrimaryContainer, scheme.primaryContainer),
        'overtrick cell': (
          scheme.onTertiaryContainer,
          scheme.tertiaryContainer,
        ),
        'selected undertrick': (scheme.onError, scheme.error),
        'selected made': (scheme.onPrimary, scheme.primary),
        'selected overtrick': (scheme.onTertiary, scheme.tertiary),
      };
      for (final e in pairs.entries) {
        expect(
          contrastRatio(e.value.$1, e.value.$2),
          greaterThanOrEqualTo(4.5),
          reason: '${e.key} ($b)',
        );
      }
    }
  });
}
