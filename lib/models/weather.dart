import 'package:hive/hive.dart';
part 'weather.g.dart';

@HiveType(typeId: 1)
class Weather extends HiveObject {
  @HiveField(0)
  final String condition;
  @HiveField(1)
  final double temperature;
  @HiveField(2)
  final String icon;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String cityName;

  Weather({
    required this.condition,
    required this.temperature,
    required this.icon,
    required this.description,
    required this.cityName,
  });
}
