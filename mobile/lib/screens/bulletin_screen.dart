import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/classe.dart';
import '../models/eleve.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../services/pdf_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class _BulletinData {
  final List<Note> notesPeriode;
  final double? moyenneT1;
  final double? moyenneT2;
  final double? moyenneT3;
  final int? rang;
  final int effectif;

  _BulletinData({
    required this.notesPeriode,
    required this.moyenneT1,
    required this.moyenneT2,
    required this.moyenneT3,
    required this.rang,
    required this.effectif,
  });
}

/// Genere le bulletin de notes d'un eleve (calque sur le modele papier
/// utilise par les ecoles, voir `PdfService.genererBulletinPdf`) : le PDF
/// genere est affiche directement via `PdfPreview` (rendu exact de ce qui
/// sera telecharge/partage), pas de double mise en page a maintenir entre
/// un aperçu Flutter et le PDF final.
class BulletinScreen extends StatefulWidget {
  final Classe classe;
  final Eleve eleve;
  const BulletinScreen({super.key, required this.classe, required this.eleve});

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  late Future<_BulletinData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BulletinData> _load() async {
    final app = context.read<AppState>();
    final classe = widget.classe;
    final eleve = widget.eleve;

    final notesParPeriode = await Future.wait([
      app.noteService.notesEleve(classe.id, eleve.id, 'T1', classe.matieres),
      app.noteService.notesEleve(classe.id, eleve.id, 'T2', classe.matieres),
      app.noteService.notesEleve(classe.id, eleve.id, 'T3', classe.matieres),
    ]);
    final periodeActiveIndex = kPeriodes.indexOf(app.periode);
    // Un bulletin genere pour T1 ne doit jamais montrer les moyennes de T2/T3
    // (et T2 ne doit pas montrer T3), meme si des notes existent deja pour
    // ces trimestres (saisie en avance, donnees de test...) : on ignore tout
    // ce qui est apres la periode active, pas seulement ce qui est vide.
    final moyennesEleve = List<double?>.generate(notesParPeriode.length, (i) {
      if (i > periodeActiveIndex) return null;
      return NoteService.moyennePonderee(notesParPeriode[i]);
    });
    final notesPeriode = notesParPeriode[periodeActiveIndex];

    final classmates = await app.eleveService.listForClasse(classe.id);
    final moyennesClasse = await Future.wait(
      classmates.map((e) async {
        final notes = await app.noteService.notesEleve(
          classe.id,
          e.id,
          app.periode,
          classe.matieres,
        );
        return MapEntry(e.id, NoteService.moyennePonderee(notes));
      }),
    );
    final classees = moyennesClasse.where((e) => e.value != null).toList()
      ..sort((a, b) => b.value!.compareTo(a.value!));
    final position = classees.indexWhere((e) => e.key == eleve.id);

    return _BulletinData(
      notesPeriode: notesPeriode,
      moyenneT1: moyennesEleve[0],
      moyenneT2: moyennesEleve[1],
      moyenneT3: moyennesEleve[2],
      rang: position == -1 ? null : position + 1,
      effectif: classmates.length,
    );
  }

  Future<Uint8List> _buildPdf(_BulletinData data) {
    final app = context.read<AppState>();
    return PdfService.genererBulletinPdf(
      eleve: widget.eleve,
      classe: widget.classe,
      enseignant: app.enseignant!,
      periode: app.periode,
      notesPeriode: data.notesPeriode,
      moyenneT1: data.moyenneT1,
      moyenneT2: data.moyenneT2,
      moyenneT3: data.moyenneT3,
      rang: data.rang,
      effectif: data.effectif,
    );
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
              title: app.tr('bulletin.title'),
              subtitle: widget.eleve.nomComplet,
            ),
            Expanded(
              child: FutureBuilder<_BulletinData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreenText,
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: ErrorBanner(app.tr('bulletin.loadError')),
                    );
                  }
                  final data = snapshot.data!;
                  return Column(
                    children: [
                      Expanded(
                        child: PdfPreview(
                          build: (format) => _buildPdf(data),
                          allowPrinting: false,
                          allowSharing: false,
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          canDebug: false,
                          actions: const [],
                          loadingWidget: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentGreenText,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border(
                            top: BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: app.tr('bulletin.download'),
                                background: AppColors.card,
                                foreground: AppColors.textDark,
                                icon: Icon(
                                  Icons.download_rounded,
                                  size: 16,
                                  color: AppColors.textDark,
                                ),
                                onPressed: () => _telecharger(data),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                label: app.tr('bulletin.share'),
                                background: AppColors.card,
                                foreground: AppColors.textDark,
                                icon: Icon(
                                  Icons.ios_share_rounded,
                                  size: 16,
                                  color: AppColors.textDark,
                                ),
                                onPressed: () => _partager(data),
                              ),
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

  Future<void> _telecharger(_BulletinData data) async {
    final app = context.read<AppState>();
    try {
      final bytes = await _buildPdf(data);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(app.tr('bulletin.pdfGenError'))));
      }
    }
  }

  Future<void> _partager(_BulletinData data) async {
    final app = context.read<AppState>();
    try {
      final bytes = await _buildPdf(data);
      await Printing.sharePdf(
        bytes: bytes,
        filename: PdfService.nomFichierBulletin(widget.eleve, app.periode),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.tr('bulletin.pdfShareError'))),
        );
      }
    }
  }
}
