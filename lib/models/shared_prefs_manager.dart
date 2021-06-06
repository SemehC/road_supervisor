import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsManager {
  static late SharedPreferences _prefs;

  static initializeSharedPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool getBool({String key = "", bool defaultVal = true}) {
    return _prefs.getBool(key) ?? defaultVal;
  }

  static setInt({String key = "", int val = 0}) {
    return _prefs.setInt(key, val);
  }

  static int getInt({String key = "", int defaultVal = 0}) {
    return _prefs.getInt(key) ?? defaultVal;
  }

  static String getString({String key = "", String defaultVal = ""}) {
    return _prefs.getString(key) ?? defaultVal;
  }

  static setString({String key = "", String val = ""}) async {
    await _prefs.setString(key, val);
  }

  static setBool({String key = "", bool val = true}) async {
    print("$key : $val");
    await _prefs.setBool(key, val);
  }
}
