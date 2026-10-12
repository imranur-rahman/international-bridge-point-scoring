/// Whether and how the app can be installed (design decision D3).
enum InstallState {
  /// The app runs installed: from the home screen or as a phone build.
  installed,

  /// The browser offers an install prompt.
  prompt,

  /// iPhone or iPad: the user installs with Share → Add to Home Screen.
  ios,

  /// No install is possible here.
  none,
}

abstract interface class InstallPrompt {
  InstallState state();

  /// Shows the install prompt of the browser. Returns true when the user
  /// accepts it.
  Future<bool> install();
}
