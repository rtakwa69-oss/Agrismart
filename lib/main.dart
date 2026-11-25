
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agrismart/config.dart';
import 'package:agrismart/firebase_options.dart';

import 'package:agrismart/providers/assistant_provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/reglages_provider.dart';
import 'package:agrismart/providers/alerte_provider.dart';

import 'package:agrismart/screens/auth_gate.dart';

import 'package:agrismart/services/assistant_service.dart';
import 'package:agrismart/services/auth_locale_service.dart';
import 'package:agrismart/services/auth_service.dart';
import 'package:agrismart/services/firebase_auth_service.dart';
import 'package:agrismart/services/notification_service.dart';

import 'package:agrismart/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase ou authentification locale
  final AuthService authService;

  if (utiliserFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    authService = FirebaseAuthService();
  } else {
    authService = AuthLocaleService();
  }

  // Initialisation du stockage local
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        // Authentification
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),

        // Gestion des zones selon l'utilisateur
        ChangeNotifierProvider(
          create: (context) => ZonesProvider(
            prefs,
            context.read<AuthProvider>(),
          ),
        ),

        // Assistant IA lié à l'utilisateur et à ses zones
        ChangeNotifierProvider(
          create: (context) => AssistantProvider(
            AssistantService(),
            context.read<AuthProvider>(),
            context.read<ZonesProvider>(),
          ),
        ),

        // Gestion du thème
        ChangeNotifierProvider(
          create: (_) => ReglagesProvider(prefs),
        ),

        // Gestion météo et cache local
        ChangeNotifierProvider(
          create: (_) => MeteoProvider(prefs)..charger(),
        ),

        // Gestion des alertes et notifications
        ChangeNotifierProvider(
          create: (context) => AlerteProvider(
            context.read<ZonesProvider>(),
            context.read<MeteoProvider>(),
            NotificationService(),
          ),
        ),
      ],
      child: const AgriSmartApp(),
    ),
  );
}

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.watch<ReglagesProvider>().themeMode;

    return MaterialApp(
      title: 'AgriSmart',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.clair(),
      darkTheme: AppTheme.sombre(),

      // Thème sauvegardé
      themeMode: themeMode,

      home: const AuthGate(),
    );
  }
}
