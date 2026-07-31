import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/classe_summary.dart';
import '../models/message_models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'class_detail_screen.dart';
import 'grades_screen.dart';
import 'whatsapp_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onGoToTab;
  const DashboardScreen({super.key, required this.onGoToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final app = context.read<AppState>();
    final summaries = await app.loadClasseSummaries();
    final messages = await app.messageService.historique();
    return _DashboardData(
      summaries: summaries,
      recentMessages: messages.take(3).toList(),
    );
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() {
      _future = f;
    });
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final enseignant = app.enseignant;

    return RefreshIndicator(
      color: AppColors.accentGreenText,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${enseignant?.nom ?? ''}',
                        style: AppText.sans(size: 22, weight: FontWeight.w700),
                      ),
                      if (enseignant?.ecole != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            enseignant!.ecole!,
                            style: AppText.sans(
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: app.toggleOffline,
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
                      app.offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                      size: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (app.offline)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 18,
                      color: AppColors.warningText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hors ligne — les modifications seront synchronisées plus tard',
                        style: AppText.sans(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FutureBuilder<_DashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGreenText,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ErrorBanner(
                    'Impossible de charger le tableau de bord',
                  ),
                );
              }
              final data = snapshot.data!;
              final classCount = data.summaries.length;
              final studentCount = data.summaries.fold<int>(
                0,
                (a, c) => a + c.studentCount,
              );
              final moyennes = data.summaries
                  .map((c) => c.moyenne)
                  .whereType<double>()
                  .toList();
              final schoolAvg = moyennes.isEmpty
                  ? null
                  : moyennes.reduce((a, b) => a + b) / moyennes.length;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: '$classCount',
                            label: 'Classes',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            value: '$studentCount',
                            label: 'Élèves',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            value: schoolAvg == null
                                ? '—'
                                : schoolAvg.toStringAsFixed(1),
                            label: 'Moyenne école',
                            highlight: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Actions rapides',
                            style: AppText.sans(
                              size: 13,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.edit_note_rounded,
                                label: 'Saisir des notes',
                                dark: true,
                                onTap: data.summaries.isEmpty
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => GradesScreen(
                                            classe: data.summaries.first.classe,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.chat_bubble_rounded,
                                label: 'Envoyer aux parents',
                                accent: true,
                                onTap: data.summaries.isEmpty
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => WhatsappScreen(
                                            classe: data.summaries.first.classe,
                                            eleves: data.summaries.first.eleves,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.groups_rounded,
                                label: 'Mes classes',
                                onTap: () => widget.onGoToTab(1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.history_rounded,
                                label: 'Historique',
                                onTap: () => widget.onGoToTab(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _QuickAction(
                            icon: Icons.auto_stories_rounded,
                            label: 'Fiches de cours (IA)',
                            onTap: () => widget.onGoToTab(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mes classes',
                              style: AppText.sans(
                                size: 13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.onGoToTab(1),
                              child: Text(
                                'Voir tout',
                                style: AppText.sans(
                                  size: 12.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.accentGreenText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...data.summaries.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ClasseRow(
                              summary: c,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClassDetailScreen(classe: c.classe),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dernières activités',
                              style: AppText.sans(
                                size: 13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.onGoToTab(2),
                              child: Text(
                                'Voir tout',
                                style: AppText.sans(
                                  size: 12.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.accentGreenText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (data.recentMessages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Aucune activité récente',
                              style: AppText.sans(
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ...data.recentMessages.map(
                          (m) => _ActivityRow(message: m),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final List<ClasseSummary> summaries;
  final List<MessageEntry> recentMessages;
  _DashboardData({required this.summaries, required this.recentMessages});
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  const _StatTile({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accentGreenBg : AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.mono(
              size: 22,
              weight: FontWeight.w700,
              color: highlight ? AppColors.accentGreenText : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.sans(size: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;
  final bool accent;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.dark = false,
    this.accent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark
        ? AppColors.brandDark
        : (accent ? AppColors.accentGreen : AppColors.card);
    final fg = dark
        ? AppColors.brandGold
        : (accent ? AppColors.accentGreenDarkText : AppColors.accentGreenText);
    final labelColor = dark
        ? AppColors.textOnDark
        : (accent ? AppColors.accentGreenDarkText : AppColors.textDark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: !dark && !accent
                ? Border.all(color: AppColors.cardBorder)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppText.sans(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClasseRow extends StatelessWidget {
  final ClasseSummary summary;
  final VoidCallback onTap;
  const _ClasseRow({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.classe.nom,
                    style: AppText.sans(size: 14.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${summary.studentCount} élèves',
                    style: AppText.sans(size: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            AvgPill(avg: summary.moyenne, fontSize: 14),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final MessageEntry message;
  const _ActivityRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 16,
              color: AppColors.accentGreenText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message envoyé à ${message.eleveNom}',
                  style: AppText.sans(size: 13, weight: FontWeight.w600),
                ),
                Text(
                  formatRelativeTime(message.dateEnvoi),
                  style: AppText.sans(size: 11.5, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatRelativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) {
    return "Aujourd'hui · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
  if (diff.inDays == 1) {
    return "Hier · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
  return '${dt.day}/${dt.month} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
