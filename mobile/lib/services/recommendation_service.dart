import 'package:cloud_firestore/cloud_firestore.dart';

/// Acces Firestore pour la collection `recommandations` (a plat, comme
/// `messages` sous chaque enseignant) : suggestions envoyees par les
/// enseignants a l'equipe Jangalekat, lues cote back-office uniquement (pas
/// d'ecran de lecture dans l'app).
class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;
  final String nom;
  RecommendationService(this.uid, this.nom);

  Future<void> envoyer(String message) {
    return _db.collection('recommandations').add({
      'enseignantUid': uid,
      'enseignantNom': nom,
      'message': message,
      'createdAt': Timestamp.now(),
    });
  }
}
