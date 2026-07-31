import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/classe.dart';
import '../models/eleve.dart';
import '../models/message_models.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import 'whatsapp_screen.dart';

class _StudentData {
  final List<Note> notes;
  final double? moyenne;
  _StudentData({required this.notes, required this.moyenne});
}

class StudentScreen extends StatefulWidget {
  final Classe classe;
  final Eleve eleve;
  const StudentScreen({super.key, required this.classe, required this.eleve});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  late Future<_StudentData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentData> _load() async {
    final app = context.read<AppState>();
    final notes = await app.noteService.notesEleve(
      widget.classe.id,
      widget.eleve.id,
      kPeriodeActuelle,
      widget.classe.matieres,
    );
    return _StudentData(
      notes: notes,
      moyenne: NoteService.moyennePonderee(notes),
    );
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: widget.eleve.telephoneParent);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openWhatsapp(TypeMessage template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhatsappScreen(
          classe: widget.classe,
          eleves: [widget.eleve],
          initialStudent: widget.eleve,
          initialTemplate: template,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<_StudentData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                children: [
                  const BackHeader(title: 'Fiche élève'),
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
            final data = snapshot.data;
            final moyenne = data?.moyenne;
            final belowThreshold = moyenne != null && moyenne < kSeuilReussite;

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const BackHeader(title: 'Fiche élève'),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      InitialsAvatar(
                        initials: widget.eleve.initiales,
                        size: 64,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.eleve.nomComplet,
                        style: AppText.sans(size: 18, weight: FontWeight.w700),
                      ),
                      Text(
                        widget.classe.nom,
                        style: AppText.sans(
                          size: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            moyenne == null ? '—' : moyenne.toStringAsFixed(1),
                            style: AppText.mono(
                              size: 20,
                              weight: FontWeight.w700,
                              color: moyenne == null
                                  ? AppColors.textFaint
                                  : AppColors.avgColor(moyenne),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'moyenne générale',
                            style: AppText.sans(
                              size: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (belowThreshold)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Sous le seuil — alerte recommandée',
                              style: AppText.sans(
                                size: 11.5,
                                weight: FontWeight.w700,
                                color: AppColors.warningText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Contact parent'),
                      const SizedBox(height: 8),
                      Text(
                        widget.eleve.nomParent ?? '—',
                        style: AppText.sans(
                          size: 14.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.eleve.telephoneParent,
                        style: AppText.mono(
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _call,
                              icon: const Icon(
                                Icons.call_rounded,
                                size: 15,
                                color: AppColors.textDark,
                              ),
                              label: Text(
                                'Appeler',
                                style: AppText.sans(
                                  size: 13,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                side: const BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                                backgroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              label: 'WhatsApp',
                              icon: const Icon(
                                Icons.chat_bubble_rounded,
                                size: 15,
                                color: AppColors.accentGreenDarkText,
                              ),
                              onPressed: () =>
                                  _openWhatsapp(TypeMessage.felicitations),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel('Notes — $kPeriodeLabel'),
                      const SizedBox(height: 10),
                      if (data == null || data.notes.isEmpty)
                        Text(
                          'Aucune note saisie pour cette période',
                          style: AppText.sans(
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        )
                      else
                        ...data.notes.map(
                          (n) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  n.matiere,
                                  style: AppText.sans(
                                    size: 13.5,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            '${n.valeur.toStringAsFixed(1)}/20  ',
                                        style: AppText.mono(
                                          size: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '· coeff ${n.coefficient}',
                                        style: AppText.mono(
                                          size: 13,
                                          color: AppColors.textMuted.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                      const SectionLabel('Message rapide'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickChip(
                            label: 'Féliciter',
                            bg: AppColors.accentGreenBg,
                            fg: AppColors.accentGreenText,
                            onTap: () =>
                                _openWhatsapp(TypeMessage.felicitations),
                          ),
                          _QuickChip(
                            label: 'Convoquer',
                            bg: AppColors.card,
                            fg: AppColors.textDark,
                            onTap: () => _openWhatsapp(TypeMessage.convocation),
                          ),
                          _QuickChip(
                            label: 'Alerter',
                            bg: AppColors.warningBg,
                            fg: AppColors.warningText,
                            onTap: () => _openWhatsapp(TypeMessage.alerte),
                          ),
                        ],
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

class _QuickChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _QuickChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppText.sans(size: 12.5, weight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }
}
