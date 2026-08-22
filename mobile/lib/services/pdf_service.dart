import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/classe.dart';
import '../models/eleve.dart';
import '../models/enseignant.dart';
import '../models/fiche_contenu.dart';
import '../models/note.dart';
import 'note_service.dart';

/// Construit le PDF d'une fiche de cours. Police de base (Helvetica) : pas
/// besoin de police custom embarquee, elle couvre deja les accents francais.
/// Mise en page pensee pour l'impression papier : pas d'aplats de couleur
/// pleine page (economie d'encre), juste une barre d'accent a gauche de
/// chaque section pour la hierarchie visuelle.
class PdfService {
  static Future<Uint8List> genererFichePdf({
    required String matiere,
    required String niveau,
    required String theme,
    required String langue,
    required FicheContenu contenu,
    DateTime? dateCreation,
  }) async {
    final doc = pw.Document();
    final date = dateCreation ?? DateTime.now();
    final dateTexte =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    theme,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Jàngalekat',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '$matiere · $niveau · ${langue == 'wolof' ? 'Wolof' : 'Français'} · $dateTexte',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey400, thickness: 0.8),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
        build: (context) => [
          _section('Résumé', contenu.resume, accent: true),
          _section('Objectifs', contenu.objectifs),
          _section('Prérequis', contenu.prerequis),
          _section('Déroulement', contenu.deroulement),
          _section('Activités', contenu.activites),
          _section('Évaluation', contenu.evaluation),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _section(String titre, String texte, {bool accent = false}) {
    final lignes = parseFicheTexte(texte);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(left: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(
            color: accent ? PdfColors.green700 : PdfColors.grey400,
            width: 2.5,
          ),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titre.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: accent ? PdfColors.green800 : PdfColors.grey700,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 5),
          if (lignes.isEmpty)
            pw.Text(
              '—',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey500),
            )
          else if (lignes.length == 1 && !lignes.first.isListItem)
            pw.Text(
              lignes.first.texte,
              style: pw.TextStyle(
                fontSize: 11,
                lineSpacing: 3,
                fontStyle: accent ? pw.FontStyle.italic : pw.FontStyle.normal,
              ),
            )
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: lignes
                  .map(
                    (l) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 18,
                            child: pw.Text(
                              l.marker ?? '',
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              l.texte,
                              style: const pw.TextStyle(
                                fontSize: 11,
                                lineSpacing: 2,
                              ),
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

  /// Nom de fichier propose (sans espaces/accents) pour le partage/telechargement.
  static String nomFichier(String theme) {
    final safe = theme
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâ]'), 'a')
        .replaceAll(RegExp(r'[ùû]'), 'u')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'ç'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'fiche_${safe.isEmpty ? 'cours' : safe}.pdf';
  }

  /// Bulletin de notes officiel (calque sur le modele papier utilise par les
  /// ecoles) : identite eleve/ecole, notes de la periode active par matiere,
  /// moyennes des 3 trimestres + moyenne generale, rang dans la classe.
  /// Reste toujours en francais (document officiel remis aux parents), quelle
  /// que soit la langue de l'interface — meme convention que les messages
  /// WhatsApp.
  static Future<Uint8List> genererBulletinPdf({
    required Eleve eleve,
    required Classe classe,
    required Enseignant enseignant,
    required String periode,
    required List<Note> notesPeriode,
    required double? moyenneT1,
    required double? moyenneT2,
    required double? moyenneT3,
    required int? rang,
    required int effectif,
  }) async {
    final doc = pw.Document();
    final moyennePeriode = NoteService.moyennePonderee(notesPeriode);
    final totalPoints = notesPeriode.fold<double>(
      0,
      (a, n) => a + n.valeur * n.coefficient,
    );
    final moyennesTrimestres = [
      moyenneT1,
      moyenneT2,
      moyenneT3,
    ].whereType<double>().toList();
    final moyenneGenerale = moyennesTrimestres.isEmpty
        ? null
        : moyennesTrimestres.reduce((a, b) => a + b) /
              moyennesTrimestres.length;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _bulletinEntete(enseignant, classe),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey900, width: 1.2),
                ),
                child: pw.Text(
                  'BULLETIN DE NOTES ${_trimestreLabel(periode)} TRIMESTRE',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(flex: 2, child: _champ('Prénoms', eleve.prenom)),
                pw.SizedBox(width: 16),
                pw.Expanded(child: _champ('Nom', eleve.nom)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 3, child: _tableauNotes(notesPeriode)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  flex: 2,
                  child: _blocAppreciations(_appreciation(moyennePeriode)),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _champ(
                    'Total',
                    '${totalPoints.toStringAsFixed(1)} Pts',
                  ),
                ),
                pw.Expanded(
                  child: _champ(
                    'Moyenne',
                    moyennePeriode == null
                        ? '—/20'
                        : '${moyennePeriode.toStringAsFixed(1)}/20',
                  ),
                ),
                pw.Expanded(
                  child: _champ(
                    'Rang',
                    rang == null
                        ? '—'
                        : '$rang${rang == 1 ? 'er' : 'ème'}/$effectif',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            _tableauTrimestres(
              moyenneT1,
              moyenneT2,
              moyenneT3,
              moyenneGenerale,
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _champ('M./Mme', enseignant.nom),
                _champ('Décision', ''),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Le Directeur',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _bulletinEntete(Enseignant enseignant, Classe classe) {
    final now = DateTime.now();
    pw.TextStyle style() => const pw.TextStyle(fontSize: 9.5);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'IA : ${enseignant.ia ?? '..........................'}',
                style: style(),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'IEF : ${enseignant.ief ?? '.........................'}',
                style: style(),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'ECOLE : ${enseignant.ecole ?? '..........................'}',
                style: style(),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ANNEE SCOLAIRE : ${_anneeScolaire(now)}',
                style: style(),
              ),
              pw.SizedBox(height: 4),
              pw.Text('COURS : ${classe.niveau}', style: style()),
              pw.SizedBox(height: 4),
              pw.Text('M./Mme : ${enseignant.nom}', style: style()),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _champ(String label, String valeur) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(valeur, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _tableauNotes(List<Note> notes) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
      columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _celluleEntete('Disciplines'),
            _celluleEntete('Note / sur'),
          ],
        ),
        ...notes.map(
          (n) => pw.TableRow(
            children: [
              _cellule(n.matiere),
              _cellule('${n.valeur.toStringAsFixed(1)} / 20'),
            ],
          ),
        ),
        if (notes.isEmpty)
          pw.TableRow(children: [_cellule('—'), _cellule('—')]),
      ],
    );
  }

  static pw.Widget _celluleEntete(String texte) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      texte,
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _cellule(String texte) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(texte, style: const pw.TextStyle(fontSize: 9.5)),
  );

  static const _appreciations = [
    'Excellent',
    'Félicitations',
    'Encouragements',
    "Tableau d'honneur",
    'Passable, peut mieux faire',
    'Insuffisant',
  ];

  static pw.Widget _blocAppreciations(String? active) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Appréciations',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ..._appreciations.map(
            (a) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 9,
                    height: 9,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey900,
                        width: 0.8,
                      ),
                      color: a == active ? PdfColors.grey900 : null,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text(a, style: const pw.TextStyle(fontSize: 8.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableauTrimestres(
    double? t1,
    double? t2,
    double? t3,
    double? generale,
  ) {
    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(1);
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _celluleEntete('1ère MOY'),
            _celluleEntete('2ème MOY'),
            _celluleEntete('3ème MOY'),
            _celluleEntete('MOY. GENERALE'),
          ],
        ),
        pw.TableRow(
          children: [
            _cellule(fmt(t1)),
            _cellule(fmt(t2)),
            _cellule(fmt(t3)),
            _cellule(fmt(generale)),
          ],
        ),
      ],
    );
  }

  static String _trimestreLabel(String periode) => switch (periode) {
    'T1' => '1er',
    'T2' => '2ème',
    'T3' => '3ème',
    _ => periode,
  };

  static String _anneeScolaire(DateTime date) {
    final y = date.year;
    return date.month >= 9 ? '$y-${y + 1}' : '${y - 1}-$y';
  }

  /// Appreciation globale deduite de la moyenne de la periode. Seuils
  /// arbitraires (pas de standard officiel unique) mais coherents avec
  /// `kSeuilReussite` (10/20) utilise partout ailleurs dans l'app.
  static String? _appreciation(double? moyenne) {
    if (moyenne == null) return null;
    if (moyenne >= 16) return 'Excellent';
    if (moyenne >= 14) return 'Félicitations';
    if (moyenne >= 12) return 'Encouragements';
    if (moyenne >= 10) return "Tableau d'honneur";
    if (moyenne >= 8) return 'Passable, peut mieux faire';
    return 'Insuffisant';
  }

  /// Nom de fichier propose pour le bulletin (sans espaces/accents).
  static String nomFichierBulletin(Eleve eleve, String periode) {
    final safe = eleve.nomComplet
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâ]'), 'a')
        .replaceAll(RegExp(r'[ùû]'), 'u')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'ç'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'bulletin_${safe.isEmpty ? 'eleve' : safe}_$periode.pdf';
  }
}
