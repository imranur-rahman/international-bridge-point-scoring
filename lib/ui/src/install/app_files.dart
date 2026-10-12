import 'app_files_stub.dart'
    if (dart.library.js_interop) 'app_files_web.dart'
    as platform;
import 'app_files_types.dart';

export 'app_files_types.dart';

/// The offline copy of this platform: the browser version on web, and a
/// stub everywhere else.
AppFiles createAppFiles() => platform.createAppFiles();
