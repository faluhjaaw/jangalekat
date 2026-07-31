import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
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
    try {
      final app = context.read<AppState>();
      final eleves = await app.eleveService.listForClasse(widget.classe.id);
      await Future.wait(
        eleves.map((e) async {
          final notes = await app.noteService.notesEleve(
            widget.classe.id,
            e.id,
            kPeriodeActuelle,
            _matieres,
          );
          final parMatiere = _matrix.putIfAbsent(e.id, () => {});
          for (final n in notes) {
            parMatiere[n.matiere] = n.valeur;
          }
        }),
      );
      _eleves = eleves;
      _rebuildControllers();
    } catch (_) {
      _error = 'Impossible de charger les notes';
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

  Future<void> _persistMatieres() async {
    try {
      await context.read<AppState>().classeService.updateMatieres(
        widget.classe.id,
        _matieres,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour des matières')),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matières · ${widget.classe.nom}',
                  style: AppText.sans(size: 17, weight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                if (_matieres.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Aucune matière — ajoutez-en une ci-dessous',
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
                            style: AppText.mono(
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () =>
                                _removeMatiere(entry.key, sheetSetState),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
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
                      child: _SheetMiniField(
                        label: 'Nouvelle matière',
                        hint: 'Musique',
                        controller: nomCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: _SheetMiniField(
                        label: 'Coeff',
                        hint: '1',
                        controller: coeffCtrl,
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Ajouter',
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
    setState(() => _matrix.putIfAbsent(e.id, () => {})[_matiere.nom] = clamped);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final app = context.read<AppState>();
      final futures = <Future>[];
      for (final e in _eleves) {
        final v = _matrix[e.id]?[_matiere.nom];
        if (v == null) continue;
        futures.add(
          app.noteService.upsert(
            widget.classe.id,
            e.id,
            matiere: _matiere.nom,
            valeur: v,
            coefficient: _matiere.coefficient,
            periode: kPeriodeActuelle,
          ),
        );
      }
      await Future.wait(futures);
      if (!mounted) return;
      setState(() {
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
          const SnackBar(content: Text('Échec de l\'enregistrement')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? Column(
                children: [
                  BackHeader(
                    title: 'Saisir les notes',
                    subtitle: widget.classe.nom,
                  ),
                  const Expanded(
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
                    title: 'Saisir les notes',
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
                    title: 'Saisir les notes',
                    subtitle: widget.classe.nom,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionLabel('Matière'),
                            InkWell(
                              onTap: _openManageMatieres,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: [
                                  Text(
                                    'Gérer',
                                    style: AppText.sans(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.accentGreenText,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
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
                              'Aucune matière pour cette classe — appuyez sur "Gérer" pour en ajouter.',
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
                            'Coefficient ${_matiere.coefficient} · $kPeriodeLabel',
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
                                              text: 'Moyenne : ',
                                              style: AppText.sans(
                                                size: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            TextSpan(
                                              text: moyenne == null
                                                  ? '—'
                                                  : moyenne.toStringAsFixed(1),
                                              style: AppText.mono(
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
                                    textAlign: TextAlign.center,
                                    style: AppText.mono(
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
                                        borderSide: const BorderSide(
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
                      decoration: const BoxDecoration(
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
                                'Moyenne classe · ${_matiere.nom}',
                                style: AppText.sans(
                                  size: 12.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                _moyenneClasseMatiere == null
                                    ? '—/20'
                                    : '${_moyenneClasseMatiere!.toStringAsFixed(1)}/20',
                                style: AppText.mono(
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
                                ? 'Enregistrement...'
                                : (_saved
                                      ? 'Notes enregistrées ✓'
                                      : 'Enregistrer'),
                            background: _saved
                                ? AppColors.accentGreenSoft
                                : AppColors.accentGreen,
                            onPressed: _saving ? null : _save,
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

class _SheetMiniField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool numeric;
  const _SheetMiniField({
    required this.label,
    required this.hint,
    required this.controller,
    this.numeric = false,
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
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            style: AppText.sans(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.sans(size: 15, color: AppColors.textFaint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
