import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/strings.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cle API Gemini chargee depuis .env, jamais en dur dans le code.
  // Si le fichier est absent/vide, l'app demarre quand meme : la generation
  // de fiches affichera juste une erreur claire (GeminiService.isConfigured).
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cache hors-ligne Firestore : actif par defaut sur mobile, on le rend
  // explicite car c'est un point important pour des enseignants en zone de
  // faible connectivite.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Langue de l'interface, mode sombre et trimestre actif : charges avant
  // le premier frame pour eviter un flash dans la mauvaise langue / le
  // mauvais theme / le mauvais trimestre au demarrage.
  final locale = await AppState.loadPersistedLocale();
  final darkMode = await AppState.loadPersistedDarkMode();
  final periode = await AppState.loadPersistedPeriode();

  runApp(
    JangalekatApp(
      initialLocale: locale,
      initialDarkMode: darkMode,
      initialPeriode: periode,
    ),
  );
}

class JangalekatApp extends StatelessWidget {
  final AppLocale initialLocale;
  final bool initialDarkMode;
  final String initialPeriode;
  const JangalekatApp({
    super.key,
    required this.initialLocale,
    required this.initialDarkMode,
    required this.initialPeriode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        locale: initialLocale,
        darkMode: initialDarkMode,
        periode: initialPeriode,
      )..restoreSession(),
      child: Builder(
        builder: (context) {
          // Rebuild le theme (couleurs, ColorScheme) quand la langue ou le
          // mode sombre change : rien d'autre dans l'app ne passe par
          // `Theme.of(context)`, mais MaterialApp l'utilise pour les
          // snackbars/dialogs par defaut.
          context.watch<AppState>();
          return MaterialApp(
            title: 'Jàngalekat',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: const _Bootstrap(),
            // Ferme le clavier quand on touche en dehors d'un champ de
            // texte, sur tous les ecrans sans avoir a le repeter partout.
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Ecran affiche pendant `AppState.restoreSession()` (lecture de la session
/// Firebase Auth), puis bascule vers Login/RootShell. Fond vert fonce et
/// logo identiques a l'ecran de lancement natif (LaunchScreen storyboard /
/// launch_background Android) pour une transition invisible entre le natif
/// et le premier frame Flutter, avec un fondu vers l'ecran suivant plutot
/// qu'une coupure brutale.
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final Widget next = app.restoring
        ? const _SplashScreen(key: ValueKey('splash'))
        : (app.releaseExpired
              ? const _ReleaseExpiredScreen(key: ValueKey('expired'))
              : (app.isAuthenticated
                    ? const RootShell(key: ValueKey('root'))
                    : const LoginScreen(key: ValueKey('login'))));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: next,
    );
  }
}

/// Affiche quand `AppState.releaseExpired` est vrai (voir
/// `ReleaseGateService`) : ecran final, aucune action possible vers le reste
/// de l'app tant que la date d'expiration en base n'est pas repoussee.
class _ReleaseExpiredScreen extends StatelessWidget {
  const _ReleaseExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_jangalekat_rounded.png',
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 20),
              Text(
                app.tr('app.releaseExpiredTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                app.tr('app.releaseExpiredMessage'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textOnDark.withValues(alpha: 0.75),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Center(
        // Image deja arrondie (coins transparents dans le PNG, pas de
        // ClipRRect) : meme taille et meme rendu que l'image de lancement
        // native (LaunchScreen.storyboard / launch_background Android),
        // qui utilise le meme fichier — le premier frame Flutter est ainsi
        // pixel-identique a l'ecran natif qu'il remplace, sans "pop" au
        // changement.
        child: Image.asset(
          'assets/images/logo_jangalekat_rounded.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
