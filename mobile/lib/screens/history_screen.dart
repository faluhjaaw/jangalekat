import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message_models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  final ValueChanged<int> onGoToTab;
  const HistoryScreen({super.key, required this.onGoToTab});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MessageEntry> _messages = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// `silent` : garde l'historique actuel affiche pendant le rechargement
  /// (pull-to-refresh a deja son propre indicateur, pas besoin d'un spinner
  /// plein ecran en plus).
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final messages = await context
          .read<AppState>()
          .messageService
          .historique();
      if (!mounted) return;
      setState(() {
        _messages = messages;
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

  String _dayLabel(DateTime dt, AppState app) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return app.tr('time.today');
    if (day == today.subtract(const Duration(days: 1))) {
      return app.tr('time.yesterday');
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // Pas de retour tactile (ripple) sur cet ecran, contrairement au reste
    // de l'app.
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.tr('history.title'),
                  style: AppText.sans(size: 22, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  app.tr('history.subtitle'),
                  style: AppText.sans(size: 13, color: AppColors.textMuted),
                ),
              ],
            ),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: app.demoOfflineView
                            ? AppColors.warningBg
                            : AppColors.accentGreenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              app.demoOfflineView
                                  ? app.tr('history.pendingSync')
                                  : app.tr('history.synced'),
                              style: AppText.sans(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: app.demoOfflineView
                                    ? AppColors.warningText
                                    : AppColors.accentGreenText,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: app.toggleDemoOfflineView,
                            child: Text(
                              app.demoOfflineView
                                  ? app.tr('history.reconnect')
                                  : app.tr('history.view'),
                              style: AppText.sans(
                                size: 12,
                                weight: FontWeight.w700,
                                color: app.demoOfflineView
                                    ? AppColors.warningText
                                    : AppColors.accentGreenText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      if (_loading && _messages.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentGreenText,
                            ),
                          ),
                        );
                      }
                      if (_error && _messages.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: ErrorBanner(app.tr('history.loadError')),
                        );
                      }
                      final messages = _messages;
                      if (messages.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                          child: Center(
                            child: Text(
                              app.tr('history.noActivity'),
                              style: AppText.sans(
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      }

                      final Map<String, List<MessageEntry>> grouped = {};
                      for (final m in messages) {
                        grouped
                            .putIfAbsent(_dayLabel(m.dateEnvoi, app), () => [])
                            .add(m);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: grouped.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: AppText.sans(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: AppColors.textFaint,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...entry.value.map(
                                    (m) => _HistoryRow(
                                      message: m,
                                      onChanged: () => _load(silent: true),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MessageEntry message;
  final VoidCallback onChanged;
  const _HistoryRow({required this.message, required this.onChanged});

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return InkWell(
      onTap: () =>
          showMessageDetailSheet(context, app, message, onDeleted: onChanged),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                    '${messageTypeLabel(message.type, app)} — ${message.eleveNom}',
                    style: AppText.sans(size: 13, weight: FontWeight.w600),
                  ),
                  Text(
                    message.statut == StatutMessage.echec
                        ? app.tr('history.sendFailed')
                        : '${app.tr('history.sentTo')} ${message.telephoneDestinataire}',
                    style: AppText.sans(size: 11.5, color: AppColors.textFaint),
                  ),
                ],
              ),
            ),
            Text(
              _time(message.dateEnvoi),
              style: AppText.sans(
                size: 11.5,
                weight: FontWeight.w600,
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
