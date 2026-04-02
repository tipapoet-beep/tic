import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'config/routes/app_router.dart';
import 'core/theme/premium_theme.dart';
import 'core/database/local_database.dart';
import 'core/sync/sync_manager.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: '.env');
  
  if (!kIsWeb) {
    Logger.log('📦 Initializing local database...');
    await LocalDatabase().init();
  } else {
    Logger.log('🌐 Running on web - local database disabled');
  }
  
  Logger.log('☁️ Initializing Supabase...');
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  if (kIsWeb) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Logger.log('✅ Session restored for user: ${session.user.id}');
    } else {
      Logger.log('⚠️ No active session found');
    }
  }
  
  Logger.log('✅ Supabase initialized');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _syncManager = SyncManager();
  
  @override
  void initState() {
    super.initState();
    _initSync();
  }
  
  Future<void> _initSync() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        _syncManager.init(context);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Фитнес Экосистема',
      theme: _buildTheme(),
      routerConfig: AppRouter().config,
      debugShowCheckedModeBanner: false,
    );
  }
  
  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.green,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      cardColor: const Color(0xFF1A1D24),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white70),
      ),
      
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      ),
    );
  }
}