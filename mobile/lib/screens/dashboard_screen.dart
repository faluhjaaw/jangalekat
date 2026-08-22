import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/classe_summary.dart';
import '../models/message_models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'class_detail_screen.dart';
import 'grades_screen.dart';
import 'recommendation_screen.dart';
import 'support_screen.dart';
import 'whatsapp_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onGoToTab;

  /// Notifie (valeur incrementee) par `RootShell` a chaque retour sur cet
  /// onglet depuis un autre : declenche un rechargement en place (les
  /// chiffres se mettent a jour sans reconstruire tout l'ecran), puisque
  /// l'`IndexedStack` du shell garde ce widget monte en permanence et ne
  /// rappelle jamais `initState` tout seul.
  final ValueListenable<int>? refreshSignal;

  const DashboardScreen({
    super.key,
    required this.onGoToTab,
    this.refreshSignal,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashboardData? _data;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_load);
    final app = context.read<AppState>();
    final summaries = app.cachedDashboardSummaries;
    final messages = app.cachedDashboardMessages;
    if (summaries != null && messages != null) {
      // Donnees deja prechargees pendant le splash (voir
      // `AppState.restoreSession`) : on les consomme directement au lieu de
      // refaire l'appel reseau. Usage unique : le cache est vide pour les
      // chargements suivants (pull-to-refresh, retour d'ecran...).
      app.cachedDashboardSummaries = null;
      app.cachedDashboardMessages = null;
      _data = _DashboardData(
        summaries: summaries,
        recentMessages: messages.take(3).toList(),
      );
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_load);
    super.dispose();
  }

  /// Toujours silencieux : jamais de spinner plein ecran, meme au premier
  /// chargement. Tant que `_data` est `null`, l'ecran reste simplement vide
  /// (rien d'affiche sous l'entete) le temps de la reponse — c'est souvent
  /// instantane grace au cache hors-ligne Firestore. Le pull-to-refresh a
  /// deja son propre indicateur visuel (`RefreshIndicator`).
  Future<void> _load() async {
    try {
      final app = context.read<AppState>();
      final summaries = await app.loadClasseSummaries();
      final messages = await app.messageService.historique();
      if (!mounted) return;
      setState(() {
        _data = _DashboardData(
          summaries: summaries,
          recentMessages: messages.take(3).toList(),
        );
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  /// Utilise par les actions rapides "Saisir des notes" et "Envoyer aux
  /// parents" : `WhatsappScreen` selectionne un eleve par defaut a
  /// l'ouverture (`_eleves.first`), lui passer une classe sans eleve la
  /// ferait planter ; pour "Saisir des notes", ouvrir une classe vide n'a
  /// aucun interet non plus. On cherche donc la premiere classe qui a au
  /// moins un eleve plutot que de prendre `summaries.first` sans condition.
  ClasseSummary? _premiereClasseAvecEleves(_DashboardData data) {
    for (final s in data.summaries) {
      if (s.eleves.isNotEmpty) return s;
    }
    return null;
  }

  Future<void> _selectPeriode(String value) async {
    final app = context.read<AppState>();
    if (value == app.periode) return;
    await app.setPeriode(value);
    _load();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer<AppState>(
        builder: (context, app, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                app.tr('settings.title'),
                style: AppText.sans(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SectionLabel(app.tr('settings.language')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SettingsLangPill(
                      label: 'FR',
                      active: app.locale == AppLocale.fr,
                      onTap: () => app.setLocale(AppLocale.fr),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SettingsLangPill(
                      label: 'EN',
                      active: app.locale == AppLocale.en,
                      onTap: () => app.setLocale(AppLocale.en),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionLabel(app.tr('settings.darkMode')),
                  Switch(
                    value: app.darkMode,
                    activeTrackColor: AppColors.accentGreen,
                    onChanged: (v) => app.setDarkMode(v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsLinkRow(
                label: app.tr('settings.support'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _SettingsLinkRow(
                label: app.tr('settings.recommendations'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecommendationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: app.tr('settings.logout'),
                background: AppColors.dangerBg,
                foreground: AppColors.dangerText,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  app.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final enseignant = app.enseignant;

    return Column(
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
                      '${app.tr('dashboard.greeting')}, ${enseignant?.nom ?? ''}',
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
                onTap: app.toggleDemoOfflineView,
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
                    app.demoOfflineView ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    size: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openSettings,
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
                    Icons.person_rounded,
                    size: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
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
                          borderRadius: BorderRadius.circular(999),
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
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accentGreenText,
            onRefresh: () => _load(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                if (!app.emailVerified) const _VerifyEmailBanner(),
                if (app.demoOfflineView)
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
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 18,
                            color: AppColors.warningText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              app.tr('dashboard.offlineBanner'),
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
                Builder(
                  builder: (context) {
                    if (_error && _data == null) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: ErrorBanner(app.tr('dashboard.error')),
                      );
                    }
                    if (_data == null) {
                      // Chargement silencieux : rien n'est affiche ici tant
                      // que les donnees n'arrivent pas (voir `_load`), pas
                      // de spinner plein ecran.
                      return const SizedBox.shrink();
                    }
                    final data = _data!;
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
                                  label: app.tr('dashboard.statClasses'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatTile(
                                  value: '$studentCount',
                                  label: app.tr('dashboard.statStudents'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatTile(
                                  value: schoolAvg == null
                                      ? '—'
                                      : schoolAvg.toStringAsFixed(1),
                                  label: app.tr('dashboard.statSchoolAvg'),
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
                                  app.tr('dashboard.quickActions'),
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
                                      label: app.tr('dashboard.actionGrades'),
                                      dark: true,
                                      onTap: _premiereClasseAvecEleves(data) == null
                                          ? null
                                          : () => Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        GradesScreen(
                                                          classe:
                                                              _premiereClasseAvecEleves(
                                                                data,
                                                              )!.classe,
                                                        ),
                                                  ),
                                                )
                                                .then((_) => _load()),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _QuickAction(
                                      icon: Icons.chat_bubble_rounded,
                                      label: app.tr('dashboard.actionWhatsapp'),
                                      accent: true,
                                      onTap: _premiereClasseAvecEleves(data) == null
                                          ? null
                                          : () => Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        WhatsappScreen(
                                                          classe:
                                                              _premiereClasseAvecEleves(
                                                                data,
                                                              )!.classe,
                                                          eleves:
                                                              _premiereClasseAvecEleves(
                                                                data,
                                                              )!.eleves,
                                                          allClasses:
                                                              data.summaries,
                                                        ),
                                                  ),
                                                )
                                                .then((_) => _load()),
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
                                      label: app.tr('dashboard.actionClasses'),
                                      onTap: () => widget.onGoToTab(1),
                                      ripple: false,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _QuickAction(
                                      icon: Icons.history_rounded,
                                      label: app.tr('dashboard.actionHistory'),
                                      onTap: () => widget.onGoToTab(2),
                                      ripple: false,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: _QuickAction(
                                  icon: Icons.auto_stories_rounded,
                                  label: app.tr('dashboard.actionFiches'),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    app.tr('dashboard.myClasses'),
                                    style: AppText.sans(
                                      size: 13,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => widget.onGoToTab(1),
                                    child: Text(
                                      app.tr('common.seeAll'),
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
                                    onTap: () => Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => ClassDetailScreen(
                                              classe: c.classe,
                                            ),
                                          ),
                                        )
                                        .then((_) => _load()),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    app.tr('dashboard.recentActivity'),
                                    style: AppText.sans(
                                      size: 13,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => widget.onGoToTab(2),
                                    child: Text(
                                      app.tr('common.seeAll'),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    app.tr('dashboard.noRecentActivity'),
                                    style: AppText.sans(
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ...data.recentMessages.map(
                                (m) => _ActivityRow(
                                  message: m,
                                  onChanged: () => _load(),
                                ),
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
          ),
        ),
      ],
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
            style: AppText.sans(
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

  /// `false` : aucun retour tactile (ni ripple, ni surbrillance) au tap —
  /// pour "Mes classes"/"Historique", ou le ripple restait visible a
  /// l'ecran apres le changement instantane d'onglet (l'`IndexedStack` du
  /// shell ne demonte jamais cette carte, l'animation du splash pouvait
  /// donc rester "figee" au lieu de terminer son fondu normalement).
  final bool ripple;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.dark = false,
    this.accent = false,
    this.onTap,
    this.ripple = true,
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
      splashColor: ripple ? null : Colors.transparent,
      highlightColor: ripple ? null : Colors.transparent,
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
  final VoidCallback onChanged;
  const _ActivityRow({required this.message, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return InkWell(
      onTap: () =>
          showMessageDetailSheet(context, app, message, onDeleted: onChanged),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
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
              child: Icon(
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
                    '${app.tr('dashboard.messageSentTo')} ${message.eleveNom}',
                    style: AppText.sans(size: 13, weight: FontWeight.w600),
                  ),
                  Text(
                    formatRelativeTime(app, message.dateEnvoi),
                    style: AppText.sans(size: 11.5, color: AppColors.textFaint),
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

class _SettingsLinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SettingsLinkRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppText.sans(size: 14, weight: FontWeight.w600),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLangPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SettingsLangPill({
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

/// Bannière incitant a verifier l'adresse email (lien envoye par Firebase a
/// l'inscription, voir `AuthService.register`) : disparait des que
/// `AppState.emailVerified` passe a `true`, apres clic sur "J'ai verifie"
/// (le SDK Firebase ne detecte pas tout seul qu'un lien a ete clique, il
/// faut explicitement recharger l'utilisateur).
class _VerifyEmailBanner extends StatefulWidget {
  const _VerifyEmailBanner();

  @override
  State<_VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends State<_VerifyEmailBanner> {
  bool _busy = false;

  Future<void> _resend() async {
    final app = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await app.resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.tr('dashboard.verifyEmailSent'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.tr('dashboard.verifyEmailError'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    final app = context.read<AppState>();
    setState(() => _busy = true);
    await app.refreshEmailVerified();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!app.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(app.tr('dashboard.verifyEmailStillNot'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mark_email_unread_rounded,
                  size: 18,
                  color: AppColors.warningText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    app.tr('dashboard.verifyEmailBanner'),
                    style: AppText.sans(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.warningText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: Text(
                    app.tr('dashboard.verifyEmailResend'),
                    style: AppText.sans(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.warningText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _check,
                  child: Text(
                    app.tr('dashboard.verifyEmailCheck'),
                    style: AppText.sans(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.warningText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatRelativeTime(AppState app, DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  final en = app.locale == AppLocale.en;
  if (diff.inMinutes < 1) return app.tr('time.justNow');
  if (diff.inHours < 1) {
    return en ? '${diff.inMinutes} min ago' : 'Il y a ${diff.inMinutes} min';
  }
  final heure =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (diff.inDays < 1) return '${app.tr('time.today')} · $heure';
  if (diff.inDays == 1) return '${app.tr('time.yesterday')} · $heure';
  return '${dt.day}/${dt.month} · $heure';
}
