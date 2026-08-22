import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/enseignant.dart';

/// Auth email/mot de passe Firebase : l'email saisi par l'enseignant est
/// l'identifiant reel du compte (utilise aussi pour la reinitialisation du
/// PIN via `resetPassword`), le PIN sert de mot de passe (Firebase impose
/// >= 6 caracteres, d'ou un PIN a 6 chiffres minimum).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<Enseignant> register({
    required String nom,
    required String email,
    required String pin,
    String? ecole,
    String? telephone,
    String? ia,
    String? ief,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pin,
      );
      final uid = credential.user!.uid;
      final enseignant = Enseignant(
        uid: uid,
        nom: nom,
        email: email,
        ecole: ecole,
        telephone: telephone,
        ia: ia,
        ief: ief,
      );
      await _db.collection('enseignants').doc(uid).set(enseignant.toMap());
      try {
        await credential.user!.sendEmailVerification();
      } catch (_) {
        // Non bloquant : le compte est deja cree, l'enseignant peut
        // redemander l'email de verification depuis le tableau de bord.
      }
      return enseignant;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  bool get emailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<bool> refreshEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<Enseignant> login({required String email, required String pin}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: pin,
      );
      final uid = credential.user!.uid;
      final doc = await _db.collection('enseignants').doc(uid).get();
      if (!doc.exists) throw AuthException('Profil enseignant introuvable');
      // Compte desactive depuis le back-office admin (`actif: false`) :
      // absent du champ = actif, retrocompatible avec les comptes crees
      // avant son introduction.
      if (doc.data()!['actif'] == false) {
        await _auth.signOut();
        throw AuthException(
          'Ce compte a ete desactive. Contactez votre administrateur.',
        );
      }
      return Enseignant.fromMap(uid, doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Toujours silencieux cote resultat (pas d'exception "utilisateur
  /// introuvable") : evite de reveler si un email correspond a un compte
  /// existant (protection contre l'enumeration de comptes).
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
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
        return 'Cette adresse email est deja utilisee';
      case 'weak-password':
        return 'Le code PIN doit contenir au moins 6 chiffres';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou code PIN incorrect';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'network-request-failed':
        return 'Pas de connexion internet';
      case 'too-many-requests':
        return 'Trop de tentatives, réessayez plus tard';
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
