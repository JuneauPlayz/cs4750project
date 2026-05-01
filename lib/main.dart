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
import 'widgets/app_background.dart';

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
  const background = Color(0xFF0F172A);
  const surface = Color(0xFF172033);
  const surfaceLow = Color(0xFF1D293D);
  const surfaceHigh = Color(0xFF26364B);
  const teal = Color(0xFF2DD4BF);
  const amber = Color(0xFFFBBF24);
  const coral = Color(0xFFFB7185);
  const border = Color(0xFF2B4056);

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: teal,
        brightness: Brightness.dark,
      ).copyWith(
        primary: teal,
        onPrimary: const Color(0xFF052F2C),
        primaryContainer: const Color(0xFF134E4A),
        onPrimaryContainer: const Color(0xFFCCFBF1),
        secondary: amber,
        onSecondary: const Color(0xFF2F2300),
        secondaryContainer: const Color(0xFF3F320A),
        onSecondaryContainer: const Color(0xFFFFE9A3),
        tertiary: coral,
        onTertiary: const Color(0xFF3E0711),
        tertiaryContainer: const Color(0xFF4A1620),
        onTertiaryContainer: const Color(0xFFFFD1D8),
        error: coral,
        outline: const Color(0xFF6B7B8F),
        outlineVariant: border,
        surfaceContainerLowest: background,
        surface: surface,
        surfaceContainerLow: surfaceLow,
        surfaceContainer: surfaceLow,
        surfaceContainerHigh: const Color(0xFF223147),
        surfaceContainerHighest: surfaceHigh,
        onSurface: const Color(0xFFF8FAFC),
        onSurfaceVariant: const Color(0xFFAAB6C7),
      );

  final textTheme = Typography.material2021(platform: TargetPlatform.iOS).white
      .apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: background.withValues(alpha: 0.96),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: border),
      ),
    ),
    textTheme: textTheme,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface.withValues(alpha: 0.98),
      elevation: 0,
      height: 78,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          color: selected
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        );
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
              borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(20),
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
            side: const BorderSide(color: border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: colorScheme.primary.withValues(alpha: 0.18),
      disabledColor: colorScheme.surfaceContainerLow,
      secondarySelectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      secondaryLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedBackgroundColor: colorScheme.primary.withValues(alpha: 0.18),
        foregroundColor: colorScheme.onSurfaceVariant,
        selectedForegroundColor: colorScheme.primary,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceLow,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surfaceLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceHigh,
      contentTextStyle: TextStyle(color: colorScheme.onSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'bootstrap',
        context: ErrorDescription('while starting GameDevLens'),
      ),
    );
    runApp(StartupErrorApp(message: '$error'));
    return;
  }

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

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Startup Error',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The app could not finish initializing on this device.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(child: Center(child: CircularProgressIndicator())),
    );
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
