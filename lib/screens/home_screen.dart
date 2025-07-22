import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/journal_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/journal_list_item.dart';
import '../utils/themes.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _selectedDate;
  String? _selectedWeather;
  final List<String> _weatherConditions = [
    'Clear', 'Clouds', 'Rain', 'Drizzle', 'Thunderstorm', 'Snow', 'Mist', 'Fog'
  ];

  Weather? _liveWeather;
  bool _isWeatherLoading = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _fetchLiveWeatherWithLocation();
  }

  Future<void> _fetchLiveWeatherWithLocation() async {
    setState(() {
      _isWeatherLoading = true;
      _weatherError = null;
    });
    try {
      Position position = await _determinePosition();
      final weather = await WeatherService().getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _liveWeather = weather;
        _isWeatherLoading = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = 'Failed to fetch live weather: $e';
        _isWeatherLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, journalProvider, _) {
        return Container(
          decoration: getWeatherBackground(_liveWeather),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Weather Journal'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.brightness_6),
                  onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                ),
              ],
            ),
            body: Column(
              children: [
                if (_isWeatherLoading)
                  const LinearProgressIndicator(),
                if (_weatherError != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _weatherError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                // Show current weather and city name
                if (_liveWeather != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Column(
                      children: [
                        Text(
                          _liveWeather!.condition,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _liveWeather!.cityName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildFilterSection(),
                Expanded(
                  child: Consumer<JournalProvider>(
                    builder: (context, journalProvider, child) {
                      if (journalProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (journalProvider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading entries',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                journalProvider.error!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => journalProvider.loadEntries(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final filteredEntries = journalProvider.filterEntries(
                        date: _selectedDate,
                        weatherCondition: _selectedWeather,
                      );

                      if (filteredEntries.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await _fetchLiveWeatherWithLocation();
                          await journalProvider.loadEntries();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            return JournalListItem(
                              entry: entry,
                              onTap: () => _navigateToDetail(entry),
                              onEdit: () => _navigateToEdit(entry),
                              onDelete: () => _showDeleteDialog(entry),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/create'),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Entries',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateFilter(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeatherFilter(),
              ),
            ],
          ),
          if (_selectedDate != null || _selectedWeather != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filters'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Select Date',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedWeather,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      hint: const Text('Weather'),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Weather'),
        ),
        ..._weatherConditions.map((condition) => DropdownMenuItem<String>(
          value: condition,
          child: Text(condition),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedWeather = value;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No journal entries yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by creating your first entry!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create Entry'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedWeather = null;
    });
  }

  void _navigateToDetail(dynamic entry) {
    Navigator.pushNamed(
      context,
      '/detail',
      arguments: entry,
    );
  }

  void _navigateToEdit(dynamic entry) {
    Navigator.pushNamed(
      context,
      '/create',
      arguments: entry,
    );
  }

  void _showDeleteDialog(dynamic entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<JournalProvider>().deleteEntry(entry.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
