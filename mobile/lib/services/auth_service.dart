import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/enseignant.dart';

/// Firebase Auth n'a pas de mode "telephone + code PIN persistant" : l'auth
/// telephone de Firebase envoie un OTP par SMS a chaque connexion, ce qui ne
/// correspond pas a la maquette (champ PIN memorise, pas de code recu).
/// On simule donc le flux de la maquette avec Auth email/mot de passe : le
/// telephone est transforme en identifiant email synthetique et le PIN sert
/// de mot de passe (Firebase impose >= 6 caracteres, d'ou un PIN a 6 chiffres).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  String _emailFor(String telephone) {
    final digits = telephone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@jangalekat.app';
  }

  Future<Enseignant> register({
    required String nom,
    required String telephone,
    required String pin,
    String? ecole,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailFor(telephone),
        password: pin,
      );
      final uid = credential.user!.uid;
      final enseignant = Enseignant(
        uid: uid,
        nom: nom,
        telephone: telephone,
        ecole: ecole,
      );
      await _db.collection('enseignants').doc(uid).set(enseignant.toMap());
      return enseignant;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<Enseignant> login({
    required String telephone,
    required String pin,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailFor(telephone),
        password: pin,
      );
      final uid = credential.user!.uid;
      final doc = await _db.collection('enseignants').doc(uid).get();
      if (!doc.exists) throw AuthException('Profil enseignant introuvable');
      return Enseignant.fromMap(uid, doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<Enseignant?> loadProfile(String uid) async {
    final doc = await _db.collection('enseignants').doc(uid).get();
    if (!doc.exists) return null;
    return Enseignant.fromMap(uid, doc.data()!);
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ce numero de telephone est deja utilise';
      case 'weak-password':
        return 'Le code PIN doit contenir au moins 6 chiffres';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Numero de telephone ou code PIN incorrect';
      case 'invalid-email':
        return 'Numero de telephone invalide';
      case 'network-request-failed':
        return 'Pas de connexion internet';
      default:
        return 'Une erreur est survenue (${e.code})';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
