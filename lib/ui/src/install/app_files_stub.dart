import 'app_files_types.dart';

AppFiles createAppFiles() => const _NoAppFiles();

class _NoAppFiles implements AppFiles {
  const _NoAppFiles();

  @override
  bool get hasOfflineCopy => false;

  @override
  Future<int> offlineSize() async => 0;

  @override
  Future<void> refresh() async {}
}
