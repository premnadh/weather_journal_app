class AppConstants {
  // API Configuration
  static const String openWeatherApiKey = 'YOUR_API_KEY_HERE';
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Default location (New York)
  static const double defaultLatitude = 40.7128;
  static const double defaultLongitude = -74.0060;
  
  // App Settings
  static const String appName = 'Weather Journal';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String journalEntriesBox = 'journal_entries';
  static const String userPinKey = 'user_pin';
  static const String sessionActiveKey = 'session_active';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Weather Conditions
  static const List<String> weatherConditions = [
    'Clear',
    'Clouds', 
    'Rain',
    'Drizzle',
    'Thunderstorm',
    'Snow',
    'Mist',
    'Fog',
    'Haze',
    'Smoke',
    'Dust',
    'Sand',
    'Ash',
    'Squall',
    'Tornado'
  ];
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String fullDateFormat = 'EEEE, MMMM d, y';
  static const String timeAgoFormat = 'HH:mm a';
  
  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String apiError = 'Failed to fetch data from server.';
  static const String storageError = 'Failed to save data locally.';
  static const String unknownError = 'An unknown error occurred.';
  static const String weatherFetchError = 'Failed to fetch weather data.';
  static const String entrySaveError = 'Failed to save journal entry.';
  static const String entryDeleteError = 'Failed to delete journal entry.';
  
  // Success Messages
  static const String entrySaved = 'Journal entry saved successfully!';
  static const String entryUpdated = 'Journal entry updated successfully!';
  static const String entryDeleted = 'Journal entry deleted successfully!';
  static const String pinSet = 'PIN set successfully!';
  static const String pinVerified = 'PIN verified successfully!';
  
  // Validation Messages
  static const String pinRequired = 'PIN is required.';
  static const String pinTooShort = 'PIN must be at least 4 digits.';
  static const String textRequired = 'Please enter some text for your journal entry.';
  static const String weatherRequired = 'Weather data is required.';
  
  // Placeholder Texts
  static const String enterPinText = 'Enter your PIN';
  static const String setPinText = 'Set a new PIN';
  static const String journalHintText = 'Write about your day...';
  static const String searchHintText = 'Search entries...';
  
  // Button Texts
  static const String saveButton = 'Save Entry';
  static const String updateButton = 'Update Entry';
  static const String deleteButton = 'Delete';
  static const String cancelButton = 'Cancel';
  static const String editButton = 'Edit';
  static const String createButton = 'Create Entry';
  static const String clearFiltersButton = 'Clear Filters';
  static const String retryButton = 'Retry';
  
  // Screen Titles
  static const String homeTitle = 'Weather Journal';
  static const String createTitle = 'Create Entry';
  static const String editTitle = 'Edit Entry';
  static const String detailTitle = 'Entry Detail';
  static const String pinTitle = 'PIN Authentication';
}
