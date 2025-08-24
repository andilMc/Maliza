import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:maliza/core/error/network_exception.dart';
import 'package:maliza/core/models/network_error_type.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkClient {
  static final http.Client _client = http.Client();

  // Configuration
  static const Duration _defaultTimeout = Duration(seconds: 10);

  NetworkClient();

  /// Méthode pour nettoyer les ressources
  static void dispose() {
    _client.close();
  }

  static Future<dynamic> post(
    String url, {
    Map<String, String>? headers,
    required Map<String, dynamic> body,
  }) async {
    try {
      // Validation de l'URL
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.scheme.startsWith('http')) {
        throw NetworkException(
          message: 'URL invalide: $url',
          type: NetworkErrorType.invalidUrl,
        );
      }

      // Headers par défaut
      final finalHeaders = {'Content-Type': 'application/json', ...?headers};

      // Encodage du body
      String encodedBody;

      try {
        encodedBody = jsonEncode(body);
      } catch (e) {
        throw NetworkException(
          message: 'Impossible d\'encoder les données JSON',
          type: NetworkErrorType.parseError,
        );
      }

      // Requête HTTP avec timeout
      final response = await _client
          .post(uri, headers: finalHeaders, body: encodedBody)
          .timeout(_defaultTimeout);
      debugPrint("=========================");
      debugPrint(response.body);
      debugPrint("=========================");
      // Gestion des codes de statut
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parsing sécurisé du JSON
        if (response.body.isEmpty) {
          return <String, dynamic>{};
        }
        try {
          return jsonDecode(response.body);
        } on FormatException {
          throw NetworkException(
            message: 'Réponse serveur invalide (JSON malformé)',
            statusCode: response.statusCode,
            responseBody: response.body,
            type: NetworkErrorType.serverError,
          );
        }
      } else {
        // Messages d'erreur selon le code de statut
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Requête invalide';
            break;
          case 401:
            errorMessage = 'Non autorisé - Veuillez vous reconnecter';
            break;
          case 403:
            errorMessage = 'Accès interdit';
            break;
          case 404:
            errorMessage = 'Ressource non trouvée';
            break;
          case 429:
            errorMessage = 'Trop de requêtes - Veuillez patienter';
            break;
          case 500:
            errorMessage = 'Erreur interne du serveur';
            break;
          case 503:
            errorMessage = 'Service temporairement indisponible';
            break;
          default:
            errorMessage = 'Erreur HTTP ${response.statusCode}';
        }

        throw NetworkException(
          message: errorMessage,
          statusCode: response.statusCode,
          responseBody: response.body,
          type: NetworkErrorType.clientError,
        );
      }
    } on TimeoutException {
      throw NetworkException(
        message: 'Délai de connexion dépassé',
        type: NetworkErrorType.timeout,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Erreur de connexion: ${e.message}',
        type: NetworkErrorType.noConnection,
      );
    } on NetworkException {
      rethrow; // Re-lancer nos exceptions personnalisées
    } catch (e) {
      if (kDebugMode) {
        debugPrint("===========HTTP-ERROR==============");
        debugPrint(e.toString());
        debugPrint("===========HTTP-ERROR==============");
      }
      throw NetworkException(
        message: 'Erreur réseau: ${e.toString()}',
        type: NetworkErrorType.unknown,
      );
    }
  }
}
