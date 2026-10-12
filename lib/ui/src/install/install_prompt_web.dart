import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'install_types.dart';

// The functions that web/index.html defines.
@JS('ibInstallState')
external JSString _ibInstallState();

@JS('ibInstall')
external JSPromise<JSString> _ibInstall();

InstallPrompt createInstallPrompt() => const _WebInstallPrompt();

class _WebInstallPrompt implements InstallPrompt {
  const _WebInstallPrompt();

  @override
  InstallState state() {
    // An older index.html (from a cache) may not define the functions.
    if (!globalContext.has('ibInstallState')) return InstallState.none;
    return switch (_ibInstallState().toDart) {
      'installed' => InstallState.installed,
      'prompt' => InstallState.prompt,
      'ios' => InstallState.ios,
      _ => InstallState.none,
    };
  }

  @override
  Future<bool> install() async {
    if (!globalContext.has('ibInstall')) return false;
    final outcome = await _ibInstall().toDart;
    return outcome.toDart == 'accepted';
  }
}
