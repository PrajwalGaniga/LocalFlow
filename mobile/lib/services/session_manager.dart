import 'package:flutter/foundation.dart';
import '../models/provider.dart';
import '../models/consumer.dart';

enum UserRole { provider, consumer }

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  UserRole? _role;
  Provider? _currentProvider;
  List<Provider> _availableProviderProfiles = [];
  Consumer? _currentConsumer;

  UserRole? get role => _role;
  Provider? get currentProvider => _currentProvider;
  List<Provider> get availableProviderProfiles => _availableProviderProfiles;
  Consumer? get currentConsumer => _currentConsumer;

  bool get isLoggedIn =>
      (_role == UserRole.provider && _currentProvider != null) ||
      (_role == UserRole.consumer && _currentConsumer != null);

  String get displayName {
    if (_role == UserRole.provider) return _currentProvider?.name ?? 'Provider';
    if (_role == UserRole.consumer) return _currentConsumer?.name ?? 'Consumer';
    return 'Guest';
  }

  String get displayPhone {
    if (_role == UserRole.provider) return _currentProvider?.phone ?? '';
    if (_role == UserRole.consumer) return _currentConsumer?.phone ?? '';
    return '';
  }

  void selectRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void loginAsProvider(Provider provider, [List<Provider>? allProfiles]) {
    _role = UserRole.provider;
    _currentProvider = provider;
    _availableProviderProfiles = allProfiles ?? [provider];
    _currentConsumer = null;
    notifyListeners();
  }

  void setAvailableProviderProfiles(List<Provider> profiles) {
    _availableProviderProfiles = profiles;
    if (_currentProvider != null) {
      final match = profiles.where((p) => p.id == _currentProvider!.id).firstOrNull;
      if (match != null) {
        _currentProvider = match;
      }
    }
    notifyListeners();
  }

  void switchProviderProfile(Provider provider) {
    _currentProvider = provider;
    notifyListeners();
  }

  void loginAsConsumer(Consumer consumer) {
    _role = UserRole.consumer;
    _currentConsumer = consumer;
    _currentProvider = null;
    _availableProviderProfiles = [];
    notifyListeners();
  }

  void logout() {
    _role = null;
    _currentProvider = null;
    _availableProviderProfiles = [];
    _currentConsumer = null;
    notifyListeners();
  }
}
