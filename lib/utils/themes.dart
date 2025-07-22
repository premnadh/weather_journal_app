import 'package:flutter/material.dart';
import '../models/weather.dart';

BoxDecoration getWeatherBackground(Weather? weather) {
  final condition = weather?.condition.toLowerCase() ?? '';
  switch (condition) {
    case 'rain':
    case 'drizzle':
    case 'thunderstorm':
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF616161), Color(0xFF90A4AE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    case 'clear':
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF81D4FA), Color(0xFFFFF176)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    case 'clouds':
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB0BEC5), Color(0xFFECEFF1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    case 'snow':
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    default:
      return const BoxDecoration(
        color: Colors.blueGrey,
      );
  }
}
