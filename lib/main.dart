import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/health_record_provider.dart';
import 'providers/medical_timeline_provider.dart';
import 'providers/family_provider.dart';
import 'providers/language_provider.dart';
import 'providers/progress_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/ai_chat/ai_chat_screen.dart';
import 'screens/ai_chat/chat_history_screen.dart';
import 'screens/share/view_shared_history_screen.dart';
import 'screens/landing/landing_screen.dart';
import 'services/notification_service.dart';
import 'services/medication_notification_service.dart';
import 'services/appointment_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // For web, environment variables must be hardcoded at build time
    // For mobile, they can be loaded from .env file
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://fbnliqznxpdjhesctbmy.supabase.co',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZibmxpcXpueHBkamhlc2N0Ym15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxOTQ1NzYsImV4cCI6MjA3NTc3MDU3Nn0.PBxXxHBsYaUqXB9yw_7WyLKTnMGRJ7PO_LiMa92z3bw',
    );

    // Try to load .env file (works on mobile, fails gracefully on web)
    bool envLoaded = false;
    try {
      await dotenv.load(fileName: ".env");
      envLoaded = true;
    } catch (e) {
      debugPrint('No .env file found, using default values (normal for web)');
    }

    // Initialize Supabase with auth flow configuration
    final urlToUse = envLoaded && dotenv.env['SUPABASE_URL']?.isNotEmpty == true
        ? dotenv.env['SUPABASE_URL']!
        : supabaseUrl;
    final keyToUse = envLoaded && dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true
        ? dotenv.env['SUPABASE_ANON_KEY']!
        : supabaseAnonKey;

    debugPrint('Initializing Supabase...');
    debugPrint('URL: $urlToUse');
    debugPrint('Key length: ${keyToUse.length}');

    await Supabase.initialize(
      url: urlToUse,
      anonKey: keyToUse,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: true,
    );

    debugPrint('Supabase initialized successfully!');

    // Initialize notification services (only on mobile, skip on web)
    try {
      await NotificationService().initialize();
      final medicationNotificationService = MedicationNotificationService();
      await medicationNotificationService.initialize();
      final appointmentNotificationService = AppointmentNotificationService();
      await appointmentNotificationService.initialize();
    } catch (e) {
      debugPrint('Notification services not available (normal for web): $e');
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
    // Re-throw to prevent app from running in bad state
    rethrow;
  }

  // Initialize language provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  runApp(MyApp(languageProvider: languageProvider));
}

class MyApp extends StatelessWidget {
  final LanguageProvider languageProvider;

  const MyApp({super.key, required this.languageProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HealthRecordProvider()),
        ChangeNotifierProvider(create: (_) => MedicalTimelineProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: GetMaterialApp(
        title: 'My Sahara: For You & Your Family',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,

        // Responsive framework configuration
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),

        // Initial route based on authentication status
        initialRoute: '/',

        // Route definitions
        getPages: [
          GetPage(name: '/', page: () => const AuthWrapper()),
          GetPage(name: '/landing', page: () => const LandingScreen()),
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
          GetPage(name: '/ai-chat', page: () => const AiChatScreen()),
          GetPage(name: '/chat-history', page: () => const ChatHistoryScreen()),
          GetPage(
            name: '/view',
            page: () {
              // Extract share code from URL parameters
              final parameters = Get.parameters;
              final code = parameters['code'] ?? '';
              return ViewSharedHistoryScreen(shareCode: code);
            },
            // Make this route publicly accessible (no auth required)
            middlewares: [],
          ),
        ],

        // Handle unknown routes
        unknownRoute: GetPage(
          name: '/notfound',
          page: () => const AuthWrapper(),
        ),
      ),
    );
  }
}

/// Wrapper widget to handle authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    // After first frame, we're no longer in initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Setup Supabase auth state listener
  void _setupAuthListener() {
    final supabase = Supabase.instance.client;

    // Listen to auth state changes
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;

      // Only react to actual auth events, not initial session checks
      final event = data.event;
      if (event != AuthChangeEvent.signedIn &&
          event != AuthChangeEvent.signedOut &&
          event != AuthChangeEvent.tokenRefreshed) {
        return;
      }

      final session = data.session;

      if (session != null) {
        // User is logged in
        final user = session.user;

        // Create user profile if it doesn't exist (for OAuth sign-ins)
        try {
          final existingProfile = await supabase
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (existingProfile == null) {
            // Profile should be created by trigger, but if not, wait a bit
            await Future.delayed(const Duration(milliseconds: 1000));

            // Check again
            final retryProfile = await supabase
                .from('users')
                .select()
                .eq('id', user.id)
                .maybeSingle();

            if (retryProfile == null) {
              debugPrint('Warning: User profile not found even after retry. Trigger may have failed.');
            }
          }
        } catch (e) {
          debugPrint('Error creating user profile: $e');
        }

        // Load user profile and navigate
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          await context.read<AuthProvider>().loadUserProfile();

          if (mounted && Get.currentRoute != '/home') {
            Get.offAllNamed('/home');
          }
        });
      } else {
        // User is logged out - clear all data and navigate to landing/login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // Clear all provider states
          context.read<HealthRecordProvider>().clear();
          context.read<FamilyProvider>().clear();
          context.read<MedicalTimelineProvider>().clear();

          // Check if running on web - show landing page, otherwise login
          final isWeb = ResponsiveBreakpoints.of(context).isDesktop ||
                        ResponsiveBreakpoints.of(context).isTablet;

          // Only navigate if we're not already on the landing or login screen
          final currentRoute = Get.currentRoute;

          // Don't navigate if already on landing or login, or if this is initial load
          if (currentRoute == '/landing' || currentRoute == '/login') {
            return;
          }

          // Navigate based on device type
          if (isWeb) {
            Get.offAllNamed('/landing');
          } else {
            Get.offAllNamed('/login');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if accessing public view route
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == '/view' || Get.currentRoute == '/view') {
      // Allow public access to view shared history
      final parameters = Get.parameters;
      final code = parameters['code'] ?? '';
      return ViewSharedHistoryScreen(shareCode: code);
    }

    // Check initial auth state
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is already logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthProvider>().loadUserProfile();
      });
      return const HomeScreen();
    } else {
      // User is not logged in - show landing page for web, login for mobile
      final isWeb = ResponsiveBreakpoints.of(context).isDesktop ||
                    ResponsiveBreakpoints.of(context).isTablet;

      return isWeb ? const LandingScreen() : const LoginScreen();
    }
  }
}
