import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:maliza/core/models/assets.dart';
import 'package:maliza/features/app/provider/weather_provider.dart';
import 'package:provider/provider.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Color? textColor = Color(0xF8FFFFFF);

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (buildContext, weatherProvider, _) {
        if (weatherProvider.isLoading ||
            weatherProvider.currentWeather == null) {
          return Padding(
            padding: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      image: DecorationImage(
                        image: AssetImage(Assets.imagesLoadw),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    image: DecorationImage(
                      image: AssetImage(
                        weatherProvider.currentWeather?.isDay ?? true
                            ? Assets.imagesDay
                            : Assets.imagesNight,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Image.network(
                                weatherProvider.currentWeather?.iconUrl ??
                                    Assets.imageUnknown,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                              .animate(onPlay: (c) => c.loop())
                              .scale(
                                begin: Offset(1, 1),
                                end: Offset(1.1, 1.1),
                                duration: Duration(milliseconds: 1000),
                              )
                              .then(curve: Curves.easeIn)
                              .scale(
                                begin: Offset(1.1, 1.1),
                                end: Offset(1, 1),
                                duration: Duration(milliseconds: 1000),
                              ),
                          Text(
                            "🌡️${weatherProvider.currentWeather?.temperature ?? '--'}°C",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 35,
                              color: textColor,
                            ),
                          ),
                          Text(
                            weatherProvider.currentDateFull,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          Text(
                            weatherProvider
                                    .currentWeather
                                    ?.weatherDescription ??
                                '--',
                            style: TextStyle(
                              // fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  weatherProvider.currentWeather?.isDay ?? true
                                  ? Color(0x930D121A)
                                  : Color.fromARGB(108, 149, 189, 255),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    'Détails Météorologiques',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                _buildDetailRow(
                                  '🌡️ Température',
                                  '${weatherProvider.currentWeather?.temperature ?? '--'}°C',
                                ),
                                _buildDetailRow(
                                  '💨 Vent',
                                  '${weatherProvider.currentWeather?.windSpeed ?? '--'}km/h',
                                ),
                                _buildDetailRow(
                                  '💧 Humidité',
                                  '${weatherProvider.currentWeather?.humidity ?? '--'}%',
                                ),
                                _buildDetailRow(
                                  '☔ précipités',
                                  '${weatherProvider.currentWeather?.precip ?? '--'}mm',
                                ),
                                _buildDetailRow(
                                  '🏙️ Ville',
                                  '${weatherProvider.currentWeather?.region} - ${weatherProvider.currentWeather?.name}',
                                ),
                                _buildDetailRow(
                                  '📅 Date',
                                  weatherProvider.currentDate,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            weatherProvider.currentWeather?.name ?? '--',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
