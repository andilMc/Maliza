import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:maliza/core/models/assets.dart';
import 'package:maliza/features/app/provider/route_navigation_provider.dart';
import 'package:maliza/features/app/provider/weather_provider.dart';
import 'package:provider/provider.dart';

class Weather extends StatefulWidget {
  Weather({Key? key}) : super(key: key);

  @override
  _WeatherState createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  int textColor = 0xF8FFFFFF;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherProvider = context.read<WeatherProvider>();
      weatherProvider.startAutoRefresh();
      weatherProvider.refreshTimes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.vibrate();
        var routeProvider = context.read<RouteNavigationProvider>();
        routeProvider.goToWeather();
      },
      child: Consumer<WeatherProvider>(
        builder: (buildContext, weatherProvider, _) {
          if (weatherProvider.isLoading ||
              weatherProvider.currentWeather == null) {
            return FLabel(
              label: Text("La Météo"),
              axis: Axis.vertical,
              child: Container(
                height: 90,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.imagesLoadw),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }
          return FLabel(
            label: Text("La Météo"),
            axis: Axis.vertical,
            child: Container(
              height: 90,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    weatherProvider.currentWeather?.isDay ?? true
                        ? Assets.imagesDay
                        : Assets.imagesNight,
                  ),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  spacing: 14,
                  children: [
                    Image.network(
                          weatherProvider.currentWeather?.iconUrl ??
                              Assets.imageUnknown,
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
                    Column(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "🌡️${weatherProvider.currentWeather?.temperature ?? '--'} °C",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 25,
                            color: Color(textColor),
                          ),
                        ),
                        Text(
                          weatherProvider.currentDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(textColor),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        spacing: 5,
                        children: [
                          Text(
                            "📍",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                              color: Color(textColor),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${weatherProvider.currentWeather?.region} - ${weatherProvider.currentWeather?.name}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(textColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ).animate().fade(duration: Duration(milliseconds: 500)),
    );
  }
}
