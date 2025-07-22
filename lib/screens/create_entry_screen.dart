import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/journal_entry.dart';
import '../models/weather.dart';
import '../providers/journal_provider.dart';
import '../services/weather_service.dart';
import '../widgets/weather_display.dart';

class CreateEntryScreen extends StatefulWidget {
  final JournalEntry? entry; // For editing existing entries

  const CreateEntryScreen({Key? key, this.entry}) : super(key: key);

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  final TextEditingController _textController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  
  Weather? _currentWeather;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entry != null;
    
    if (_isEditing) {
      _textController.text = widget.entry!.text;
      _currentWeather = widget.entry!.weather;
    } else {
      _fetchCurrentWeatherWithLocation();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentWeatherWithLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      Position position = await _determinePosition();
      final weather = await _weatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _currentWeather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch weather: $e';
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchCurrentWeather() async {
    // For edit mode: use the weather already saved with the entry
    if (_isEditing) return;
    await _fetchCurrentWeatherWithLocation();
  }

  Future<void> _saveEntry() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Please enter some text for your journal entry.';
      });
      return;
    }

    if (_currentWeather == null) {
      setState(() {
        _error = 'Weather data is not available. Please try again.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final journalProvider = context.read<JournalProvider>();
      
      if (_isEditing) {
        // Update existing entry
        final updatedEntry = JournalEntry(
          id: widget.entry!.id,
          date: widget.entry!.date,
          text: text,
          weather: _currentWeather!,
          editedAt: DateTime.now(),
        );
        await journalProvider.updateEntry(updatedEntry);
      } else {
        // Create new entry
        final newEntry = JournalEntry(
          id: _generateId(),
          date: DateTime.now(),
          text: text,
          weather: _currentWeather!,
        );
        await journalProvider.addEntry(newEntry);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Entry updated successfully!' : 'Entry created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save entry: $e';
        _isSaving = false;
      });
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'Create Entry'),
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              onPressed: _fetchCurrentWeatherWithLocation,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Weather',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Display Section
            _buildWeatherSection(),
            if (_currentWeather != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  _currentWeather!.cityName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Text Input Section
            Text(
              'Journal Entry',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Write about your day...',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
            const SizedBox(height: 24),
            // Error Display
            if (_error != null) _buildErrorSection(),
            const SizedBox(height: 24),
            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Weather',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_currentWeather != null)
              WeatherDisplay(weather: _currentWeather!)
            else
              Text(
                'Weather data not available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Journal Entry',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Write about your day...',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || _isSaving) ? null : _saveEntry,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Saving...'),
                ],
              )
            : Text(_isEditing ? 'Update Entry' : 'Save Entry'),
      ),
    );
  }
}
