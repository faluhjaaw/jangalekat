import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fiche_cours.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'fiche_result_screen.dart';

/// Historique des fiches de cours enregistrees par l'enseignant.
class FicheHistoryScreen extends StatefulWidget {
  const FicheHistoryScreen({super.key});

  @override
  State<FicheHistoryScreen> createState() => _FicheHistoryScreenState();
}

class _FicheHistoryScreenState extends State<FicheHistoryScreen> {
  List<FicheCours> _fiches = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final fiches = await context.read<AppState>().ficheService.historique();
      if (!mounted) return;
      setState(() {
        _fiches = fiches;
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

  String _dateLabel(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              title: app.tr('fiche.historyTitle'),
              subtitle: app.tr('nav.history'),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accentGreenText,
                onRefresh: () => _load(silent: true),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (_loading && _fiches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGreenText,
                          ),
                        ),
                      )
                    else if (_error && _fiches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ErrorBanner(app.tr('fiche.historyLoadError')),
                      )
                    else if (_fiches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                        child: Center(
                          child: Text(
                            app.tr('fiche.historyEmpty'),
                            style: AppText.sans(
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: _fiches
                              .map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _FicheCard(
                                    fiche: f,
                                    dateLabel: _dateLabel(f.dateCreation),
                                    onTap: () => Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => FicheResultScreen(
                                              matiere: f.matiere,
                                              niveau: f.niveau,
                                              theme: f.theme,
                                              langue: f.langue,
                                              contenu: f.contenu,
                                              ficheId: f.id,
                                              dateCreation: f.dateCreation,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FicheCard extends StatelessWidget {
  final FicheCours fiche;
  final String dateLabel;
  final VoidCallback onTap;
  const _FicheCard({
    required this.fiche,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accentGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 18,
                color: AppColors.accentGreenText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fiche.theme,
                    style: AppText.sans(size: 14, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fiche.matiere} · ${fiche.niveau}',
                    style: AppText.sans(size: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              dateLabel,
              style: AppText.sans(size: 11.5, color: AppColors.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
