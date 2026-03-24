import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/discovery_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/project_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/game_hub_screen.dart';
import 'screens/game_onboarding_screen.dart';
import 'screens/notes_screen.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_user_data_service.dart';

WidgetStateProperty<Color?> _softOverlay(Color color) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: 0.10);
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return color.withValues(alpha: 0.05);
    }
    return Colors.transparent;
  });
}

ThemeData _buildTheme() {
  const background = Color(0xFF101214);
  const surface = Color(0xFF171A1D);
  const surfaceLow = Color(0xFF1D2227);
  const surfaceHigh = Color(0xFF2A3138);

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF00BFA5),
        brightness: Brightness.dark,
      ).copyWith(
        surface: surface,
        surfaceContainerLow: surfaceLow,
        surfaceContainerHighest: surfaceHigh,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 72,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          size: 22,
        );
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            animationDuration: const Duration(milliseconds: 140),
            overlayColor: _softOverlay(colorScheme.onPrimary),
          ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            animationDuration: const Duration(milliseconds: 140),
            overlayColor: _softOverlay(colorScheme.onPrimary),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            foregroundColor: colorScheme.onSurface,
            backgroundColor: colorScheme.surfaceContainerLow,
            side: BorderSide(color: colorScheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            animationDuration: const Duration(milliseconds: 140),
            overlayColor: _softOverlay(colorScheme.primary),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ).copyWith(
            animationDuration: const Duration(milliseconds: 140),
            overlayColor: _softOverlay(colorScheme.primary),
          ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).copyWith(overlayColor: _softOverlay(colorScheme.primary)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  final userDataService = FirestoreUserDataService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authService: FirebaseAuthService())..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesProvider(userDataService: userDataService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectProvider(userDataService: userDataService),
        ),
        ChangeNotifierProvider(
          create: (_) => DiscoveryProvider(userDataService: userDataService),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameDevLens',
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: _buildTheme(),
      home: const _AppFlowGate(),
    );
  }
}

class _AppFlowGate extends StatefulWidget {
  const _AppFlowGate();

  @override
  State<_AppFlowGate> createState() => _AppFlowGateState();
}

class _AppFlowGateState extends State<_AppFlowGate> {
  String? _lastUserId;
  bool _isSyncingUserData = false;

  void _syncUserData(String? userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final notesProvider = context.read<NotesProvider>();
      final projectProvider = context.read<ProjectProvider>();
      final discoveryProvider = context.read<DiscoveryProvider>();

      try {
        if (userId == null) {
          notesProvider.reset();
          projectProvider.reset();
          discoveryProvider.reset();
        } else {
          await Future.wait([
            notesProvider.loadForUser(userId),
            projectProvider.loadForUser(userId),
            discoveryProvider.loadForUser(userId),
          ]);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSyncingUserData = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ProjectProvider>(
      builder: (context, authProvider, projectProvider, child) {
        final userId = authProvider.currentUser?.id;

        if (!authProvider.isInitializing && userId != _lastUserId) {
          _lastUserId = userId;
          _isSyncingUserData = true;
          _syncUserData(userId);
          return const _AuthLoadingScreen();
        }

        if (authProvider.isInitializing || _isSyncingUserData) {
          return const _AuthLoadingScreen();
        }

        if (!authProvider.isAuthenticated) {
          return const AuthScreen(key: ValueKey('auth-screen'));
        }

        if (projectProvider.needsOnboarding) {
          return const GameOnboardingScreen(key: ValueKey('game-onboarding'));
        }

        return const MainNavigationScreen(key: ValueKey('main-navigation'));
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const NotesScreen(),
          const GameHubScreen(),
          DiscoverScreen(isActive: _currentIndex == 2),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Game Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
        ],
      ),
    );
  }
}
