import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maliza/core/error/weather_exception.dart';
import 'package:maliza/core/models/current_weather.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1/current.json';
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<CurrentWeather> getWeatherData({
    required double latitude,
    required double longitude,
    String timezone = 'GMT',
  }) async {
    try {
      final Uri url = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'key': 'e36a6ee5bfa74844aae193819252108',
          'q': "${latitude.toString()},${longitude.toString()}",
          'aqi': 'yes',
        },
      );

      debugPrint('Fetching weather data from: $url');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return CurrentWeather.fromJson(jsonData);
      } else {
        throw WeatherException(
          'Erreur lors de la récupération des données: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is WeatherException) {
        rethrow;
      }
      throw WeatherException('Erreur de connexion: $e', 0);
    }
  }

  void dispose() {
    _client.close();
  }
}
