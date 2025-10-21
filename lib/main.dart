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
import 'services/notification_service.dart';
import 'services/medication_notification_service.dart';
import 'services/appointment_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase with auth flow configuration
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: true,
    );

    // Initialize notification service
    await NotificationService().initialize();

    // Initialize medication notification service
    final medicationNotificationService = MedicationNotificationService();
    await medicationNotificationService.initialize();

    // Initialize appointment notification service
    final appointmentNotificationService = AppointmentNotificationService();
    await appointmentNotificationService.initialize();
  } catch (e) {
    debugPrint('Initialization error: $e');
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
        title: 'mySahara',
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
        home: const AuthWrapper(),
        initialRoute: null,

        // Route definitions
        getPages: [
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

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
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
            // Create profile for OAuth user
            final fullName = user.userMetadata?['full_name'] as String? ??
                            user.userMetadata?['name'] as String? ??
                            user.email?.split('@')[0] ?? 'User';

            await supabase.from('users').insert({
              'id': user.id,
              'email': user.email,
              'full_name': fullName,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Error creating user profile: $e');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<AuthProvider>().loadUserProfile();
          Get.offAll(() => const HomeScreen());
        });
      } else {
        // User is logged out
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Get.offAll(() => const LoginScreen());
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
      // User is not logged in
      return const LoginScreen();
    }
  }
}
