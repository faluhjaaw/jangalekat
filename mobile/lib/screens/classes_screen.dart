import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/classe_summary.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'class_detail_screen.dart';

class ClassesScreen extends StatefulWidget {
  final ValueChanged<int> onGoToTab;
  const ClassesScreen({super.key, required this.onGoToTab});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  late Future<List<ClasseSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().loadClasseSummaries();
  }

  Future<void> _reload() async {
    final f = context.read<AppState>().loadClasseSummaries();
    setState(() {
      _future = f;
    });
    await f;
  }

  Future<void> _openCreateClasse() async {
    final nomCtrl = TextEditingController();
    final niveauCtrl = TextEditingController();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajouter une classe',
              style: AppText.sans(size: 17, weight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _SheetField(label: 'Nom', hint: 'CM2 A', controller: nomCtrl),
            const SizedBox(height: 12),
            _SheetField(label: 'Niveau', hint: 'CM2', controller: niveauCtrl),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Créer la classe',
              onPressed: () async {
                if (nomCtrl.text.trim().isEmpty ||
                    niveauCtrl.text.trim().isEmpty) {
                  return;
                }
                try {
                  await context.read<AppState>().classeService.create(
                    nom: nomCtrl.text.trim(),
                    niveau: niveauCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Impossible de créer la classe'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accentGreenText,
      onRefresh: _reload,
      child: FutureBuilder<List<ClasseSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGreenText,
              ),
            );
          }
          final summaries = snapshot.data ?? [];
          final studentTotal = summaries.fold<int>(
            0,
            (a, c) => a + c.studentCount,
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes classes',
                      style: AppText.sans(size: 22, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summaries.length} classes · $studentTotal élèves',
                      style: AppText.sans(size: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ErrorBanner('Impossible de charger les classes'),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: summaries
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ClasseCard(
                            summary: s,
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ClassDetailScreen(classe: s.classe),
                                  ),
                                )
                                .then((_) => _reload()),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: OutlinedButton(
                  onPressed: _openCreateClasse,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AppColors.dashedBorder,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '+ Ajouter une classe',
                    style: AppText.sans(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClasseCard extends StatelessWidget {
  final ClasseSummary summary;
  final VoidCallback onTap;
  const _ClasseCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            InitialsAvatar(initials: summary.classe.nom, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.classe.nom,
                    style: AppText.sans(size: 15.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${summary.studentCount} élèves',
                    style: AppText.sans(size: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AvgPill(avg: summary.moyenne, fontSize: 14),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textFaint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  const _SheetField({
    required this.label,
    required this.hint,
    required this.controller,
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
