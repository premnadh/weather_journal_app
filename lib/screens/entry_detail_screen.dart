import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../widgets/weather_display.dart';

class EntryDetailScreen extends StatelessWidget {
  final JournalEntry? entry;

  const EntryDetailScreen({super.key, this.entry});

  @override
  Widget build(BuildContext context) {
    // If no entry is passed, try to get it from route arguments
    final journalEntry = entry ?? (ModalRoute.of(context)?.settings.arguments as JournalEntry?);
    
    if (journalEntry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Entry Detail')),
        body: const Center(
          child: Text('Entry not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Detail'),
        actions: [
          IconButton(
            onPressed: () => _editEntry(context, journalEntry),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Entry',
          ),
          IconButton(
            onPressed: () => _showDeleteDialog(context, journalEntry),
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Entry',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Time Section
            _buildDateSection(context, journalEntry),
            const SizedBox(height: 24),
            
            // Weather Section
            _buildWeatherSection(context, journalEntry),
            const SizedBox(height: 24),
            
            // Journal Text Section
            _buildTextSection(context, journalEntry),
            
            // Edit Info (if entry was edited)
            if (journalEntry.editedAt != null) ...[
              const SizedBox(height: 24),
              _buildEditInfoSection(context, journalEntry),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Date & Time',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatFullDate(entry.date),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFullTime(entry.date),
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getTimeAgo(entry.date),
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weather',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            WeatherDisplay(weather: entry.weather),
            if (entry.weather.cityName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  entry.weather.cityName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSection(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.book,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Journal Entry',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.text,
              style: textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditInfoSection(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Edited ${_formatFullDate(entry.editedAt!)} at ${_formatFullTime(entry.editedAt!)}',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    return '$weekday, $month $day, $year';
  }

  String _formatFullTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _editEntry(BuildContext context, JournalEntry entry) {
    Navigator.pushNamed(
      context,
      '/create',
      arguments: entry,
    );
  }

  void _showDeleteDialog(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<JournalProvider>().deleteEntry(entry.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
