import 'install_types.dart';

/// Not a browser: Android and iOS builds, and tests. The app is installed
/// already, or no install is possible.
InstallPrompt createInstallPrompt() => const _NoInstallPrompt();

class _NoInstallPrompt implements InstallPrompt {
  const _NoInstallPrompt();

  @override
  InstallState state() => InstallState.none;

  @override
  Future<bool> install() async => false;
}
