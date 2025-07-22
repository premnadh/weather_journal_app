import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Import providers
import 'providers/journal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
// Import screens
import 'screens/pin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_entry_screen.dart';
import 'screens/entry_detail_screen.dart';
// Import models for Hive registration
import 'models/journal_entry.dart';
import 'models/weather.dart';
import 'dart:async'; // Added for Timer

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(WeatherAdapter());
  
  runApp(const WeatherJournalApp());
}

class WeatherJournalApp extends StatelessWidget {
  const WeatherJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return SessionManager(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Weather Journal App – Track Your Day',
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              debugShowCheckedModeBanner: false,
              initialRoute: '/pin',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/pin':
                    return MaterialPageRoute(builder: (_) => const PinScreen());
                  case '/home':
                    return MaterialPageRoute(builder: (_) => const HomeScreen());
                  case '/create':
                    final entry = settings.arguments as JournalEntry?;
                    return MaterialPageRoute(
                      builder: (_) => CreateEntryScreen(entry: entry),
                    );
                  case '/detail':
                    final entry = settings.arguments as JournalEntry?;
                    return MaterialPageRoute(
                      builder: (_) => EntryDetailScreen(entry: entry),
                    );
                  default:
                    return MaterialPageRoute(builder: (_) => const PinScreen());
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class SessionManager extends StatefulWidget {
  final Widget child;
  const SessionManager({required this.child, super.key});

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> with WidgetsBindingObserver {
  DateTime? _lastUserInteraction;
  late AuthProvider _authProvider;
  Timer? _sessionTimer;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _resetSessionTimer();
    print('[SessionManager] Initialized and timer started.');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetSessionTimer() {
    print('[SessionManager] Resetting session timer.');
    _sessionTimer?.cancel();
    _sessionTimer = Timer(AuthProvider.sessionTimeout, _handleSessionTimeout);
    _authProvider.updateActivity();
  }

  void _handleSessionTimeout() {
    print('[SessionManager] Session timed out! Logging out.');
    _authProvider.forceLogout();
    if (mounted) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/pin', (route) => false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[SessionManager] AppLifecycleState: $state');
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleSessionTimeout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: (node, event) {
        _resetSessionTimer();
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: (_) => _resetSessionTimer(),
        onPointerMove: (_) => _resetSessionTimer(),
        onPointerUp: (_) => _resetSessionTimer(),
        child: widget.child,
      ),
    );
  }
} 