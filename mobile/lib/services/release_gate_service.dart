import 'package:cloud_firestore/cloud_firestore.dart';

/// Verrou a distance pour les builds de test (APK partage hors store, voir
/// PRESENTATION.md) : lit `app_config/release.expiresAt` et permet de couper
/// l'acces a une version de test depuis la console Firebase, sans devoir
/// renvoyer un nouvel APK aux testeurs. Doc public en lecture (voir
/// firestore.rules), ecriture reservee a l'admin (console/Admin SDK).
///
/// Fail-open : en cas d'erreur (pas de reseau, doc absent...) l'app reste
/// utilisable. Ce n'est pas un verrou de securite dur (contournable hors
/// ligne tant que le cache local n'a pas vu la nouvelle valeur), juste un
/// interrupteur pratique pour une phase de test.
class ReleaseGateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isExpired() async {
    try {
      final doc = await _db.collection('app_config').doc('release').get();
      final expiresAt = doc.data()?['expiresAt'] as Timestamp?;
      if (expiresAt == null) return false;
      return DateTime.now().isAfter(expiresAt.toDate());
    } catch (_) {
      return false;
    }
  }
}
