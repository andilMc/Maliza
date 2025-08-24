import 'package:maliza/core/api/remote_database_helper.dart';
import 'package:maliza/core/models/api_result.dart';
import 'package:maliza/core/models/user.dart';
import 'package:flutter/material.dart';
import 'package:maliza/core/data/account_cache.dart';

enum AuthResult { success, cacheFailed, invalid, error, noConnexion }

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? success;
  bool _isInitial = false;

  bool get isInitial => _isInitial;
  set isInitial(bool value) {
    _isInitial = value;
    if (!value) {
      notifyListeners();
    }
  }

  Future<void> _updateState({
    bool? loading,
    String? error,
    String? success,
  }) async {
    if (loading != null) isLoading = loading;
    this.error = error;
    this.success = success;

    notifyListeners();
  }

  /// Méthode pour gérer le login
  Future<AuthResult> login(String email, String password) async {
    _updateState(loading: true, error: null, success: null);

    try {
      User user = User(email: email, password: password);
      ApiResult<User> resp = await RemoteDatabaseHelper.login(user);
      debugPrint("=========================");
      debugPrint("${resp.data}");
      debugPrint("=========================");

      if (resp.data is User) {
        final saved = await AccountCache.cachedLoginedUser(resp.data!);
        return saved ? AuthResult.success : AuthResult.cacheFailed;
      } else {
        if (resp.errorMessage == "Erreur de connexion réseau") {
          return AuthResult.noConnexion;
        }
        return AuthResult.invalid;
      }
    } catch (e) {
      debugPrint("Login error: $e");
      return AuthResult.error;
    } finally {
      _updateState(loading: false);
    }
  }

  /// Méthode pour gérer l'inscription
  Future<bool> register(String email, String password) async {
    _updateState(loading: true, error: null, success: null);

    try {
      User user = User(email: email, password: password);

      final apiResult = await RemoteDatabaseHelper.register(user);

      if (!apiResult.isSuccess) {
        _updateState(error: apiResult.errorMessage, loading: false);
        return false;
      }

      _updateState(success: apiResult.data, loading: false);
      _isInitial = false;
      return true;
    } catch (e) {
      debugPrint("Register error: $e");
      _updateState(error: "Erreur réseau", loading: false);
      return false;
    }
  }
}
