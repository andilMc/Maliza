import 'package:shared_preferences/shared_preferences.dart';
import 'package:maliza/core/models/user.dart';

class AccountCache {
  static final _sharedPreferences = SharedPreferencesAsync();

  static Future<bool?> isLogined() {
    return _sharedPreferences.getBool("isLogin");
  }

  static Future<bool> cachedLoginedUser(User usr) async {
    try {
      _sharedPreferences.setInt('account_id', usr.id!);
      _sharedPreferences.setString("email", usr.email);
      _sharedPreferences.setBool("isLogin", true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearLoginedUser() async {
    try {
      _sharedPreferences.setInt('account_id', 0);
      _sharedPreferences.setString("email", '');
      _sharedPreferences.setBool("isLogin", false);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<int?> getCurrentAccountId() {
    return _sharedPreferences.getInt('account_id');
  }

  static Future<String> getCurrentAccountEmail() async {
    return await _sharedPreferences.getString('email') as String;
  }
}
