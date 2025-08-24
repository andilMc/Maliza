class CurrentWeather {
  String region;
  String name;
  final double temperature;
  final String weatherDescription;
  final String iconUrl;
  final bool isDay;
  final double windSpeed;
  final double humidity;
  final double precip;

  CurrentWeather({
    required this.region,
    required this.name,
    required this.temperature,
    required this.weatherDescription,
    required this.iconUrl,
    required this.isDay,
    required this.windSpeed,
    required this.precip,
    required this.humidity,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    // Récupère l'URL originale
    String originalIconUrl = json['current']['condition']['icon'] as String;

    // Modifie la taille et ajoute "http:" devant si nécessaire
    String iconUrl = originalIconUrl.startsWith('//')
        ? 'http:${originalIconUrl.replaceAll('64x64', '128x128')}'
        : originalIconUrl.replaceAll('64x64', '128x128');

    return CurrentWeather(
      region: "",
      name: "",
      temperature: (json['current']['temp_c'] as num).toDouble(),
      weatherDescription: json['current']['condition']['text'] as String,
      iconUrl: iconUrl,
      isDay: json['current']['is_day'] == 0 ? false : true,
      windSpeed: (json['current']['wind_kph'] as num).toDouble(),
      humidity: (json['current']['humidity'] as num).toDouble(),
      precip: (json['current']['precip_mm'] as num).toDouble(),
    );
  }
}
