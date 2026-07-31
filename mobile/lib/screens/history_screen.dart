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
  late Future<List<MessageEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().messageService.historique();
  }

  Future<void> _reload() async {
    final f = context.read<AppState>().messageService.historique();
    setState(() {
      _future = f;
    });
    await f;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return "Aujourd'hui";
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return RefreshIndicator(
      color: AppColors.accentGreenText,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique',
                  style: AppText.sans(size: 22, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Journal des actions',
                  style: AppText.sans(size: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: app.offline
                    ? AppColors.warningBg
                    : AppColors.accentGreenBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      app.offline
                          ? '3 modifications en attente de synchronisation'
                          : 'Toutes les données sont synchronisées',
                      style: AppText.sans(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: app.offline
                            ? AppColors.warningText
                            : AppColors.accentGreenText,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: app.toggleOffline,
                    child: Text(
                      app.offline ? 'Se reconnecter' : 'Voir',
                      style: AppText.sans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: app.offline
                            ? AppColors.warningText
                            : AppColors.accentGreenText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<MessageEntry>>(
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
                  child: ErrorBanner('Impossible de charger l\'historique'),
                );
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Center(
                    child: Text(
                      'Aucune activité pour le moment',
                      style: AppText.sans(size: 13, color: AppColors.textMuted),
                    ),
                  ),
                );
              }

              final Map<String, List<MessageEntry>> grouped = {};
              for (final m in messages) {
                grouped.putIfAbsent(_dayLabel(m.dateEnvoi), () => []).add(m);
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
                          ...entry.value.map((m) => _HistoryRow(message: m)),
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
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MessageEntry message;
  const _HistoryRow({required this.message});

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _typeLabel(TypeMessage t) => switch (t) {
    TypeMessage.felicitations => 'Félicitations',
    TypeMessage.convocation => 'Convocation',
    TypeMessage.alerte => 'Alerte',
    TypeMessage.groupe => 'Message groupé',
    TypeMessage.personnalise => 'Message',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  '${_typeLabel(message.type)} — ${message.eleveNom}',
                  style: AppText.sans(size: 13, weight: FontWeight.w600),
                ),
                Text(
                  message.statut == StatutMessage.echec
                      ? 'Échec de l\'envoi'
                      : 'Envoyé à ${message.telephoneDestinataire}',
                  style: AppText.sans(size: 11.5, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
          Text(
            _time(message.dateEnvoi),
            style: AppText.mono(size: 11.5, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}
