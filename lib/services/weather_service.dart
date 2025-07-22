import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = '532524daedd0776b37b7cda01238f704'; 
  
  // Default location (can be updated to use device location)
  static const double _defaultLat = 40.7128; // New York
  static const double _defaultLon = -74.0060;

  /// Fetch current weather for a specific location
  Future<Weather> getCurrentWeather({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final lat = latitude ?? _defaultLat;
      final lon = longitude ?? _defaultLon;
      
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather data: $e');
    }
  }

  /// Fetch weather by city name
  Future<Weather> getWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=${Uri.encodeComponent(cityName)}&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      } else if (response.statusCode == 404) {
        throw Exception('City not found: $cityName');
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather data: $e');
    }
  }

  /// Parse weather data from API response
  Weather _parseWeatherData(Map<String, dynamic> data) {
    print('OpenWeatherMap API response: $data'); // Debug print
    final weather = data['weather'][0];
    final main = data['main'];
    final cityName = data['name'] ?? 'Unknown Location';
    
    return Weather(
      condition: weather['main'] ?? 'Unknown',
      temperature: (main['temp'] as num).toDouble(),
      icon: weather['icon'] ?? '01d',
      description: weather['description'] ?? 'Unknown',
      cityName: cityName,
    );
  }

  /// Get weather icon URL
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  /// Get weather condition emoji (for UI display)
  String getWeatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}
