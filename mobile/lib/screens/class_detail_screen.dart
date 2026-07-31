import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
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
  late Future<List<_EleveAvg>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_EleveAvg>> _load() async {
    final app = context.read<AppState>();
    final eleves = await app.eleveService.listForClasse(widget.classe.id);
    final results = await Future.wait(
      eleves.map((e) async {
        final notes = await app.noteService.notesEleve(
          widget.classe.id,
          e.id,
          kPeriodeActuelle,
          widget.classe.matieres,
        );
        return _EleveAvg(e, NoteService.moyennePonderee(notes));
      }),
    );
    results.sort((a, b) => a.eleve.nom.compareTo(b.eleve.nom));
    return results;
  }

  void _reload() => setState(() {
    _future = _load();
  });

  Future<void> _openAddEleve() async {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                'Ajouter un élève',
                style: AppText.sans(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _MiniField(label: 'Prénom', controller: prenomCtrl),
              const SizedBox(height: 12),
              _MiniField(label: 'Nom', controller: nomCtrl),
              const SizedBox(height: 12),
              _MiniField(label: 'Nom du parent', controller: parentCtrl),
              const SizedBox(height: 12),
              _MiniField(
                label: 'Téléphone parent',
                controller: telCtrl,
                hint: '+221 77 000 00 00',
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Ajouter',
                onPressed: () async {
                  if (nomCtrl.text.trim().isEmpty ||
                      prenomCtrl.text.trim().isEmpty ||
                      telCtrl.text.trim().isEmpty) {
                    return;
                  }
                  try {
                    await context.read<AppState>().eleveService.create(
                      widget.classe.id,
                      nom: nomCtrl.text.trim(),
                      prenom: prenomCtrl.text.trim(),
                      telephoneParent: telCtrl.text.trim(),
                      nomParent: parentCtrl.text.trim().isEmpty
                          ? null
                          : parentCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  } catch (_) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible d\'ajouter l\'élève'),
                        ),
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
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<_EleveAvg>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                children: [
                  BackHeader(title: widget.classe.nom),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreenText,
                      ),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  BackHeader(title: widget.classe.nom),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ErrorBanner('Impossible de charger la classe'),
                  ),
                ],
              );
            }

            final rows = snapshot.data!;
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
                .map((b) => moyennes.where((m) => m >= b.$2 && m < b.$3).length)
                .toList();
            final maxCount = counts.isEmpty
                ? 1
                : counts.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                BackHeader(
                  title: widget.classe.nom,
                  subtitle: '${rows.length} élèves',
                ),
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
                          label: 'Moyenne classe',
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
                              ? 'Meilleur'
                              : 'Meilleur · ${best.moyenne!.toStringAsFixed(1)}',
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
                              ? 'Plus faible'
                              : 'Plus faible · ${worst.moyenne!.toStringAsFixed(1)}',
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
                      const SectionLabel('Répartition des moyennes'),
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
                                  style: AppText.mono(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 10,
                                    backgroundColor: AppColors.card,
                                    valueColor: AlwaysStoppedAnimation(b.$4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                child: Text(
                                  '${counts[i]}',
                                  textAlign: TextAlign.right,
                                  style: AppText.mono(
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
                          label: 'Saisir les notes',
                          onPressed: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GradesScreen(classe: widget.classe),
                                ),
                              )
                              .then((_) => _reload()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: '+ Ajouter un élève',
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
                      const SectionLabel('Élèves'),
                      const SizedBox(height: 8),
                      ...rows.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentScreen(
                                      classe: widget.classe,
                                      eleve: r.eleve,
                                    ),
                                  ),
                                )
                                .then((_) => _reload()),
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
          style: AppText.mono(
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

class _MiniField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  const _MiniField({required this.label, required this.controller, this.hint});

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
