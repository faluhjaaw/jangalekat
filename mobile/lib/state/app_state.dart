import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/classe_summary.dart';
import '../models/enseignant.dart';
import '../models/message_models.dart';
import '../services/auth_service.dart';
import '../services/classe_service.dart';
import '../services/eleve_service.dart';
import '../services/fiche_service.dart';
import '../services/note_service.dart';
import '../services/message_service.dart';
import '../services/recommendation_service.dart';
import '../services/release_gate_service.dart';
import '../theme/app_colors.dart';

const _kLocalePrefKey = 'jangalekat_locale';
const _kDarkModePrefKey = 'jangalekat_dark_mode';
const _kPeriodePrefKey = 'jangalekat_periode';

/// Trimestres geres par l'app (systeme scolaire senegalais). Pas de gestion
/// de dates de debut/fin : l'enseignant choisit juste le trimestre actif,
/// chaque note est deja rattachee a un trimestre precis en base (voir
/// `Note.idFor`).
const List<String> kPeriodes = ['T1', 'T2', 'T3'];

const Map<String, String> _kPeriodeLabelsFr = {
  'T1': 'Trimestre 1',
  'T2': 'Trimestre 2',
  'T3': 'Trimestre 3',
};

/// Etat global minimal : session enseignant (Firebase Auth) + acces aux
/// services Firestore. Chaque ecran va chercher ses propres donnees (classes,
/// eleves, notes...) au moment ou il en a besoin, pas de gros store central.
class AppState extends ChangeNotifier {
  final AuthService authService = AuthService();
  final ReleaseGateService _releaseGateService = ReleaseGateService();

  /// Langue de l'interface (FR/EN), independante de la langue des fiches de
  /// cours generees par l'IA. Persistee localement (preference d'appareil,
  /// pas une donnee de profil a synchroniser).
  AppLocale locale;

  /// Mode sombre : bascule uniquement `AppColors._dark` (pas de
  /// `Theme.of(context)` dans cette app, les ecrans lisent `AppColors`
  /// directement) donc il suffit de `notifyListeners()` pour que les ecrans
  /// qui observent `AppState` se redessinent avec les nouvelles couleurs.
  bool darkMode;

  /// Trimestre actif ('T1'/'T2'/'T3') : filtre toutes les notes lues/ecrites
  /// (saisie, moyennes, historique eleve...) pour que l'app reste coherente
  /// sur un seul trimestre a la fois. Persiste comme la langue/le mode
  /// sombre — c'est une preference d'appareil, pas une donnee de profil.
  String periode;

  AppState({
    this.locale = AppLocale.fr,
    this.darkMode = false,
    this.periode = 'T2',
  }) {
    AppColors.setDark(darkMode);
  }

  /// Libelle localise (FR/EN) du trimestre actif, pour l'affichage a l'ecran.
  String get periodeLabel => tr('period.${periode.toLowerCase()}');

  /// Libelle toujours en francais, pour le corps des messages WhatsApp
  /// envoyes aux parents (langue des destinataires, independante de la
  /// langue de l'interface — voir strings.dart).
  String get periodeLabelFr => _kPeriodeLabelsFr[periode] ?? periode;

  Future<void> setPeriode(String value) async {
    if (value == periode) return;
    periode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPeriodePrefKey, value);
  }

  static Future<String> loadPersistedPeriode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kPeriodePrefKey);
    return kPeriodes.contains(value) ? value! : 'T2';
  }

  String tr(String key) => Strings.t(locale, key);

  Future<void> setLocale(AppLocale value) async {
    if (value == locale) return;
    locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalePrefKey, value == AppLocale.en ? 'en' : 'fr');
  }

  static Future<AppLocale> loadPersistedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocalePrefKey) == 'en'
        ? AppLocale.en
        : AppLocale.fr;
  }

  Future<void> setDarkMode(bool value) async {
    if (value == darkMode) return;
    darkMode = value;
    AppColors.setDark(value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModePrefKey, value);
  }

  static Future<bool> loadPersistedDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDarkModePrefKey) ?? false;
  }

  ClasseService? _classeService;
  EleveService? _eleveService;
  NoteService? _noteService;
  MessageService? _messageService;
  FicheService? _ficheService;
  RecommendationService? _recommendationService;

  ClasseService get classeService => _classeService!;
  EleveService get eleveService => _eleveService!;
  NoteService get noteService => _noteService!;
  MessageService get messageService => _messageService!;
  FicheService get ficheService => _ficheService!;
  RecommendationService get recommendationService => _recommendationService!;

  Enseignant? enseignant;
  bool restoring = true;

  /// Verrou a distance pour les builds de test (voir `ReleaseGateService`) :
  /// verifie a chaque lancement, avant meme l'ecran de connexion. `false`
  /// par defaut (fail-open) tant que la verification n'a pas eu lieu.
  bool releaseExpired = false;

  /// N'a aucun lien avec l'etat reseau reel de l'appareil — voir
  /// `toggleDemoOfflineView`, dont le nom precise l'intention.
  bool demoOfflineView = false;

  bool get isAuthenticated => enseignant != null;

  /// Donnees du tableau de bord precharger pendant l'ecran de lancement (voir
  /// `restoreSession`), consommees une seule fois par `DashboardScreen` pour
  /// eviter un deuxieme spinner juste apres le splash. `null` des qu'elles
  /// ont ete recuperees ou si le prechargement a echoue/n'a pas eu lieu :
  /// l'ecran retombe alors sur son propre chargement normal.
  List<ClasseSummary>? cachedDashboardSummaries;
  List<MessageEntry>? cachedDashboardMessages;

  /// Firebase Auth conserve la session entre les lancements : on lit juste
  /// l'utilisateur courant et son profil au demarrage, pas de token a gerer.
  /// Si l'enseignant est deja connecte, on precharge aussi les donnees du
  /// tableau de bord ici : le splash reste affiche pendant ce temps (voir
  /// `main.dart`), donc l'utilisateur ne voit jamais l'ecran vide avec son
  /// propre spinner juste apres.
  Future<void> restoreSession() async {
    releaseExpired = await _releaseGateService.isExpired();
    if (releaseExpired) {
      restoring = false;
      notifyListeners();
      return;
    }
    final user = authService.currentUser;
    if (user != null) {
      final profil = await authService.loadProfile(user.uid);
      if (profil != null) {
        _setEnseignant(profil);
        try {
          await authService.refreshEmailVerified();
          cachedDashboardSummaries = await loadClasseSummaries();
          cachedDashboardMessages = await messageService.historique();
        } catch (_) {
          // Pas bloquant : DashboardScreen fera son propre chargement (avec
          // son propre etat d'erreur) si le prechargement a echoue.
        }
      }
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> login(String email, String pin) async {
    final e = await authService.login(email: email, pin: pin);
    _setEnseignant(e);
  }

  Future<void> resetPassword(String email) => authService.resetPassword(email);

  /// Purement incitatif : rien dans l'app (ni ecran, ni regle Firestore) ne
  /// conditionne l'acces a `emailVerified`. Choix assume pour ne jamais
  /// bloquer un enseignant en zone de faible connectivite qui n'a pas encore
  /// pu consulter sa boite mail — voir la banniere sur `DashboardScreen`.
  bool get emailVerified => authService.emailVerified;

  /// Recharge l'etat de verification depuis Firebase (le SDK ne le met pas a
  /// jour tout seul apres que l'enseignant a clique le lien recu par email).
  Future<void> refreshEmailVerified() async {
    await authService.refreshEmailVerified();
    notifyListeners();
  }

  Future<void> resendVerificationEmail() => authService.sendEmailVerification();

  Future<void> register({
    required String nom,
    required String email,
    required String pin,
    String? ecole,
    String? telephone,
    String? ia,
    String? ief,
  }) async {
    final e = await authService.register(
      nom: nom,
      email: email,
      pin: pin,
      ecole: ecole,
      telephone: telephone,
      ia: ia,
      ief: ief,
    );
    _setEnseignant(e);
  }

  void _setEnseignant(Enseignant e) {
    enseignant = e;
    _classeService = ClasseService(e.uid);
    _eleveService = EleveService(e.uid);
    _noteService = NoteService(e.uid);
    _messageService = MessageService(e.uid);
    _ficheService = FicheService(e.uid);
    _recommendationService = RecommendationService(e.uid, e.nom);
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    enseignant = null;
    _classeService = null;
    _eleveService = null;
    _noteService = null;
    _messageService = null;
    _ficheService = null;
    _recommendationService = null;
    notifyListeners();
  }

  /// Bascule d'affichage uniquement (demo, fidele a la maquette), sans lien
  /// avec l'etat reseau reel : le cache hors-ligne Firestore, lui, est actif
  /// en permanence independamment de ce bouton (voir main.dart). Le nom
  /// existe pour que ce ne soit jamais confondu avec un vrai indicateur de
  /// connectivite.
  void toggleDemoOfflineView() {
    demoOfflineView = !demoOfflineView;
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
                periode,
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
