import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cle API xAI (Grok) chargee depuis .env, jamais en dur dans le code.
  // Si le fichier est absent/vide, l'app demarre quand meme : la generation
  // de fiches affichera juste une erreur claire (GrokService.isConfigured).
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cache hors-ligne Firestore : actif par defaut sur mobile, on le rend
  // explicite car c'est un point important pour des enseignants en zone de
  // faible connectivite.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const JangalekatApp());
}

class JangalekatApp extends StatelessWidget {
  const JangalekatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..restoreSession(),
      child: MaterialApp(
        title: 'Jàngalekat',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Bootstrap(),
      ),
    );
  }
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.restoring) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentGreenText),
        ),
      );
    }
    return app.isAuthenticated ? const RootShell() : const LoginScreen();
  }
}
