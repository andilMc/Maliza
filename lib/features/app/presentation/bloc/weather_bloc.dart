// import 'package:maliza/core/models/weather_day.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:forui/forui.dart';
// import 'package:intl/intl.dart';
// import 'package:maliza/features/app/provider/weather_provider.dart';
// import 'package:provider/provider.dart';

// class WeatherBlock extends StatefulWidget {
//   final WeatherDay? forecast;

//   const WeatherBlock({super.key, required this.forecast});

//   @override
//   State<WeatherBlock> createState() => _WeatherBlockState(day: forecast);
// }

// class _WeatherBlockState extends State<WeatherBlock> {
//   final WeatherDay? day;

//   _WeatherBlockState({required this.day});
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: MediaQuery.of(context).size.width,
//       child: Consumer<WeatherProvider>(
//         builder:
//             (innerContext, provider, _) => FCard(
//               title: Text(
//                 "${day!.dayLong} - ${provider.city}",
//                 style: TextStyle(fontSize: 14),
//               ),
//               subtitle: Text(
//                 "${day!.dayShort} le ${DateFormat('d  MMMM  yyyy', 'fr_FR').format(DateTime.parse(day!.date))}",
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 10),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           children: [
//                             SvgPicture.network(
//                                   day!.dayWeatherIcon,
//                                   width: 45,
//                                   height: 45,
//                                 )
//                                 .animate(
//                                   onPlay:
//                                       (controller) =>
//                                           controller.repeat(reverse: true),
//                                 )
//                                 .scale(
//                                   begin: Offset(1.0, 1.0),
//                                   end: Offset(1.2, 1.2),
//                                   duration: 600.ms,
//                                   curve: Curves.easeInOut,
//                                 ),
//                             Text(
//                               "La Journée",
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               day!.dayWeatherDescription,
//                               textAlign: TextAlign.center,
//                               softWrap: true,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 9),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         width: .1,
//                         height: 80,
//                         color: Colors.black,
//                         margin: EdgeInsets.only(left: 5, right: 5),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Column(
//                           children: [
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.arrow_upward,
//                                   size: 14,
//                                   color: Colors.red,
//                                 ),
//                                 Text(
//                                   "${day?.tempMax} ",
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const Icon(
//                                   Icons.arrow_downward,
//                                   size: 12,
//                                   color: Colors.blue,
//                                 ),
//                                 Text(
//                                   "${day?.tempMin}",
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(
//                                   Icons.wb_sunny,
//                                   size: 10,
//                                   color: Colors.orange,
//                                 ),
//                                 Text(
//                                   "${day?.sunHours}",
//                                   style: TextStyle(fontSize: 9),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               spacing: 8,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(
//                                       Icons.air,
//                                       size: 10,
//                                       color: Colors.blue,
//                                     ),
//                                     Text(
//                                       "${day?.windSpeed}",
//                                       style: TextStyle(fontSize: 9),
//                                     ),
//                                   ],
//                                 ),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(
//                                       Icons.water_drop,
//                                       size: 10,
//                                       color: Colors.blueGrey,
//                                     ),
//                                     Text(
//                                       "${day?.precip}",
//                                       style: TextStyle(fontSize: 9),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         width: .1,
//                         height: 80,
//                         color: Colors.black,
//                         margin: EdgeInsets.only(left: 5, right: 5),
//                       ),
//                       Expanded(
//                         child: Column(
//                           children: [
//                             SvgPicture.network(
//                                   day!.nightWeatherIcon,
//                                   width: 45,
//                                   height: 45,
//                                 )
//                                 .animate(
//                                   onPlay:
//                                       (controller) =>
//                                           controller.repeat(reverse: true),
//                                 )
//                                 .scale(
//                                   begin: Offset(1.0, 1.0),
//                                   end: Offset(1.2, 1.2),
//                                   duration: 600.ms,
//                                   curve: Curves.easeInOut,
//                                 ),
//                             Text(
//                               "La Nuit",
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               day!.nightWeatherDescription,
//                               textAlign: TextAlign.center,
//                               softWrap: true,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 9),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ).animate().fade(duration: 1.seconds),
//       ),
//     );
//   }
// }
