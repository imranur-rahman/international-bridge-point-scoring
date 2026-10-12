import 'package:bridge_scorekeeper/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

class FakeInstallPrompt implements InstallPrompt {
  FakeInstallPrompt(this.current, {this.accept = true});

  InstallState current;
  final bool accept;
  int prompts = 0;

  @override
  InstallState state() => current;

  @override
  Future<bool> install() async {
    prompts++;
    if (accept) current = InstallState.installed;
    return accept;
  }
}

void main() {
  testWidgets('install in Chrome', (tester) async {
    final fake = FakeInstallPrompt(InstallState.prompt);
    final h = await pumpApp(tester, installPrompt: fake);
    expect(find.text('Install IB Scoring'), findsOneWidget);
    await h.tapKey('install');
    expect(fake.prompts, 1);
    // After the install, the action hides.
    expect(find.byKey(const Key('install')), findsNothing);
  });

  testWidgets('a dismissed prompt keeps nothing to show', (tester) async {
    final fake = FakeInstallPrompt(InstallState.prompt, accept: false);
    final h = await pumpApp(tester, installPrompt: fake);
    await h.tapKey('install');
    expect(fake.prompts, 1);
  });

  testWidgets('iPhone guide', (tester) async {
    final fake = FakeInstallPrompt(InstallState.ios);
    final h = await pumpApp(tester, installPrompt: fake);
    await h.tapKey('install');
    expect(find.byKey(const Key('ios-install-guide')), findsOneWidget);
    expect(
      find.textContaining('Tap Share, then Add to Home Screen'),
      findsOneWidget,
    );
    expect(fake.prompts, 0);
  });

  testWidgets('installed app shows no install action', (tester) async {
    await pumpApp(
      tester,
      installPrompt: FakeInstallPrompt(InstallState.installed),
    );
    expect(find.byKey(const Key('install')), findsNothing);
  });

  testWidgets('a prompt that comes late shows the action', (tester) async {
    final fake = FakeInstallPrompt(InstallState.none);
    await pumpApp(tester, installPrompt: fake);
    expect(find.byKey(const Key('install')), findsNothing);
    fake.current = InstallState.prompt;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('install')), findsOneWidget);
  });

  testWidgets('no action where the browser offers none', (tester) async {
    await pumpApp(tester, installPrompt: FakeInstallPrompt(InstallState.none));
    await tester.pump(const Duration(seconds: 12));
    expect(find.byKey(const Key('install')), findsNothing);
  });

  testWidgets('a failed prompt hides the action', (tester) async {
    final fake = _FailingPrompt();
    final h = await pumpApp(tester, installPrompt: fake);
    await h.tapKey('install');
    expect(find.byKey(const Key('install')), findsNothing);
  });
}

class _FailingPrompt implements InstallPrompt {
  InstallState current = InstallState.prompt;

  @override
  InstallState state() => current;

  @override
  Future<bool> install() async {
    // The browser used its prompt and then refused it.
    current = InstallState.none;
    throw StateError('The browser refused the prompt');
  }
}
