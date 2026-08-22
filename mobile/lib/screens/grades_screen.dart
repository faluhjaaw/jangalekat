import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/classe.dart';
import '../models/eleve.dart';
import '../models/matiere.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

class GradesScreen extends StatefulWidget {
  final Classe classe;
  const GradesScreen({super.key, required this.classe});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  bool _loading = true;
  String? _error;
  List<Eleve> _eleves = [];
  final Map<String, Map<String, double?>> _matrix =
      {}; // eleveId -> matiere -> valeur
  /// Copie des valeurs telles que chargees depuis Firestore, pour ne
  /// renvoyer en ecriture que ce qui a reellement change (voir `_dirty`).
  final Map<String, Map<String, double?>> _original = {};

  /// Couples (eleveId, matiere) modifies depuis le dernier chargement/
  /// enregistrement, toutes matieres confondues (pas seulement l'onglet
  /// affiche) : `_save` doit persister les notes saisies sur n'importe quel
  /// onglet, pas uniquement celui actif au moment du clic.
  final Set<(String, String)> _dirty = {};
  final Map<String, TextEditingController> _controllers = {};
  int _subjectIndex = 0;
  bool _saving = false;
  bool _saved = false;
  late List<Matiere> _matieres;

  Matiere get _matiere => _matieres[_subjectIndex];

  @override
  void initState() {
    super.initState();
    _matieres = List.of(widget.classe.matieres);
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final app = context.read<AppState>();
    try {
      final eleves = await app.eleveService.listForClasse(widget.classe.id);
      _matrix.clear();
      await Future.wait(
        eleves.map((e) async {
          final notes = await app.noteService.notesEleve(
            widget.classe.id,
            e.id,
            app.periode,
            _matieres,
          );
          final parMatiere = _matrix.putIfAbsent(e.id, () => {});
          for (final n in notes) {
            parMatiere[n.matiere] = n.valeur;
          }
        }),
      );
      _eleves = eleves;
      _original
        ..clear()
        ..addAll({for (final e in _matrix.entries) e.key: Map.of(e.value)});
      _dirty.clear();
      _rebuildControllers();
    } catch (_) {
      _error = app.tr('grades.loadError');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _rebuildControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    if (_matieres.isEmpty) return;
    for (final e in _eleves) {
      final value = _matrix[e.id]?[_matiere.nom];
      _controllers[e.id] = TextEditingController(
        text: value == null ? '' : _fmt(value),
      );
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  double? _moyenneEleve(String eleveId) {
    final notes = _matrix[eleveId];
    if (notes == null) return null;
    double sommePoints = 0;
    int sommeCoeff = 0;
    for (final m in _matieres) {
      final v = notes[m.nom];
      if (v != null) {
        sommePoints += v * m.coefficient;
        sommeCoeff += m.coefficient;
      }
    }
    if (sommeCoeff == 0) return null;
    return sommePoints / sommeCoeff;
  }

  double? get _moyenneClasseMatiere {
    final values = _eleves
        .map((e) => _matrix[e.id]?[_matiere.nom])
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  void _selectSubject(int index) {
    setState(() {
      _subjectIndex = index;
      _rebuildControllers();
    });
  }

  /// Change de trimestre actif (partage par toute l'app, voir
  /// `AppState.periode`) puis recharge les notes de cette classe pour le
  /// nouveau trimestre : chaque trimestre a ses propres notes en base, il
  /// ne faut jamais melanger celles de deux trimestres a l'ecran.
  Future<void> _selectPeriode(String value) async {
    final app = context.read<AppState>();
    if (value == app.periode) return;
    await app.setPeriode(value);
    if (mounted) _load();
  }

  Future<void> _persistMatieres() async {
    try {
      await context.read<AppState>().classeService.updateMatieres(
        widget.classe.id,
        _matieres,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AppState>().tr('grades.updateMatieresError'),
            ),
          ),
        );
      }
    }
  }

  /// Retirer une matiere ne supprime pas les notes deja saisies pour cette
  /// matiere (elles restent en base, juste plus affichees/modifiables tant
  /// que la matiere n'est pas rajoutee) : pas de suppression en cascade
  /// silencieuse des notes d'un enseignant.
  void _removeMatiere(int index, StateSetter sheetSetState) {
    setState(() {
      _matieres.removeAt(index);
      if (_subjectIndex >= _matieres.length) {
        _subjectIndex = _matieres.length - 1;
      }
      if (_subjectIndex < 0) _subjectIndex = 0;
      if (_matieres.isNotEmpty) _rebuildControllers();
    });
    sheetSetState(() {});
    _persistMatieres();
  }

  void _addMatiere(String nom, int coefficient, StateSetter sheetSetState) {
    final nomTrim = nom.trim();
    if (nomTrim.isEmpty) return;
    if (_matieres.any((m) => m.nom.toLowerCase() == nomTrim.toLowerCase())) {
      return;
    }
    setState(() {
      _matieres.add(Matiere(nomTrim, coefficient));
    });
    sheetSetState(() {});
    _persistMatieres();
  }

  void _openManageMatieres() {
    final app = context.read<AppState>();
    final nomCtrl = TextEditingController();
    final coeffCtrl = TextEditingController(text: '1');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sheetSetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${app.tr('grades.manageTitlePrefix')} · ${widget.classe.nom}',
                  style: AppText.sans(size: 17, weight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                if (_matieres.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      app.tr('grades.noSubjects'),
                      style: AppText.sans(size: 13, color: AppColors.textMuted),
                    ),
                  ),
                ..._matieres.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value.nom,
                              style: AppText.sans(
                                size: 13.5,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'coeff ${entry.value.coefficient}',
                            style: AppText.sans(
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () =>
                                _removeMatiere(entry.key, sheetSetState),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 19,
                                color: AppColors.dangerText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: LabeledField(
                        label: app.tr('grades.newSubject'),
                        hint: 'Musique',
                        controller: nomCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: LabeledField(
                        label: app.tr('grades.coeffLabel'),
                        hint: '1',
                        controller: coeffCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: app.tr('classDetail.add'),
                  background: AppColors.card,
                  foreground: AppColors.textDark,
                  onPressed: () {
                    final coeff = int.tryParse(coeffCtrl.text.trim()) ?? 1;
                    _addMatiere(
                      nomCtrl.text,
                      coeff.clamp(1, 10),
                      sheetSetState,
                    );
                    nomCtrl.clear();
                    coeffCtrl.text = '1';
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onScoreChanged(Eleve e, String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    final clamped = parsed?.clamp(0.0, 20.0);
    final matiere = _matiere.nom;
    setState(() {
      _matrix.putIfAbsent(e.id, () => {})[matiere] = clamped;
      final key = (e.id, matiere);
      if (clamped == _original[e.id]?[matiere]) {
        _dirty.remove(key);
      } else {
        _dirty.add(key);
      }
    });
  }

  Future<void> _save() async {
    if (_dirty.isEmpty) return;
    setState(() => _saving = true);
    try {
      final app = context.read<AppState>();
      final toSave = _dirty.toList();
      final futures = <Future>[];
      for (final (eleveId, matiereNom) in toSave) {
        final v = _matrix[eleveId]?[matiereNom];
        if (v == null) {
          futures.add(
            app.noteService.supprimer(
              widget.classe.id,
              eleveId,
              matiere: matiereNom,
              periode: app.periode,
            ),
          );
          continue;
        }
        final matiere = _matieres.firstWhere(
          (m) => m.nom == matiereNom,
          orElse: () => Matiere(matiereNom, 1),
        );
        futures.add(
          app.noteService.upsert(
            widget.classe.id,
            eleveId,
            matiere: matiereNom,
            valeur: v,
            coefficient: matiere.coefficient,
            periode: app.periode,
          ),
        );
      }
      await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        for (final key in toSave) {
          final (eleveId, matiereNom) = key;
          _original.putIfAbsent(eleveId, () => {})[matiereNom] =
              _matrix[eleveId]?[matiereNom];
          _dirty.remove(key);
        }
        _saving = false;
        _saved = true;
      });
      Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AppState>().tr('grades.saveError')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? Column(
                children: [
                  BackHeader(
                    title: app.tr('grades.title'),
                    subtitle: widget.classe.nom,
                  ),
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreenText,
                      ),
                    ),
                  ),
                ],
              )
            : _error != null
            ? Column(
                children: [
                  BackHeader(
                    title: app.tr('grades.title'),
                    subtitle: widget.classe.nom,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ErrorBanner(_error!),
                  ),
                ],
              )
            : Column(
                children: [
                  BackHeader(
                    title: app.tr('grades.title'),
                    subtitle: widget.classe.nom,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel(app.tr('period.sectionLabel')),
                        const SizedBox(height: 8),
                        Row(
                          children: kPeriodes
                              .map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () => _selectPeriode(p),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p == app.periode
                                            ? AppColors.brandDark
                                            : AppColors.card,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        app.tr('period.${p.toLowerCase()}'),
                                        style: AppText.sans(
                                          size: 12.5,
                                          weight: FontWeight.w700,
                                          color: p == app.periode
                                              ? AppColors.brandGold
                                              : AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SectionLabel(app.tr('grades.subject')),
                            InkWell(
                              onTap: _openManageMatieres,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: [
                                  Text(
                                    app.tr('common.manage'),
                                    style: AppText.sans(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.accentGreenText,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 15,
                                    color: AppColors.accentGreenText,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_matieres.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              app.tr('grades.noSubjectsForClass'),
                              style: AppText.sans(
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        else ...[
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              scrollDirection: Axis.horizontal,
                              itemCount: _matieres.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final active = i == _subjectIndex;
                                return InkWell(
                                  onTap: () => _selectSubject(i),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.brandDark
                                          : AppColors.card,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _matieres[i].nom,
                                      style: AppText.sans(
                                        size: 12.5,
                                        weight: FontWeight.w700,
                                        color: active
                                            ? AppColors.brandGold
                                            : AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${app.tr('grades.coefficient')} ${_matiere.coefficient} · ${app.periodeLabel}',
                            style: AppText.sans(
                              size: 11.5,
                              color: AppColors.textFaint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_matieres.isEmpty) const Spacer(),
                  if (_matieres.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                        itemCount: _eleves.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = _eleves[i];
                          final moyenne = _moyenneEleve(e.id);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                InitialsAvatar(initials: e.initiales, size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.nomComplet,
                                        style: AppText.sans(
                                          size: 13.5,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: app.tr('grades.average'),
                                              style: AppText.sans(
                                                size: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            TextSpan(
                                              text: moyenne == null
                                                  ? '—'
                                                  : moyenne.toStringAsFixed(1),
                                              style: AppText.sans(
                                                size: 11,
                                                weight: FontWeight.w700,
                                                color: moyenne == null
                                                    ? AppColors.textFaint
                                                    : AppColors.avgColor(
                                                        moyenne,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 52,
                                  child: TextField(
                                    controller: _controllers[e.id],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [_MaxScoreFormatter()],
                                    textAlign: TextAlign.center,
                                    style: AppText.sans(
                                      size: 14,
                                      weight: FontWeight.w700,
                                    ),
                                    onChanged: (v) => _onScoreChanged(e, v),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: AppColors.background,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 9,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: AppColors.cardBorder,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (_matieres.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                          top: BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${app.tr('grades.classAverage')}${_matiere.nom}',
                                style: AppText.sans(
                                  size: 12.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                _moyenneClasseMatiere == null
                                    ? '—/20'
                                    : '${_moyenneClasseMatiere!.toStringAsFixed(1)}/20',
                                style: AppText.sans(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: AppColors.accentGreenText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PrimaryButton(
                            label: _saving
                                ? app.tr('grades.saving')
                                : (_saved
                                      ? app.tr('grades.saved')
                                      : app.tr('grades.save')),
                            background: _saved
                                ? AppColors.accentGreenSoft
                                : AppColors.accentGreen,
                            onPressed: _saving || _dirty.isEmpty ? null : _save,
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

/// Empeche de saisir une note superieure a 20 : rejette la modification si le
/// texte resultant se parse en un nombre > 20 (accepte '' et les saisies en
/// cours comme '1' ou '19,' qui ne parsent pas encore en nombre valide).
class _MaxScoreFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = double.tryParse(newValue.text.replaceAll(',', '.'));
    if (value != null && value > 20) return oldValue;
    return newValue;
  }
}
