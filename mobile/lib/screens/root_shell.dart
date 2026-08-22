import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'classes_screen.dart';
import 'dashboard_screen.dart';
import 'fiche_form_screen.dart';
import 'history_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  /// Notifie `DashboardScreen` a chaque retour sur l'onglet Accueil depuis
  /// un autre onglet, pour qu'il recharge ses donnees en place (juste les
  /// chiffres qui changent) au lieu d'etre demonte/remonte : l'`IndexedStack`
  /// garde les ecrans en memoire sans les recharger automatiquement, ce qui
  /// laisserait sinon le tableau de bord affiche des donnees perimees apres
  /// une modification faite depuis un autre onglet (ex. ajout d'eleve dans
  /// Classes).
  final ValueNotifier<int> _homeRefreshTick = ValueNotifier(0);

  /// Meme principe que `_homeRefreshTick`, pour l'onglet Fiches : les options
  /// matiere/niveau proposees viennent des classes de l'enseignant, chargees
  /// une seule fois a l'ouverture (voir `FicheFormScreen._loadOptionsFromClasses`).
  /// Sans ce signal, une matiere/classe ajoutee depuis un autre onglet reste
  /// invisible tant que l'app n'est pas relancee (l'`IndexedStack` garde
  /// l'ecran monte sans jamais rappeler `initState`).
  final ValueNotifier<int> _ficheRefreshTick = ValueNotifier(0);

  void goToTab(int index) {
    if (index == 0 && _index != 0) _homeRefreshTick.value++;
    if (index == 3 && _index != 3) _ficheRefreshTick.value++;
    setState(() => _index = index);
  }

  @override
  void dispose() {
    _homeRefreshTick.dispose();
    _ficheRefreshTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Necessaire pour que le fond du Scaffold (visible sous la SafeArea et
    // derriere l'IndexedStack) suive le mode sombre : les ecrans enfants
    // observent deja `AppState` chacun de leur cote, mais le Scaffold du
    // shell lui-meme doit aussi s'abonner pour rafraichir sa propre couleur.
    context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(
              onGoToTab: goToTab,
              refreshSignal: _homeRefreshTick,
            ),
            ClassesScreen(onGoToTab: goToTab),
            HistoryScreen(onGoToTab: goToTab),
            FicheFormScreen(embedded: true, refreshSignal: _ficheRefreshTick),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: goToTab),
    );
  }
}
