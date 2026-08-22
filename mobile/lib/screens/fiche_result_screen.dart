import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/fiche_contenu.dart';
import '../services/pdf_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

/// Affichage d'une fiche generee : consultation, enregistrement, export PDF
/// (telechargement/partage), modification et suppression. `ficheId`/
/// `dateCreation` non-nuls quand on ouvre une fiche deja enregistree depuis
/// l'historique — dans ce cas le bouton "Enregistrer" est masque (deja en
/// base) et les actions modifier/supprimer apparaissent dans l'entete.
class FicheResultScreen extends StatefulWidget {
  final String matiere;
  final String niveau;
  final String theme;
  final String langue;
  final FicheContenu contenu;
  final String? ficheId;
  final DateTime? dateCreation;

  const FicheResultScreen({
    super.key,
    required this.matiere,
    required this.niveau,
    required this.theme,
    required this.langue,
    required this.contenu,
    this.ficheId,
    this.dateCreation,
  });

  @override
  State<FicheResultScreen> createState() => _FicheResultScreenState();
}

class _FicheResultScreenState extends State<FicheResultScreen> {
  bool _saving = false;
  bool _saved = false;
  bool _exporting = false;
  bool _editing = false;
  bool _editSaving = false;
  bool _deleting = false;
  String? _error;

  late String _theme;
  late FicheContenu _contenu;

  late final _themeCtrl = TextEditingController(text: _theme);
  late final _resumeCtrl = TextEditingController(text: _contenu.resume);
  late final _objectifsCtrl = TextEditingController(text: _contenu.objectifs);
  late final _prerequisCtrl = TextEditingController(text: _contenu.prerequis);
  late final _deroulementCtrl = TextEditingController(
    text: _contenu.deroulement,
  );
  late final _activitesCtrl = TextEditingController(text: _contenu.activites);
  late final _evaluationCtrl = TextEditingController(
    text: _contenu.evaluation,
  );

  bool get _dejaEnregistree => widget.ficheId != null || _saved;
  bool get _modifiable => widget.ficheId != null;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme;
    _contenu = widget.contenu;
  }

  @override
  void dispose() {
    _themeCtrl.dispose();
    _resumeCtrl.dispose();
    _objectifsCtrl.dispose();
    _prerequisCtrl.dispose();
    _deroulementCtrl.dispose();
    _activitesCtrl.dispose();
    _evaluationCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final app = context.read<AppState>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await app.ficheService.enregistrer(
        matiere: widget.matiere,
        niveau: widget.niveau,
        theme: _theme,
        contenu: _contenu,
        langue: widget.langue,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = app.tr('fiche.saveError');
      });
    }
  }

  void _commencerEdition() {
    setState(() {
      _error = null;
      _editing = true;
    });
  }

  void _annulerEdition() {
    setState(() {
      _themeCtrl.text = _theme;
      _resumeCtrl.text = _contenu.resume;
      _objectifsCtrl.text = _contenu.objectifs;
      _prerequisCtrl.text = _contenu.prerequis;
      _deroulementCtrl.text = _contenu.deroulement;
      _activitesCtrl.text = _contenu.activites;
      _evaluationCtrl.text = _contenu.evaluation;
      _editing = false;
      _error = null;
    });
  }

  Future<void> _enregistrerModifications() async {
    final app = context.read<AppState>();
    final nouveauTheme = _themeCtrl.text.trim();
    final nouveauContenu = FicheContenu(
      resume: _resumeCtrl.text.trim(),
      objectifs: _objectifsCtrl.text.trim(),
      prerequis: _prerequisCtrl.text.trim(),
      deroulement: _deroulementCtrl.text.trim(),
      activites: _activitesCtrl.text.trim(),
      evaluation: _evaluationCtrl.text.trim(),
    );
    setState(() {
      _editSaving = true;
      _error = null;
    });
    try {
      await app.ficheService.modifier(
        ficheId: widget.ficheId!,
        theme: nouveauTheme,
        contenu: nouveauContenu,
      );
      if (!mounted) return;
      setState(() {
        _theme = nouveauTheme;
        _contenu = nouveauContenu;
        _editSaving = false;
        _editing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _editSaving = false;
        _error = app.tr('fiche.editError');
      });
    }
  }

  Future<void> _supprimer() async {
    final app = context.read<AppState>();
    final confirmed = await confirmDelete(
      context,
      app,
      title: app.tr('fiche.deleteConfirmTitle'),
      message: app.tr('fiche.deleteConfirmMessage'),
    );
    if (!confirmed) return;
    setState(() => _deleting = true);
    try {
      await app.ficheService.supprimer(widget.ficheId!);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = app.tr('fiche.deleteError');
      });
    }
  }

  Future<Uint8List> _buildPdf() {
    return PdfService.genererFichePdf(
      matiere: widget.matiere,
      niveau: widget.niveau,
      theme: _theme,
      langue: widget.langue,
      contenu: _contenu,
      dateCreation: widget.dateCreation,
    );
  }

  Future<void> _telecharger() async {
    final app = context.read<AppState>();
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      if (mounted) setState(() => _error = app.tr('fiche.pdfGenError'));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _partager() async {
    final app = context.read<AppState>();
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: PdfService.nomFichier(_theme),
      );
    } catch (_) {
      if (mounted) setState(() => _error = app.tr('fiche.pdfShareError'));
    } finally {
      if (mounted) setState(() => _exporting = false);
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
              title: _editing ? app.tr('fiche.edit') : _theme,
              subtitle: '${widget.matiere} · ${widget.niveau}',
              trailing: (_modifiable && !_editing)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderIconButton(
                          icon: Icons.edit_rounded,
                          onTap: _commencerEdition,
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconButton(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.dangerText,
                          onTap: _deleting ? null : _supprimer,
                        ),
                      ],
                    )
                  : null,
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (!_editing)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.translate_rounded,
                            label: widget.langue == 'wolof'
                                ? app.tr('lang.wolof')
                                : app.tr('lang.fr'),
                          ),
                          if (widget.dateCreation != null)
                            _MetaChip(
                              icon: Icons.event_rounded,
                              label: _dateLabel(widget.dateCreation!),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) ...[
                          ErrorBanner(_error!),
                          const SizedBox(height: 14),
                        ],
                        if (_editing) ...[
                          SectionLabel(app.tr('fiche.themeLabel')),
                          const SizedBox(height: 7),
                          _EditField(controller: _themeCtrl, minLines: 1),
                          const SizedBox(height: 14),
                        ],
                        _Section(
                          label: app.tr('fiche.sectionResume'),
                          icon: Icons.summarize_rounded,
                          texte: _contenu.resume,
                          accent: true,
                          editing: _editing,
                          controller: _resumeCtrl,
                        ),
                        _Section(
                          label: app.tr('fiche.sectionObjectifs'),
                          icon: Icons.flag_rounded,
                          texte: _contenu.objectifs,
                          editing: _editing,
                          controller: _objectifsCtrl,
                        ),
                        _Section(
                          label: app.tr('fiche.sectionPrerequis'),
                          icon: Icons.fact_check_rounded,
                          texte: _contenu.prerequis,
                          editing: _editing,
                          controller: _prerequisCtrl,
                        ),
                        _Section(
                          label: app.tr('fiche.sectionDeroulement'),
                          icon: Icons.timeline_rounded,
                          texte: _contenu.deroulement,
                          editing: _editing,
                          controller: _deroulementCtrl,
                        ),
                        _Section(
                          label: app.tr('fiche.sectionActivites'),
                          icon: Icons.assignment_rounded,
                          texte: _contenu.activites,
                          editing: _editing,
                          controller: _activitesCtrl,
                        ),
                        _Section(
                          label: app.tr('fiche.sectionEvaluation'),
                          icon: Icons.grading_rounded,
                          texte: _contenu.evaluation,
                          editing: _editing,
                          controller: _evaluationCtrl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: _editing
                  ? Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: app.tr('common.cancel'),
                            background: AppColors.card,
                            foreground: AppColors.textDark,
                            onPressed: _editSaving ? null : _annulerEdition,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label: _editSaving
                                ? app.tr('fiche.editSaving')
                                : app.tr('fiche.editSave'),
                            onPressed: _editSaving
                                ? null
                                : _enregistrerModifications,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: app.tr('fiche.download'),
                                background: AppColors.card,
                                foreground: AppColors.textDark,
                                icon: Icon(
                                  Icons.download_rounded,
                                  size: 16,
                                  color: AppColors.textDark,
                                ),
                                onPressed: _exporting ? null : _telecharger,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                label: app.tr('fiche.share'),
                                background: AppColors.card,
                                foreground: AppColors.textDark,
                                icon: Icon(
                                  Icons.ios_share_rounded,
                                  size: 16,
                                  color: AppColors.textDark,
                                ),
                                onPressed: _exporting ? null : _partager,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        PrimaryButton(
                          label: _saving
                              ? app.tr('fiche.saving')
                              : _dejaEnregistree
                              ? app.tr('fiche.saved')
                              : app.tr('fiche.save'),
                          background: _dejaEnregistree
                              ? AppColors.accentGreenSoft
                              : AppColors.accentGreen,
                          icon: _dejaEnregistree
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 17,
                                  color: AppColors.accentGreenDarkText,
                                )
                              : null,
                          onPressed: (_saving || _dejaEnregistree)
                              ? null
                              : _enregistrer,
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

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  const _HeaderIconButton({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.textDark),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final int minLines;
  const _EditField({required this.controller, this.minLines = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: null,
        style: AppText.sans(size: 13.5, height: 1.5),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.sans(
              size: 11.5,
              weight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final IconData icon;
  final String texte;
  final bool accent;
  final bool editing;
  final TextEditingController? controller;
  const _Section({
    required this.label,
    required this.icon,
    required this.texte,
    this.accent = false,
    this.editing = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final lignes = parseFicheTexte(texte);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? AppColors.accentGreenBg : AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent
                      ? AppColors.background
                      : AppColors.accentGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: AppColors.accentGreenText),
              ),
              const SizedBox(width: 8),
              SectionLabel(label),
            ],
          ),
          const SizedBox(height: 10),
          if (editing && controller != null)
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: null,
              style: AppText.sans(size: 13.5, height: 1.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: accent
                    ? AppColors.background
                    : AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            )
          else if (lignes.isEmpty)
            Text(
              '—',
              style: AppText.sans(size: 13.5, color: AppColors.textFaint),
            )
          else if (lignes.length == 1 && !lignes.first.isListItem)
            Text(
              lignes.first.texte,
              style: AppText.sans(size: 13.5, height: 1.5),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lignes
                  .map(
                    (l) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              l.marker ?? '',
                              style: AppText.sans(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.accentGreenText,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l.texte,
                              style: AppText.sans(size: 13.5, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
