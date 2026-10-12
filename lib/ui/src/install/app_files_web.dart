import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'app_files_types.dart';

// The functions that web/index.html defines.
@JS('ibOfflineSize')
external JSPromise<JSNumber> _ibOfflineSize();

@JS('ibRefreshAppFiles')
external JSPromise<JSAny?> _ibRefreshAppFiles();

AppFiles createAppFiles() => const _WebAppFiles();

class _WebAppFiles implements AppFiles {
  const _WebAppFiles();

  @override
  bool get hasOfflineCopy => globalContext.has('ibRefreshAppFiles');

  @override
  Future<int> offlineSize() async {
    if (!globalContext.has('ibOfflineSize')) return 0;
    return (await _ibOfflineSize().toDart).toDartInt;
  }

  @override
  Future<void> refresh() async {
    if (!hasOfflineCopy) return;
    await _ibRefreshAppFiles().toDart;
  }
}
