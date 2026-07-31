/// Matiere + coefficient, propre a chaque classe (stockee dans le champ
/// `matieres` du document classe, pas de sous-collection : la liste reste
/// petite et editee en bloc par l'enseignant).
class Matiere {
  final String nom;
  final int coefficient;
  const Matiere(this.nom, this.coefficient);

  factory Matiere.fromMap(Map<String, dynamic> data) => Matiere(
    data['nom'] as String? ?? '',
    (data['coefficient'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toMap() => {'nom': nom, 'coefficient': coefficient};
}

/// Matieres de depart proposees a la creation d'une classe (modifiables
/// ensuite par l'enseignant, classe par classe).
const List<Matiere> kMatieresDefaut = [
  Matiere('Français', 3),
  Matiere('Mathématiques', 3),
  Matiere('Sciences', 2),
  Matiere('Histoire-Géo', 2),
  Matiere('Anglais', 1),
];
