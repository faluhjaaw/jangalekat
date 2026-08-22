import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/matiere.dart';
import '../services/gemini_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'fiche_history_screen.dart';
import 'fiche_result_screen.dart';

/// Niveaux proposes a l'enseignant (primaire + college, systeme senegalais).
const List<String> _kNiveaux = [
  'CI',
  'CP',
  'CE1',
  'CE2',
  'CM1',
  'CM2',
  '6e',
  '5e',
  '4e',
  '3e',
];

/// Durees de seance courantes proposees (optionnel, pas de valeur par defaut).
const List<String> _kDurees = [
  '30 minutes',
  '45 minutes',
  '1 heure',
  '1h30',
  '2 heures',
];

/// Formulaire de generation d'une fiche de cours via Gemini (Google AI).
/// La fiche n'est pas liee a une classe existante : l'enseignant choisit
/// matiere/niveau/duree parmi des options (donnees en contexte a l'IA), une
/// fiche peut servir a plusieurs classes.
class FicheFormScreen extends StatefulWidget {
  /// true quand l'ecran est un onglet de la barre de navigation (pas de
  /// bouton retour, entete plein comme Classes/Historique) ; false quand il
  /// est pousse par-dessus un autre ecran (ex. action rapide du tableau de
  /// bord), avec un BackHeader classique.
  final bool embedded;

  /// Notifie (valeur incrementee) a chaque retour sur cet onglet depuis un
  /// autre, pour recharger les options matiere/niveau en place (voir
  /// `RootShell.goToTab` / `DashboardScreen.refreshSignal` pour le meme
  /// principe).
  final ValueListenable<int>? refreshSignal;

  const FicheFormScreen({
    super.key,
    this.embedded = false,
    this.refreshSignal,
  });

  @override
  State<FicheFormScreen> createState() => _FicheFormScreenState();
}

class _FicheFormScreenState extends State<FicheFormScreen> {
  final _geminiService = GeminiService();

  final _themeCtrl = TextEditingController();
  final _objectifsCtrl = TextEditingController();
  String? _matiere;
  String? _niveau;
  String? _duree;
  String _langue = 'fr';

  bool _generating = false;
  String? _error;

  /// Memes matieres que celles gerees au niveau de la saisie des notes
  /// (bouton "Gérer" de l'ecran Notes) : union des matieres de toutes les
  /// classes de l'enseignant, dedupliquee. Valeur de depart = matieres par
  /// defaut, remplacee des que les classes sont chargees.
  List<String> _matiereOptions = kMatieresDefaut.map((m) => m.nom).toList();

  /// Meme principe pour les niveaux : union des `Classe.niveau` reellement
  /// utilises par l'enseignant. Valeur de depart = liste generique, remplacee
  /// des que les classes sont chargees (si l'enseignant en a au moins une).
  List<String> _niveauOptions = _kNiveaux;

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_loadOptionsFromClasses);
    _loadOptionsFromClasses();
  }

  Future<void> _loadOptionsFromClasses() async {
    try {
      final classes = await context.read<AppState>().classeService.list();
      if (!mounted || classes.isEmpty) return;

      final matieres = <String>{};
      final niveaux = <String>{};
      for (final c in classes) {
        niveaux.add(c.niveau);
        for (final m in c.matieres) {
          matieres.add(m.nom);
        }
      }
      setState(() {
        if (matieres.isNotEmpty) _matiereOptions = matieres.toList();
        if (niveaux.isNotEmpty) _niveauOptions = niveaux.toList();
      });
    } catch (_) {
      // Listes par defaut deja affichees, pas bloquant pour la generation.
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_loadOptionsFromClasses);
    _themeCtrl.dispose();
    _objectifsCtrl.dispose();
    super.dispose();
  }

  bool get _formValide =>
      _matiere != null && _niveau != null && _themeCtrl.text.trim().isNotEmpty;

  Future<void> _generer() async {
    final app = context.read<AppState>();
    if (!_formValide) {
      setState(() => _error = app.tr('fiche.requiredFields'));
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final contenu = await _geminiService.genererFiche(
        matiere: _matiere!,
        niveau: _niveau!,
        theme: _themeCtrl.text.trim(),
        objectifsSaisis: _objectifsCtrl.text.trim(),
        duree: _duree,
        langue: _langue,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FicheResultScreen(
            matiere: _matiere!,
            niveau: _niveau!,
            theme: _themeCtrl.text.trim(),
            langue: _langue,
            contenu: contenu,
          ),
        ),
      );
    } on GeminiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = app.tr('fiche.genericError'));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.tr('fiche.tabTitle'),
                            style: AppText.sans(
                              size: 22,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.tr('fiche.tabSubtitle'),
                            style: AppText.sans(
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FicheHistoryScreen(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              BackHeader(
                title: app.tr('fiche.formTitle'),
                subtitle: app.tr('fiche.tabSubtitle'),
              ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) ...[
                          ErrorBanner(_error!),
                          const SizedBox(height: 14),
                        ],
                        _OptionChips(
                          label: app.tr('grades.subject'),
                          options: _matiereOptions,
                          selected: _matiere,
                          onSelect: (v) => setState(() => _matiere = v),
                        ),
                        const SizedBox(height: 14),
                        _OptionChips(
                          label: app.tr('fiche.level'),
                          options: _niveauOptions,
                          selected: _niveau,
                          onSelect: (v) => setState(() => _niveau = v),
                        ),
                        const SizedBox(height: 14),
                        LabeledField(
                          label: app.tr('fiche.themeLabel'),
                          hint: 'La division euclidienne',
                          controller: _themeCtrl,
                        ),
                        const SizedBox(height: 14),
                        LabeledField(
                          label: app.tr('fiche.objectivesLabel'),
                          hint:
                              'Ce que les élèves doivent savoir faire à la fin',
                          controller: _objectifsCtrl,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _OptionChips(
                          label: app.tr('fiche.durationLabel'),
                          options: _kDurees,
                          selected: _duree,
                          onSelect: (v) =>
                              setState(() => _duree = v == _duree ? null : v),
                        ),
                        const SizedBox(height: 14),
                        SectionLabel(app.tr('fiche.languageLabel')),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _LangueButton(
                                label: app.tr('lang.fr'),
                                active: _langue == 'fr',
                                onTap: () => setState(() => _langue = 'fr'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LangueButton(
                                label: app.tr('lang.wolof'),
                                active: _langue == 'wolof',
                                onTap: () => setState(() => _langue = 'wolof'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: _generating
                              ? app.tr('fiche.generating')
                              : app.tr('fiche.generate'),
                          onPressed: _generating ? null : _generer,
                        ),
                        if (_generating)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentGreenText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Options a choix unique presentees en puces (chips) horizontales
/// scrollables, donnees telles quelles en contexte au prompt Gemini.
class _OptionChips extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _OptionChips({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.sans(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.textFaint,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final option = options[i];
              final active = option == selected;
              return InkWell(
                onTap: () => onSelect(option),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.brandDark : AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option,
                    style: AppText.sans(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: active ? AppColors.brandGold : AppColors.textDark,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LangueButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangueButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.brandDark : AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 13,
            weight: FontWeight.w700,
            color: active ? AppColors.textOnDark : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
