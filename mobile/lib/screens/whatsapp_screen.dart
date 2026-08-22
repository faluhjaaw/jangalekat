import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/classe.dart';
import '../models/classe_summary.dart';
import '../models/eleve.dart';
import '../models/message_models.dart';
import '../services/note_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

enum _Mode { individuel, groupe }

/// wa.me n'ouvre qu'une conversation a la fois : impossible d'envoyer un
/// "vrai" message groupe sans Cloud Function (hors scope du MVP). On expose
/// donc le lien pret-a-l'emploi, WhatsApp lui-meme, et c'est l'enseignant qui
/// appuie sur "envoyer" pour chaque destinataire.
Uri _waLinkFor(String telephone, String texte) {
  final digits = telephone.replaceAll(RegExp(r'[^0-9]'), '');
  return Uri.https('wa.me', '/$digits', {'text': texte});
}

class WhatsappScreen extends StatefulWidget {
  final Classe classe;
  final List<Eleve> eleves;
  final Eleve? initialStudent;
  final TypeMessage initialTemplate;

  /// Quand fourni avec plus d'une classe, affiche un selecteur de classe
  /// au-dessus du choix Individuel/Groupe (ex. action rapide "Envoyer aux
  /// parents" du tableau de bord, qui n'est pas liee a une classe precise).
  /// `null`/liste a un seul element : pas de selecteur, comportement
  /// inchange (ex. depuis la fiche d'un eleve, deja scopee a sa classe).
  final List<ClasseSummary>? allClasses;

  const WhatsappScreen({
    super.key,
    required this.classe,
    required this.eleves,
    this.initialStudent,
    this.initialTemplate = TypeMessage.felicitations,
    this.allClasses,
  });

  @override
  State<WhatsappScreen> createState() => _WhatsappScreenState();
}

class _WhatsappScreenState extends State<WhatsappScreen> {
  late Classe _classe;
  late List<Eleve> _eleves;
  late _Mode _mode;
  late TypeMessage _template;
  late Eleve _selectedStudent;
  late Set<String> _selectedParentIds;
  final _messageCtrl = TextEditingController();

  bool _sending = false;
  bool _sent = false;
  String? _error;
  int _groupSentCount = 0;

  @override
  void initState() {
    super.initState();
    _classe = widget.classe;
    _eleves = widget.eleves;
    _mode = _Mode.individuel;
    _template = widget.initialTemplate;
    _selectedStudent = widget.initialStudent ?? _eleves.first;
    _selectedParentIds = _eleves.map((e) => e.id).toSet();
    _generateText();
  }

  void _selectClasse(Classe c) {
    final summary = widget.allClasses!.firstWhere((s) => s.classe.id == c.id);
    setState(() {
      _classe = summary.classe;
      _eleves = summary.eleves;
      _selectedStudent = _eleves.isEmpty ? _selectedStudent : _eleves.first;
      _selectedParentIds = _eleves.map((e) => e.id).toSet();
      _groupSentCount = 0;
      _sent = false;
    });
    _generateText();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateText() async {
    if (_template == TypeMessage.personnalise) {
      setState(() => _messageCtrl.text = '');
      return;
    }
    final app = context.read<AppState>();
    final enseignantNom = app.enseignant?.nom ?? '';
    final ecole = app.enseignant?.ecole ?? '';

    final periodeLabel = app.periodeLabelFr;

    if (_mode == _Mode.groupe) {
      _messageCtrl.text =
          'Bonjour, voici les résultats du $periodeLabel pour la classe de ${_classe.nom}. — $enseignantNom.';
      setState(() {});
      return;
    }

    double? moyenne;
    try {
      final notes = await app.noteService.notesEleve(
        _classe.id,
        _selectedStudent.id,
        app.periode,
        _classe.matieres,
      );
      moyenne = NoteService.moyennePonderee(notes);
    } catch (_) {
      moyenne = null;
    }
    final moyenneTxt = moyenne == null ? 'N/A' : moyenne.toStringAsFixed(1);
    final nomComplet = _selectedStudent.nomComplet;

    final text = switch (_template) {
      TypeMessage.felicitations =>
        'Bonjour, je vous informe que $nomComplet a obtenu une moyenne de $moyenneTxt/20 ce $periodeLabel. Félicitations pour ce travail sérieux ! — $enseignantNom, $ecole.',
      TypeMessage.convocation =>
        'Bonjour, je souhaiterais échanger avec vous au sujet des résultats de $nomComplet. Merci de passer à l\'école quand vous pourrez. — $enseignantNom.',
      TypeMessage.alerte =>
        'Bonjour, la moyenne de $nomComplet est de $moyenneTxt/20 ce $periodeLabel, en dessous du seuil de réussite. Restons en contact pour l\'accompagner. — $enseignantNom.',
      _ => '',
    };
    if (!mounted) return;
    setState(() => _messageCtrl.text = text);
  }

  void _setMode(_Mode m) {
    setState(() => _mode = m);
    _generateText();
  }

  void _selectTemplate(TypeMessage t) {
    setState(() => _template = t);
    _generateText();
  }

  void _toggleParent(String id) {
    setState(() {
      if (_selectedParentIds.contains(id)) {
        _selectedParentIds.remove(id);
      } else {
        _selectedParentIds.add(id);
      }
    });
  }

  List<Eleve> get _groupTargets =>
      _eleves.where((e) => _selectedParentIds.contains(e.id)).toList();

  Future<void> _sendTo(Eleve eleve) async {
    final app = context.read<AppState>();
    final texte = _messageCtrl.text.trim();
    final uri = _waLinkFor(eleve.telephoneParent, texte);
    final ouvert =
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    await app.messageService.enregistrer(
      eleveId: eleve.id,
      eleveNom: eleve.nomComplet,
      classeId: _classe.id,
      classeNom: _classe.nom,
      contenu: texte,
      type: _mode == _Mode.groupe ? TypeMessage.groupe : _template,
      statut: ouvert ? StatutMessage.envoye : StatutMessage.echec,
      telephoneDestinataire: eleve.telephoneParent,
    );
    if (!ouvert) throw Exception('WhatsApp indisponible');
  }

  Future<void> _send() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (_mode == _Mode.individuel) {
        if (_sent) return;
        await _sendTo(_selectedStudent);
        if (!mounted) return;
        setState(() {
          _sending = false;
          _sent = true;
        });
      } else {
        final targets = _groupTargets;
        if (_groupSentCount >= targets.length) return;
        await _sendTo(targets[_groupSentCount]);
        if (!mounted) return;
        setState(() {
          _sending = false;
          _groupSentCount++;
          if (_groupSentCount >= targets.length) _sent = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = context.read<AppState>().tr('whatsapp.openError');
      });
    }
  }

  /// Passe au destinataire suivant sans reessayer l'envoi : utilise quand
  /// l'echec est du au destinataire lui-meme (numero invalide, WhatsApp non
  /// installe...) et que reessayer ne changerait rien. L'echec reste
  /// journalise (voir `_sendTo`), seul le blocage de la file est leve.
  void _skipCurrent() {
    setState(() {
      _error = null;
      _groupSentCount++;
      if (_groupSentCount >= _groupTargets.length) _sent = true;
    });
  }

  int get _sendCount =>
      _mode == _Mode.individuel ? 1 : _selectedParentIds.length;

  String _sendLabel(AppState app) {
    if (_sending) return app.tr('whatsapp.sending');
    if (_mode == _Mode.individuel) {
      return _sent ? app.tr('whatsapp.sent') : app.tr('whatsapp.sendButton');
    }
    final targets = _groupTargets;
    if (targets.isEmpty) return app.tr('whatsapp.sendButton');
    if (_sent) {
      return '${app.tr('whatsapp.sent')} (${targets.length}/${targets.length})';
    }
    if (_groupSentCount == 0) {
      return '${app.tr('whatsapp.sendButton')} — ${targets.length} ${app.tr('whatsapp.messagesSuffix')}';
    }
    final suivant = targets[_groupSentCount];
    return '${app.tr('whatsapp.next')} : ${suivant.prenom} ($_groupSentCount/${targets.length})';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(title: app.tr('whatsapp.title')),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                children: [
                  if (_error != null) ...[
                    ErrorBanner(_error!),
                    if (_mode == _Mode.groupe &&
                        _groupSentCount < _groupTargets.length) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _skipCurrent,
                        child: Text(
                          app.tr('whatsapp.skip'),
                          style: AppText.sans(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                  if ((widget.allClasses?.length ?? 0) > 1) ...[
                    _ClassePicker(
                      classes: widget.allClasses!,
                      selected: _classe,
                      onSelect: _selectClasse,
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _ModeButton(
                          label: app.tr('whatsapp.individual'),
                          active: _mode == _Mode.individuel,
                          onTap: () => _setMode(_Mode.individuel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ModeButton(
                          label: app.tr('whatsapp.group'),
                          active: _mode == _Mode.groupe,
                          onTap: () => _setMode(_Mode.groupe),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_mode == _Mode.individuel)
                    _IndividualPicker(
                      eleves: _eleves,
                      selected: _selectedStudent,
                      onSelect: (e) {
                        setState(() => _selectedStudent = e);
                        _generateText();
                      },
                    )
                  else
                    _GroupPicker(
                      eleves: _eleves,
                      selectedIds: _selectedParentIds,
                      onToggle: _toggleParent,
                    ),
                  const SizedBox(height: 14),
                  SectionLabel(app.tr('whatsapp.messageType')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TemplateChip(
                        label: app.tr('whatsapp.templateCongrats'),
                        active: _template == TypeMessage.felicitations,
                        activeBg: AppColors.accentGreenBgStrong,
                        fg: AppColors.accentGreenText,
                        onTap: () => _selectTemplate(TypeMessage.felicitations),
                      ),
                      _TemplateChip(
                        label: app.tr('whatsapp.templateSummon'),
                        active: _template == TypeMessage.convocation,
                        activeBg: AppColors.accentGreenBgStrong,
                        fg: AppColors.textDark,
                        onTap: () => _selectTemplate(TypeMessage.convocation),
                      ),
                      _TemplateChip(
                        label: app.tr('whatsapp.templateAlert'),
                        active: _template == TypeMessage.alerte,
                        activeBg: AppColors.warningBg,
                        fg: AppColors.warningText,
                        onTap: () => _selectTemplate(TypeMessage.alerte),
                      ),
                      _TemplateChip(
                        label: app.tr('whatsapp.templateCustom'),
                        active: _template == TypeMessage.personnalise,
                        activeBg: AppColors.accentGreenBgStrong,
                        fg: AppColors.textDark,
                        onTap: () => _selectTemplate(TypeMessage.personnalise),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SectionLabel(app.tr('whatsapp.preview')),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreenBgStrong,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: TextField(
                      controller: _messageCtrl,
                      maxLines: 6,
                      minLines: 4,
                      style: AppText.sans(size: 13.5, height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
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
              child: PrimaryButton(
                label: _sendLabel(app),
                background: _sent
                    ? AppColors.accentGreenSoft
                    : AppColors.accentGreen,
                icon: _sent
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: AppColors.accentGreenDarkText,
                      )
                    : null,
                onPressed: _sending || _sendCount == 0 || _sent ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selecteur de classe : ne s'affiche que si l'enseignant a plus d'une
/// classe et que l'ecran n'est pas deja scope a une classe precise (voir
/// `WhatsappScreen.allClasses`). Meme habillage que `_IndividualPicker`
/// (avatar + nom/sous-titre + puce menu) pour rester coherent visuellement.
class _ClassePicker extends StatelessWidget {
  final List<ClasseSummary> classes;
  final Classe selected;
  final ValueChanged<Classe> onSelect;
  const _ClassePicker({
    required this.classes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final selectedSummary = classes.firstWhere(
      (s) => s.classe.id == selected.id,
      orElse: () => classes.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: selected.initiales, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.nom,
                  style: AppText.sans(size: 14, weight: FontWeight.w700),
                ),
                Text(
                  '${selectedSummary.studentCount} ${app.tr('classes.summaryStudents')}',
                  style: AppText.sans(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (classes.length > 1)
            PopupMenuButton<Classe>(
              icon: Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: AppColors.textFaint,
              ),
              onSelected: onSelect,
              itemBuilder: (context) => classes
                  .map(
                    (s) => PopupMenuItem(
                      value: s.classe,
                      child: Text(s.classe.nom),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeButton({
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

class _IndividualPicker extends StatelessWidget {
  final List<Eleve> eleves;
  final Eleve selected;
  final ValueChanged<Eleve> onSelect;
  const _IndividualPicker({
    required this.eleves,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: selected.initiales, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.nomParent ?? selected.nomComplet,
                  style: AppText.sans(size: 14, weight: FontWeight.w700),
                ),
                Text(
                  selected.telephoneParent,
                  style: AppText.sans(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (eleves.length > 1)
            PopupMenuButton<Eleve>(
              icon: Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: AppColors.textFaint,
              ),
              onSelected: onSelect,
              itemBuilder: (context) => eleves
                  .map(
                    (e) => PopupMenuItem(value: e, child: Text(e.nomComplet)),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _GroupPicker extends StatelessWidget {
  final List<Eleve> eleves;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  const _GroupPicker({
    required this.eleves,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionLabel(app.tr('whatsapp.recipients')),
            Text(
              '${selectedIds.length}/${eleves.length} ${app.tr('whatsapp.selected')}',
              style: AppText.sans(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            shrinkWrap: true,
            itemCount: eleves.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final e = eleves[i];
              final checked = selectedIds.contains(e.id);
              return InkWell(
                onTap: () => onToggle(e.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: checked
                              ? AppColors.accentGreenText
                              : Colors.transparent,
                          border: Border.all(
                            color: checked
                                ? AppColors.accentGreenText
                                : AppColors.dashedBorder,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: checked
                            ? const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.nomParent ?? e.nomComplet,
                          style: AppText.sans(
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        e.prenom,
                        style: AppText.sans(
                          size: 11,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeBg;
  final Color fg;
  final VoidCallback onTap;
  const _TemplateChip({
    required this.label,
    required this.active,
    required this.activeBg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? activeBg : AppColors.card,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppText.sans(size: 12, weight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }
}
