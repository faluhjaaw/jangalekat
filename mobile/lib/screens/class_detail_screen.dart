import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/classe.dart';
import '../models/eleve.dart';
import '../services/note_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'grades_screen.dart';
import 'student_screen.dart';

class _EleveAvg {
  final Eleve eleve;
  final double? moyenne;
  _EleveAvg(this.eleve, this.moyenne);
}

class ClassDetailScreen extends StatefulWidget {
  final Classe classe;
  const ClassDetailScreen({super.key, required this.classe});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late Classe _classe;
  List<_EleveAvg> _rows = [];
  bool _loading = true;
  bool _error = false;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _classe = widget.classe;
    _load();
    _searchCtrl.addListener(
      () => setState(() => _search = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// `silent` : garde les donnees actuelles affichees pendant le rechargement
  /// (utilise au retour d'un ecran pousse), au lieu de tout remplacer par un
  /// spinner plein ecran a chaque navigation retour.
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final app = context.read<AppState>();
      final eleves = await app.eleveService.listForClasse(_classe.id);
      final results = await Future.wait(
        eleves.map((e) async {
          final notes = await app.noteService.notesEleve(
            _classe.id,
            e.id,
            app.periode,
            _classe.matieres,
          );
          return _EleveAvg(e, NoteService.moyennePonderee(notes));
        }),
      );
      results.sort((a, b) => a.eleve.nom.compareTo(b.eleve.nom));
      if (!mounted) return;
      setState(() {
        _rows = results;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _openAddEleve() async {
    final app = context.read<AppState>();
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCodeCtrl = TextEditingController(text: '221');
    final telNumberCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.tr('classDetail.addStudentSheetTitle'),
                    style: AppText.sans(size: 17, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    ErrorBanner(error!),
                    const SizedBox(height: 12),
                  ],
                  LabeledField(
                    label: app.tr('classDetail.firstName'),
                    controller: prenomCtrl,
                    hint: 'Fatou',
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: app.tr('classDetail.lastName'),
                    controller: nomCtrl,
                    hint: 'Diop',
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: app.tr('classDetail.parentName'),
                    controller: parentCtrl,
                    hint: 'Mme Diop',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.tr('classDetail.parentPhone').toUpperCase(),
                    style: AppText.sans(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.textFaint,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  PhoneField(
                    codeController: telCodeCtrl,
                    numberController: telNumberCtrl,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: app.tr('classDetail.add'),
                    onPressed: () async {
                      if (nomCtrl.text.trim().isEmpty ||
                          prenomCtrl.text.trim().isEmpty ||
                          telNumberCtrl.text.trim().isEmpty) {
                        setSheetState(
                          () => error = app.tr(
                            'classDetail.studentRequiredFields',
                          ),
                        );
                        return;
                      }
                      try {
                        await app.eleveService.create(
                          _classe.id,
                          nom: nomCtrl.text.trim(),
                          prenom: prenomCtrl.text.trim(),
                          telephoneParent: combinePhone(
                            telCodeCtrl,
                            telNumberCtrl,
                          ),
                          nomParent: parentCtrl.text.trim().isEmpty
                              ? null
                              : parentCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (_) {
                        if (ctx.mounted) {
                          setSheetState(
                            () =>
                                error = app.tr('classDetail.addStudentError'),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (created == true) _load(silent: true);
  }

  Future<void> _confirmerSuppression(BuildContext sheetContext) async {
    final app = context.read<AppState>();
    final confirmed = await confirmDelete(
      sheetContext,
      app,
      title: app.tr('classDetail.deleteConfirmTitle'),
      message: app.tr('classDetail.deleteConfirmMessage'),
    );
    if (!confirmed) return;
    try {
      await app.classeService.softDelete(_classe.id);
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          SnackBar(content: Text(app.tr('classDetail.deleteError'))),
        );
      }
    }
  }

  Future<void> _openEditClasse() async {
    final app = context.read<AppState>();
    final nomCtrl = TextEditingController(text: _classe.nom);
    final niveauCtrl = TextEditingController(text: _classe.niveau);
    final updated = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.tr('classDetail.editSheetTitle'),
                    style: AppText.sans(size: 17, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    ErrorBanner(error!),
                    const SizedBox(height: 12),
                  ],
                  LabeledField(
                    label: app.tr('classes.name'),
                    controller: nomCtrl,
                    hint: 'CM2 A',
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: app.tr('classes.level'),
                    controller: niveauCtrl,
                    hint: 'CM2',
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: app.tr('student.save'),
                    onPressed: () async {
                      if (nomCtrl.text.trim().isEmpty ||
                          niveauCtrl.text.trim().isEmpty) {
                        setSheetState(
                          () => error = app.tr('classes.requiredFields'),
                        );
                        return;
                      }
                      try {
                        await app.classeService.update(
                          _classe.id,
                          nom: nomCtrl.text.trim(),
                          niveau: niveauCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (_) {
                        if (ctx.mounted) {
                          setSheetState(
                            () => error = app.tr('classDetail.editError'),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: app.tr('classDetail.deleteClass'),
                    background: AppColors.dangerBg,
                    foreground: AppColors.dangerText,
                    onPressed: () => _confirmerSuppression(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (updated == true && mounted) {
      setState(() {
        _classe = Classe(
          id: _classe.id,
          nom: nomCtrl.text.trim(),
          niveau: niveauCtrl.text.trim(),
          effectif: _classe.effectif,
          matieres: _classe.matieres,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final showSubtitle =
        !(_loading && _rows.isEmpty) && !(_error && _rows.isEmpty);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              title: _classe.nom,
              subtitle: showSubtitle
                  ? '${_rows.length} ${app.tr('classes.summaryStudents')}'
                  : null,
              trailing: InkWell(
                onTap: _openEditClasse,
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_loading && _rows.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreenText,
                      ),
                    );
                  }
                  if (_error && _rows.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: ErrorBanner(app.tr('classDetail.error')),
                    );
                  }

                  final rows = _rows;
                  final moyennes = rows
                      .map((r) => r.moyenne)
                      .whereType<double>()
                      .toList();
                  final classeAvg = moyennes.isEmpty
                      ? null
                      : moyennes.reduce((a, b) => a + b) / moyennes.length;

                  _EleveAvg? best, worst;
                  for (final r in rows) {
                    if (r.moyenne == null) continue;
                    if (best == null || r.moyenne! > best.moyenne!) best = r;
                    if (worst == null || r.moyenne! < worst.moyenne!) worst = r;
                  }

                  final buckets = [
                    ('0-9', 0.0, 10.0, AppColors.dangerText),
                    ('10-11', 10.0, 12.0, AppColors.bucketMid),
                    ('12-13', 12.0, 14.0, AppColors.accentGreenSoft),
                    ('14-20', 14.0, 21.0, AppColors.accentGreenText),
                  ];
                  final counts = buckets
                      .map(
                        (b) =>
                            moyennes.where((m) => m >= b.$2 && m < b.$3).length,
                      )
                      .toList();
                  final maxCount = counts.isEmpty
                      ? 1
                      : counts
                            .reduce((a, b) => a > b ? a : b)
                            .clamp(1, 1 << 30);

                  final filteredRows = _search.isEmpty
                      ? rows
                      : rows
                            .where(
                              (r) => r.eleve.nomComplet.toLowerCase().contains(
                                _search,
                              ),
                            )
                            .toList();

                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                value: classeAvg == null
                                    ? '—'
                                    : classeAvg.toStringAsFixed(1),
                                label: app.tr('classDetail.classAverage'),
                                color: classeAvg == null
                                    ? AppColors.textFaint
                                    : AppColors.avgColor(classeAvg),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 34,
                              color: AppColors.cardBorder,
                            ),
                            Expanded(
                              child: _StatColumn(
                                value: best?.eleve.prenom ?? '—',
                                label: best == null
                                    ? app.tr('classDetail.best')
                                    : '${app.tr('classDetail.best')} · ${best.moyenne!.toStringAsFixed(1)}',
                                color: AppColors.accentGreenText,
                                small: true,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 34,
                              color: AppColors.cardBorder,
                            ),
                            Expanded(
                              child: _StatColumn(
                                value: worst?.eleve.prenom ?? '—',
                                label: worst == null
                                    ? app.tr('classDetail.worst')
                                    : '${app.tr('classDetail.worst')} · ${worst.moyenne!.toStringAsFixed(1)}',
                                color: AppColors.dangerText,
                                small: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionLabel(app.tr('classDetail.distribution')),
                            const SizedBox(height: 8),
                            ...List.generate(buckets.length, (i) {
                              final b = buckets[i];
                              final pct = counts[i] / maxCount;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        b.$1,
                                        style: AppText.sans(
                                          size: 11,
                                          weight: FontWeight.w500,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 10,
                                          backgroundColor: AppColors.card,
                                          valueColor: AlwaysStoppedAnimation(
                                            b.$4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 16,
                                      child: Text(
                                        '${counts[i]}',
                                        textAlign: TextAlign.right,
                                        style: AppText.sans(
                                          size: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: app.tr('classDetail.enterGrades'),
                                onPressed: () => Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            GradesScreen(classe: _classe),
                                      ),
                                    )
                                    .then((_) => _load(silent: true)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                label: app.tr('classDetail.addStudent'),
                                background: AppColors.card,
                                foreground: AppColors.textDark,
                                onPressed: _openAddEleve,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionLabel(app.tr('classDetail.students')),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                style: AppText.sans(
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: app.tr('classDetail.searchHint'),
                                  hintStyle: AppText.sans(
                                    size: 14,
                                    color: AppColors.textFaint,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 19,
                                    color: AppColors.textFaint,
                                  ),
                                  suffixIcon: _search.isEmpty
                                      ? null
                                      : InkWell(
                                          onTap: _searchCtrl.clear,
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: AppColors.textFaint,
                                          ),
                                        ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (filteredRows.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  app.tr('classDetail.noResults'),
                                  style: AppText.sans(
                                    size: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ...filteredRows.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) => StudentScreen(
                                            classe: _classe,
                                            eleve: r.eleve,
                                          ),
                                        ),
                                      )
                                      .then((_) => _load(silent: true)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        InitialsAvatar(
                                          initials: r.eleve.initiales,
                                          size: 38,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            r.eleve.nomComplet,
                                            style: AppText.sans(
                                              size: 14,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        AvgPill(avg: r.moyenne),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool small;
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.sans(
            size: small ? 15 : 20,
            weight: FontWeight.w700,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppText.sans(size: 10.5, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

