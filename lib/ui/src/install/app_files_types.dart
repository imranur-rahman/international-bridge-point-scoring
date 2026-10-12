/// The offline copy of the web app (design decision D5).
abstract interface class AppFiles {
  /// False on Android and iOS builds, which have no offline copy.
  bool get hasOfflineCopy;

  /// The size of the offline copy in bytes.
  Future<int> offlineSize();

  /// Deletes the offline copy and reloads the app from the network.
  Future<void> refresh();
}
