class ApiConfig {
  static const String _defaultNgrokUrl = 'https://dawdlingly-pseudoinsane-pa.ngrok-free.dev';
  static String? _customBaseUrl;

  /// Default API base URL - defaults to active ngrok URL so physical devices and emulators connect seamlessly
  static String get defaultBaseUrl => _defaultNgrokUrl;

  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  static set baseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
  }

  static void reset() {
    _customBaseUrl = null;
  }
}
