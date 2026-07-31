import 'classe.dart';
import 'eleve.dart';

/// Agregat classe + effectif + moyenne, utilise par le tableau de bord et
/// la liste des classes (evite de refaire les memes appels API deux fois).
class ClasseSummary {
  final Classe classe;
  final List<Eleve> eleves;
  final double? moyenne;

  ClasseSummary({required this.classe, required this.eleves, this.moyenne});

  int get studentCount => eleves.length;
}
