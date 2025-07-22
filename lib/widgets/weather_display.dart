import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherDisplay extends StatelessWidget {
  final Weather weather;
  final bool showDetails;
  final double? iconSize;
  final TextStyle? textStyle;

  const WeatherDisplay({
    super.key,
    required this.weather,
    this.showDetails = true,
    this.iconSize,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final weatherService = WeatherService();
    final emoji = weatherService.getWeatherEmoji(weather.condition);
    final defaultTextStyle = textStyle ?? Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: iconSize ?? 24),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${weather.temperature.round()}°C',
              style: defaultTextStyle?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: (defaultTextStyle.fontSize ?? 14) + 2,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: 2),
              Text(
                weather.condition,
                style: defaultTextStyle?.copyWith(
                  fontSize: (defaultTextStyle.fontSize ?? 14) - 2,
                  color: defaultTextStyle.color?.withOpacity(0.7),
                ),
              ),
              if (weather.description != weather.condition) ...[
                const SizedBox(height: 1),
                Text(
                  weather.description,
                  style: defaultTextStyle?.copyWith(
                    fontSize: (defaultTextStyle.fontSize ?? 14) - 3,
                    color: defaultTextStyle.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }
}

class WeatherDisplayCompact extends StatelessWidget {
  final Weather weather;
  final double? iconSize;

  const WeatherDisplayCompact({
    super.key,
    required this.weather,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final weatherService = WeatherService();
    final emoji = weatherService.getWeatherEmoji(weather.condition);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: iconSize ?? 20),
        ),
        const SizedBox(width: 4),
        Text(
          '${weather.temperature.round()}°',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
