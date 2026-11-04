import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  static const _darkKey = 'dark_mode';

  final SharedPreferences _prefs;
  bool _darkMode;

  SettingsStore(this._prefs) : _darkMode = _prefs.getBool(_darkKey) ?? false;

  bool get darkMode => _darkMode;

  set darkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    _prefs.setBool(_darkKey, value);
    notifyListeners();
  }
}
