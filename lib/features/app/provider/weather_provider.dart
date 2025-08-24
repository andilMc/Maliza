import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:maliza/core/api/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maliza/core/models/current_weather.dart';

class WeatherProvider extends ChangeNotifier {
  final _weatherService = WeatherService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Timer? _timer;
  double latitude = 14.6937;
  double longitude = -17.4441;
  CurrentWeather? currentWeather;
  String currentDate = '';
  String currentDateFull = '';

  Future<void> loadWeather(double latitude, double longitude) async {
    currentWeather = await _weatherService.getWeatherData(
      latitude: latitude,
      longitude: longitude,
    );
    Placemark placemark = (await placemarkFromCoordinates(
      latitude,
      longitude,
    )).first;

    currentWeather?.region = placemark.locality!;
    currentWeather?.name = placemark.subLocality!;

    notifyListeners();
  }

  void refreshTimes() {
    final format = DateFormat("EEEE, H:mm", 'fr_FR');
    final formatFull = DateFormat("EEEE, le d MMMM yyyy", 'fr_FR');

    Timer.periodic(Duration(seconds: 1), (_) {
      currentDate = format.format(DateTime.now());
      currentDate = currentDate[0].toUpperCase() + currentDate.substring(1);
      currentDateFull = formatFull.format(DateTime.now());
      currentDateFull =
          currentDateFull[0].toUpperCase() + currentDateFull.substring(1);
      notifyListeners();
    });
  }

  void startAutoRefresh() {
    _isLoading = true;
    _getCurentLocation();
    loadWeather(latitude, longitude);
    _timer?.cancel();
    _isLoading = false;
    _timer = Timer.periodic(Duration(seconds: 3), (_) {
      _getCurentLocation();
      loadWeather(latitude, longitude);
    });
  }

  Future<void> _getCurentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Permission localisation refusée");
          // Use default Dakar coordinates
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Permission refusée définitivement. Aller dans paramètres.");
        // Use default Dakar coordinates
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      latitude = position.latitude;
      longitude = position.longitude;

      notifyListeners();
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
