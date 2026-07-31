import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../models/classe_summary.dart';
import '../models/enseignant.dart';
import '../services/auth_service.dart';
import '../services/classe_service.dart';
import '../services/eleve_service.dart';
import '../services/note_service.dart';
import '../services/message_service.dart';

/// Etat global minimal : session enseignant (Firebase Auth) + acces aux
/// services Firestore. Chaque ecran va chercher ses propres donnees (classes,
/// eleves, notes...) au moment ou il en a besoin, pas de gros store central.
class AppState extends ChangeNotifier {
  final AuthService authService = AuthService();

  ClasseService? _classeService;
  EleveService? _eleveService;
  NoteService? _noteService;
  MessageService? _messageService;

  ClasseService get classeService => _classeService!;
  EleveService get eleveService => _eleveService!;
  NoteService get noteService => _noteService!;
  MessageService get messageService => _messageService!;

  Enseignant? enseignant;
  bool restoring = true;
  bool offline = false;

  bool get isAuthenticated => enseignant != null;

  /// Firebase Auth conserve la session entre les lancements : on lit juste
  /// l'utilisateur courant et son profil au demarrage, pas de token a gerer.
  Future<void> restoreSession() async {
    final user = authService.currentUser;
    if (user != null) {
      final profil = await authService.loadProfile(user.uid);
      if (profil != null) _setEnseignant(profil);
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> login(String telephone, String pin) async {
    final e = await authService.login(telephone: telephone, pin: pin);
    _setEnseignant(e);
  }

  Future<void> register({
    required String nom,
    required String telephone,
    required String pin,
    String? ecole,
  }) async {
    final e = await authService.register(
      nom: nom,
      telephone: telephone,
      pin: pin,
      ecole: ecole,
    );
    _setEnseignant(e);
  }

  void _setEnseignant(Enseignant e) {
    enseignant = e;
    _classeService = ClasseService(e.uid);
    _eleveService = EleveService(e.uid);
    _noteService = NoteService(e.uid);
    _messageService = MessageService(e.uid);
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    enseignant = null;
    _classeService = null;
    _eleveService = null;
    _noteService = null;
    _messageService = null;
    notifyListeners();
  }

  /// Bascule d'affichage uniquement (demo, fidele a la maquette) : le cache
  /// hors-ligne Firestore, lui, est actif en permanence independamment de ce
  /// bouton (voir main.dart).
  void toggleOffline() {
    offline = !offline;
    notifyListeners();
  }

  /// Charge les classes de l'enseignant avec effectif + moyenne de periode,
  /// utilise par le tableau de bord et l'ecran "Mes classes".
  Future<List<ClasseSummary>> loadClasseSummaries() async {
    final classes = await classeService.list();
    return Future.wait(
      classes.map((classe) async {
        final eleves = await eleveService.listForClasse(classe.id);
        final moyennes = await Future.wait(
          eleves.map(
            (e) async => NoteService.moyennePonderee(
              await noteService.notesEleve(
                classe.id,
                e.id,
                kPeriodeActuelle,
                classe.matieres,
              ),
            ),
          ),
        );
        final stats = StatistiquesClasse.from(moyennes);
        return ClasseSummary(
          classe: classe,
          eleves: eleves,
          moyenne: stats.moyenneGenerale,
        );
      }),
    );
  }
}
