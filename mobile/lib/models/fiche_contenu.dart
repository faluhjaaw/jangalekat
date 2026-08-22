/// Contenu structure d'une fiche de cours generee par Gemini.
/// Chaque section est un texte libre (affiche dans sa propre carte a
/// l'ecran, modifiable independamment sur l'ecran d'edition).
class FicheContenu {
  final String objectifs;
  final String prerequis;
  final String deroulement;
  final String activites;
  final String evaluation;
  final String resume;

  FicheContenu({
    required this.objectifs,
    required this.prerequis,
    required this.deroulement,
    required this.activites,
    required this.evaluation,
    required this.resume,
  });

  factory FicheContenu.fromJson(Map<String, dynamic> json) => FicheContenu(
    objectifs: json['objectifs'] as String? ?? '',
    prerequis: json['prerequis'] as String? ?? '',
    deroulement: json['deroulement'] as String? ?? '',
    activites: json['activites'] as String? ?? '',
    evaluation: json['evaluation'] as String? ?? '',
    resume: json['resume'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'objectifs': objectifs,
    'prerequis': prerequis,
    'deroulement': deroulement,
    'activites': activites,
    'evaluation': evaluation,
    'resume': resume,
  };

  FicheContenu copyWith({
    String? objectifs,
    String? prerequis,
    String? deroulement,
    String? activites,
    String? evaluation,
    String? resume,
  }) => FicheContenu(
    objectifs: objectifs ?? this.objectifs,
    prerequis: prerequis ?? this.prerequis,
    deroulement: deroulement ?? this.deroulement,
    activites: activites ?? this.activites,
    evaluation: evaluation ?? this.evaluation,
    resume: resume ?? this.resume,
  );

  /// Rendu texte simple, utilise pour le partage (WhatsApp, autres apps).
  String toPlainText({required String titre}) =>
      '''
$titre

OBJECTIFS
$objectifs

PREREQUIS
$prerequis

DEROULEMENT
$deroulement

ACTIVITES
$activites

EVALUATION
$evaluation

RESUME
$resume
'''
          .trim();
}

/// Une ligne de contenu de section : soit un item de liste (marqueur non
/// nul, "1." ou "•"), soit un paragraphe simple (marqueur nul).
class FicheLine {
  final String? marker;
  final String texte;
  const FicheLine({this.marker, required this.texte});
  bool get isListItem => marker != null;
}

final _kBulletPattern = RegExp(r'^(\d+[.)]|[-•])\s+');

/// Malgre la consigne "texte brut" du prompt, Gemini glisse parfois du
/// Markdown (**gras**, _italique_, `code`, #titres) dans le JSON. L'app
/// n'interprete jamais de Markdown ailleurs : on le retire plutot que de
/// laisser les symboles bruts (ex. "**") s'afficher a l'ecran ou dans le PDF.
String _stripMarkdown(String s) {
  var out = s;
  out = out.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!);
  out = out.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!);
  out = out.replaceAllMapped(
    RegExp(r'(?<!\*)\*([^*\n]+?)\*(?!\*)'),
    (m) => m.group(1)!,
  );
  out = out.replaceAllMapped(
    RegExp(r'(?<!_)_([^_\n]+?)_(?!_)'),
    (m) => m.group(1)!,
  );
  out = out.replaceAllMapped(RegExp(r'`([^`]+?)`'), (m) => m.group(1)!);
  out = out.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
  // Nettoyage des marqueurs restes non-apparies (ex. un seul "**" isole).
  return out.replaceAll('**', '').replaceAll('__', '');
}

/// Gemini renvoie parfois une liste numerotee/a puces dans une section
/// ("1. ...\n2. ..."), parfois un paragraphe continu. On decoupe en lignes
/// structurees uniquement si un vrai marqueur de liste est detecte, pour que
/// l'affichage (app + PDF) rende chaque etape separement plutot qu'un bloc
/// de texte compact difficile a lire pour un enseignant.
List<FicheLine> parseFicheTexte(String texte) {
  final propre = _stripMarkdown(texte);
  if (propre.trim().isEmpty) return const [];
  final lignes = propre
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  final aUneListe = lignes.any((l) => _kBulletPattern.hasMatch(l));
  if (!aUneListe) return [FicheLine(texte: propre.trim())];

  return lignes.map((l) {
    final match = _kBulletPattern.firstMatch(l);
    if (match == null) return FicheLine(texte: l);
    final marker = match.group(1)!;
    final reste = l.substring(match.end);
    final numerote = RegExp(r'\d').hasMatch(marker);
    return FicheLine(marker: numerote ? marker : '•', texte: reste);
  }).toList();
}
