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
  List<ClasseSummary> _summaries = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// `silent` : ne montre pas le spinner plein ecran, garde les donnees
  /// affichees pendant le rechargement (utilise au retour d'un ecran pousse,
  /// pour eviter le flash "page qui recharge" au bouton retour).
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await context.read<AppState>().loadClasseSummaries();
      if (!mounted) return;
      setState(() {
        _summaries = data;
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

  Future<void> _openCreateClasse() async {
    final app = context.read<AppState>();
    final nomCtrl = TextEditingController();
    final niveauCtrl = TextEditingController();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.tr('classes.sheetTitle'),
                  style: AppText.sans(size: 17, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (error != null) ...[
                  ErrorBanner(error!),
                  const SizedBox(height: 12),
                ],
                LabeledField(
                  label: app.tr('classes.name'),
                  hint: 'CM2 A',
                  controller: nomCtrl,
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: app.tr('classes.level'),
                  hint: 'CM2',
                  controller: niveauCtrl,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: app.tr('classes.create'),
                  onPressed: () async {
                    if (nomCtrl.text.trim().isEmpty ||
                        niveauCtrl.text.trim().isEmpty) {
                      setSheetState(
                        () => error = app.tr('classes.requiredFields'),
                      );
                      return;
                    }
                    try {
                      await app.classeService.create(
                        nom: nomCtrl.text.trim(),
                        niveau: niveauCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    } catch (_) {
                      if (ctx.mounted) {
                        setSheetState(
                          () => error = app.tr('classes.createError'),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (created == true) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final summaries = _summaries;
    final studentTotal = summaries.fold<int>(0, (a, c) => a + c.studentCount);

    // Pas de retour tactile (ripple) sur cet ecran, contrairement au reste
    // de l'app : les cartes de classe ne sont pas concernees par le style
    // de feedback global demande ailleurs.
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.tr('classes.title'),
                  style: AppText.sans(size: 22, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${summaries.length} ${app.tr('classes.summaryClasses')} · $studentTotal ${app.tr('classes.summaryStudents')}',
                  style: AppText.sans(size: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentGreenText,
              onRefresh: () => _load(silent: true),
              child: Builder(
                builder: (context) {
                  if (_loading && _summaries.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreenText,
                      ),
                    );
                  }

                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (_error)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ErrorBanner(app.tr('classes.error')),
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
                                            builder: (_) => ClassDetailScreen(
                                              classe: s.classe,
                                            ),
                                          ),
                                        )
                                        .then((_) => _load(silent: true)),
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
                            side: BorderSide(
                              color: AppColors.dashedBorder,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            app.tr('classes.add'),
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
            ),
          ),
        ],
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
    final app = context.watch<AppState>();
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
            InitialsAvatar(initials: summary.classe.initiales, size: 46),
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
                    '${summary.studentCount} ${app.tr('classes.summaryStudents')}',
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
                Icon(
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
