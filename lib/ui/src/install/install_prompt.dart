import 'install_prompt_stub.dart'
    if (dart.library.js_interop) 'install_prompt_web.dart'
    as platform;
import 'install_types.dart';

export 'install_types.dart';

/// The install prompt of this platform: the browser version on web, and a
/// stub everywhere else.
InstallPrompt createInstallPrompt() => platform.createInstallPrompt();
