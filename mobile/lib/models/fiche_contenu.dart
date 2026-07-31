/// Contenu structure d'une fiche de cours generee par Grok.
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
