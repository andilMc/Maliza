import 'dart:async';

import 'package:maliza/core/api/api_endpoints.dart';
import 'package:maliza/core/error/api_exception.dart';
import 'package:maliza/core/models/api_result.dart';
import 'package:maliza/core/models/todo.dart';
import 'package:maliza/core/models/user.dart';
import 'package:maliza/core/network/network_client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RemoteDatabaseHelper {
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const String _networkErrorMessage = 'Erreur de connexion réseau';
  static const String _timeoutErrorMessage = 'La requête a expiré';
  static const String _unknownErrorMessage =
      'Une erreur inconnue s\'est produite';

  static Future<Map<String, dynamic>> _makeApiCall(
    Future<Map<String, dynamic>> Function() apiCall,
  ) async {
    try {
      return await apiCall().timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException(message: _timeoutErrorMessage);
    } catch (e) {
      debugPrint('Erreur API: $e');
      throw ApiException(
        message: e is ApiException ? e.message : _networkErrorMessage,
      );
    }
  }

  /// Validation des paramètres d'authentification
  static void _validateAuthParams(User user) {
    if (user.email.trim().isEmpty) {
      throw ApiException(message: 'L\'email ne peut pas être vide');
    }
    if (user.password!.trim().isEmpty) {
      throw ApiException(message: 'Le mot de passe ne peut pas être vide');
    }
  }

  static Future<ApiResult<User>> login(User user) async {
    try {
      _validateAuthParams(user);

      final response = await _makeApiCall(() async {
        final res = await NetworkClient.post(
          ApiEndpoints.login,
          body: {
            'email': user.email.trim().toLowerCase(),
            'password': user.password,
          },
        );
        return Map<String, dynamic>.from(res);
      });

      if (response['data'] == null) {
        return const ApiResult.error(message: 'Réponse invalide du serveur');
      }

      final data = response['data'] as Map<String, dynamic>;
      final accountId = data['account_id'];
      final email = data['email'];

      if (accountId == null || email == null) {
        return const ApiResult.error(
          message: 'Données utilisateur incomplètes',
        );
      }

      final loggedUser = User(
        id: accountId is int ? accountId : int.tryParse(accountId.toString()),
        email: email.toString(),
      );

      return ApiResult.success(loggedUser);
    } on ApiException catch (e) {
      return ApiResult.error(message: e.message, code: e.errorCode);
    } catch (e) {
      debugPrint('Erreur login: $e');
      return const ApiResult.error(message: 'Erreur lors de la connexion');
    }
  }

  static Future<ApiResult<String>> register(User user) async {
    try {
      _validateAuthParams(user);

      final response = await _makeApiCall(() async {
        final res = await NetworkClient.post(
          ApiEndpoints.register,
          body: {
            'email': user.email.trim().toLowerCase(),
            'password': user.password,
          },
        );
        return Map<String, dynamic>.from(res);
      });

      if (response['error'] != null) {
        final errorMessage = response['error'].toString();
        return ApiResult.error(message: errorMessage);
      }

      if (response['data'] != null) {
        final successMessage = response['data'].toString();
        return ApiResult.success(successMessage);
      }

      return const ApiResult.error(message: _unknownErrorMessage);
    } on ApiException catch (e) {
      return ApiResult.error(message: e.message, code: e.errorCode);
    } catch (e) {
      debugPrint('Erreur inscription: $e');
      return const ApiResult.error(message: 'Erreur lors de l\'inscription');
    }
  }

  static void _validateTodoData(Map<String, dynamic> todo) {
    if (todo['todo'] == null || todo['todo'].toString().trim().isEmpty) {
      throw ApiException(message: 'Le titre de la tâche ne peut pas être vide');
    }

    if (todo['date'] == null || todo['date'].toString().trim().isEmpty) {
      throw ApiException(message: 'La date de la tâche est requise');
    }

    try {
      DateFormat format = DateFormat("yyyy-M-d H:mm");
      format.parse(todo['date'].toString());
    } catch (e) {
      throw ApiException(message: 'Format de date invalide');
    }
  }

  static Future<ApiResult<String>> insertTodo(Map<String, dynamic> todo) async {
    try {
      _validateTodoData(todo);

      final cleanTodo = Map<String, dynamic>.from(todo);
      cleanTodo['todo'] =
          "${cleanTodo['todo_id']}@${cleanTodo['todo'].toString().trim()}";
      final result = await _makeApiCall(() async {
        final res = await NetworkClient.post(
          ApiEndpoints.insertTodo,
          body: cleanTodo,
        );
        return Map<String, dynamic>.from(res);
      });

      if (result['error'] != null) {
        final errorMessage = result['error'].toString();
        return ApiResult.error(message: errorMessage);
      }

      final successMessage =
          result['data']?.toString() ?? 'Tâche créée avec succès';
      return ApiResult.success(successMessage);
    } on ApiException catch (e) {
      return ApiResult.error(message: e.message, code: e.errorCode);
    } catch (e) {
      debugPrint('Erreur insertion todo: $e');
      return const ApiResult.error(
        message: 'Erreur lors de la création de la tâche',
      );
    }
  }

  static Future<ApiResult<List<Todo>>> getAllTodos(int accountId) async {
    try {
      if (accountId <= 0) {
        throw ApiException(message: 'ID utilisateur invalide');
      }

      final response = await _makeApiCall(() async {
        final res = await NetworkClient.post(
          ApiEndpoints.todos,
          body: {'account_id': accountId},
        );
        return Map<String, dynamic>.from(res);
      });

      if (response['error'] != null) {
        final errorMessage = response['error'].toString();
        return ApiResult.error(message: errorMessage);
      }

      if (response['data'] == null) {
        return const ApiResult.success([]);
      }

      final List<Todo> todos = [];
      final data = response['data'];

      if (data is List) {
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              final todo = Todo.fromMap(item);
              todos.add(todo);
            }
          } catch (e) {
            debugPrint('Erreur conversion todo: $e');
          }
        }
      }

      return ApiResult.success(todos);
    } on ApiException catch (e) {
      return ApiResult.error(message: e.message, code: e.errorCode);
    } catch (e) {
      debugPrint('Erreur getAllTodos: $e');
      return const ApiResult.error(
        message: 'Erreur lors du chargement des tâches',
      );
    }
  }

  static Future<ApiResult<String>> updateTodo(Map<String, dynamic> todo) async {
    try {
      _validateTodoData(todo);

      if (todo['todo_id'] == null) {
        throw ApiException(message: 'ID de la tâche manquant');
      }

      // Nettoyage des données
      final cleanTodo = Map<String, dynamic>.from(todo);
      cleanTodo['todo'] = (cleanTodo['todo'].toString().trim())
          .replaceAll(r'\', r'\\')
          .replaceAll("'", r"\'")
          .replaceAll('"', r'\"')
          .replaceAll('\n', r'\n')
          .replaceAll('\r', r'\r')
          .replaceAll('\t', r'\t')
          .replaceAll('\0', r'\0');
      ;
      final result = await _makeApiCall(
        () async => Map<String, dynamic>.from(
          await NetworkClient.post(ApiEndpoints.updateTodo, body: cleanTodo),
        ),
      );

      if (result['error'] != null) {
        final errorMessage = result['error'].toString();
        return ApiResult.error(message: errorMessage);
      }

      final successMessage =
          result['data']?.toString() ?? 'Tâche mise à jour avec succès';
      return ApiResult.success(successMessage);
    } on ApiException catch (e) {
      return ApiResult.error(message: e.message, code: e.errorCode);
    } catch (e) {
      debugPrint('Erreur update todo: $e');
      return const ApiResult.error(
        message: 'Erreur lors de la mise à jour de la tâche',
      );
    }
  }

  static Future<ApiResult<String>> deleteTodo(int todoId) async {
    try {
      if (todoId <= 0) {
        throw ApiException(message: 'ID de tâche invalide');
      }

      final result = await _makeApiCall(
        () async => Map<String, dynamic>.from(
          await NetworkClient.post(
            ApiEndpoints.deleteTodo,
            body: {'todo_id': todoId},
          ),
        ),
      );

      if (result['error'] != null) {
        final errorMessage = result['error'].toString();
        return ApiResult.error(message: errorMessage);
      }

      final successMessage =
          result['data']?.toString() ?? 'Tâche supprimée avec succès';
      return ApiResult.success(successMessage);
    } on ApiException catch (e) {
      return ApiResult.error(message: e.message, code: e.errorCode);
    } catch (e) {
      debugPrint('Erreur delete todo: $e');
      return const ApiResult.error(
        message: 'Erreur lors de la suppression de la tâche',
      );
    }
  }
}
