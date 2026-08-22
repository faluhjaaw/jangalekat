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
import 'bulletin_screen.dart';
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
  late Eleve _eleve;
  late Future<_StudentData> _future;

  @override
  void initState() {
    super.initState();
    _eleve = widget.eleve;
    _future = _load();
  }

  Future<_StudentData> _load() async {
    final app = context.read<AppState>();
    final notes = await app.noteService.notesEleve(
      widget.classe.id,
      _eleve.id,
      app.periode,
      widget.classe.matieres,
    );
    return _StudentData(
      notes: notes,
      moyenne: NoteService.moyennePonderee(notes),
    );
  }

  Future<void> _call() async {
    final app = context.read<AppState>();
    final digits = _eleve.telephoneParent.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(app.tr('student.callInvalidNumber'))),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: _eleve.telephoneParent);
    final ok = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.tr('student.callError'))));
    }
  }

  void _openWhatsapp(TypeMessage template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhatsappScreen(
          classe: widget.classe,
          eleves: [_eleve],
          initialStudent: _eleve,
          initialTemplate: template,
        ),
      ),
    );
  }

  Future<void> _openEditEleve() async {
    final app = context.read<AppState>();
    final prenomCtrl = TextEditingController(text: _eleve.prenom);
    final nomCtrl = TextEditingController(text: _eleve.nom);
    final parentCtrl = TextEditingController(text: _eleve.nomParent ?? '');
    final telSplit = splitPhone(_eleve.telephoneParent);
    final telCodeCtrl = TextEditingController(text: telSplit.code);
    final telNumberCtrl = TextEditingController(text: telSplit.number);
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
                    app.tr('student.editSheetTitle'),
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
                    label: app.tr('student.save'),
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
                        await app.eleveService.update(
                          widget.classe.id,
                          _eleve.id,
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
                            () => error = app.tr('student.editError'),
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
    if (updated == true && mounted) {
      setState(() {
        _eleve = Eleve(
          id: _eleve.id,
          nom: nomCtrl.text.trim(),
          prenom: prenomCtrl.text.trim(),
          telephoneParent: combinePhone(telCodeCtrl, telNumberCtrl),
          nomParent: parentCtrl.text.trim().isEmpty
              ? null
              : parentCtrl.text.trim(),
        );
      });
    }
  }

  bool _deleting = false;

  Future<void> _supprimerEleve() async {
    final app = context.read<AppState>();
    final confirmed = await confirmDelete(
      context,
      app,
      title: app.tr('student.deleteConfirmTitle'),
      message: app.tr('student.deleteConfirmMessage'),
    );
    if (!confirmed) return;
    setState(() => _deleting = true);
    try {
      await app.eleveService.delete(widget.classe.id, _eleve.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.tr('student.deleteError'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              title: app.tr('student.title'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BulletinScreen(
                          classe: widget.classe,
                          eleve: _eleve,
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        size: 17,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openEditEleve,
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _deleting ? null : _supprimerEleve,
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: AppColors.dangerText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<_StudentData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreenText,
                      ),
                    );
                  }
                  final data = snapshot.data;
                  final moyenne = data?.moyenne;
                  final belowThreshold =
                      moyenne != null && moyenne < kSeuilReussite;

                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
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
                              initials: _eleve.initiales,
                              size: 64,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _eleve.nomComplet,
                              style: AppText.sans(
                                size: 18,
                                weight: FontWeight.w700,
                              ),
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
                                  moyenne == null
                                      ? '—'
                                      : moyenne.toStringAsFixed(1),
                                  style: AppText.sans(
                                    size: 20,
                                    weight: FontWeight.w700,
                                    color: moyenne == null
                                        ? AppColors.textFaint
                                        : AppColors.avgColor(moyenne),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  app.tr('student.generalAverage'),
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
                                    app.tr('student.belowThreshold'),
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
                            SectionLabel(app.tr('student.parentContact')),
                            const SizedBox(height: 8),
                            Text(
                              _eleve.nomParent ?? '—',
                              style: AppText.sans(
                                size: 14.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _eleve.telephoneParent,
                              style: AppText.sans(
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
                                    icon: Icon(
                                      Icons.call_rounded,
                                      size: 15,
                                      color: AppColors.textDark,
                                    ),
                                    label: Text(
                                      app.tr('student.call'),
                                      style: AppText.sans(
                                        size: 13,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      side: BorderSide(
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
                                    onPressed: () => _openWhatsapp(
                                      TypeMessage.felicitations,
                                    ),
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
                            SectionLabel(
                              '${app.tr('student.notesTitle')} — ${app.periodeLabel}',
                            ),
                            const SizedBox(height: 10),
                            if (data == null || data.notes.isEmpty)
                              Text(
                                app.tr('student.noNotes'),
                                style: AppText.sans(
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                              )
                            else
                              ...data.notes.map(
                                (n) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                              style: AppText.sans(
                                                size: 13,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '· coeff ${n.coefficient}',
                                              style: AppText.sans(
                                                size: 13,
                                                color: AppColors.textMuted
                                                    .withValues(alpha: 0.7),
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
                            SectionLabel(app.tr('student.quickMessage')),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _QuickChip(
                                  label: app.tr('student.congratulate'),
                                  bg: AppColors.accentGreenBg,
                                  fg: AppColors.accentGreenText,
                                  onTap: () =>
                                      _openWhatsapp(TypeMessage.felicitations),
                                ),
                                _QuickChip(
                                  label: app.tr('student.summon'),
                                  bg: AppColors.card,
                                  fg: AppColors.textDark,
                                  onTap: () =>
                                      _openWhatsapp(TypeMessage.convocation),
                                ),
                                _QuickChip(
                                  label: app.tr('student.alert'),
                                  bg: AppColors.warningBg,
                                  fg: AppColors.warningText,
                                  onTap: () =>
                                      _openWhatsapp(TypeMessage.alerte),
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
          ],
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
