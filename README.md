# Jàngalekat

Application de gestion scolaire pour enseignants : classes, élèves, notes (moyenne
pondérée par coefficient) et envoi des résultats aux parents via WhatsApp.

- `mobile/` — application Flutter (Android prioritaire), Firebase Auth + Cloud
  Firestore, aucun backend serveur.
- `admin/` — back office web (React + Vite), gestion des enseignants et
  suivi des messages/statistiques, même projet Firebase (voir `admin/README.md`).
- `design/` — maquettes Claude Design (référence visuelle).

Architecture volontairement simple côté mobile : `models/`, `screens/`,
`services/` (accès Firestore), `widgets/`. Pas de Clean Architecture, pas de
couches inutiles. La logique métier (moyennes, statistiques) est calculée en
Dart, côté client — pas de Cloud Functions pour le MVP.

Il n'y a plus de backend : l'ancienne version Spring Boot + PostgreSQL a été
entièrement supprimée au profit de Firebase.

## 1. Créer le projet Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → **Ajouter un projet** (ex. `jangalekat-app`).
2. **Authentication** → Sign-in method → activer **E-mail/Mot de passe**.
   L'email saisi par l'enseignant est son identifiant réel (envoi d'un email
   de vérification à l'inscription, réinitialisation du PIN par email —
   voir §4 "Premier lancement").
3. **Firestore Database** → créer une base, mode production (les règles du
   dépôt remplacent les règles par défaut, voir §3).
4. Ajouter une application **Android** au projet :
   - package name : `com.jangalekat.jangalekat_mobile` (ou le vôtre, mais il
     doit correspondre à `mobile/android/app/build.gradle.kts` → `applicationId`)
   - téléchargez `google-services.json` et placez-le dans `mobile/android/app/`
     (déjà présent et commité dans ce dépôt pour le projet `jangalekat` — à
     remplacer seulement si vous pointez vers votre propre projet Firebase).

### Générer `firebase_options.dart`

Le fichier `mobile/lib/firebase_options.dart` versionné n'est qu'un
**placeholder** (fausses clés). Générez le vrai fichier avec FlutterFire CLI :

```bash
dart pub global activate flutterfire_cli
cd mobile
flutterfire configure
```

La commande se connecte à votre compte Google, liste vos projets Firebase,
enregistre l'app Android/iOS si besoin et régénère `firebase_options.dart`
avec les vraies clés.

## 2. Règles de sécurité Firestore

Le fichier `mobile/firestore.rules` restreint chaque enseignant à son propre
sous-arbre :

```
enseignants/{uid}/**  →  lisible/modifiable seulement si request.auth.uid == uid
```

Déployez-les :

```bash
cd mobile
firebase login
firebase use --add        # selectionner le projet cree a l'etape 1
firebase deploy --only firestore:rules
```

## 3. Modèle de données Firestore

```
enseignants/{uid}
  nom, email, ecole?, telephone?

enseignants/{uid}/classes/{classeId}
  nom, niveau, effectif        # effectif tenu a jour via FieldValue.increment

enseignants/{uid}/classes/{classeId}/eleves/{eleveId}
  nom, prenom, telephoneParent, nomParent?

enseignants/{uid}/classes/{classeId}/eleves/{eleveId}/notes/{matiere}__{periode}
  matiere, valeur, coefficient, periode, date   # id deterministe = upsert direct

enseignants/{uid}/messages/{messageId}
  eleveId, eleveNom, classeId, classeNom, contenu, type, statut,
  telephoneDestinataire, dateEnvoi
```

Collection `messages` à plat (pas sous chaque élève) pour permettre une seule
requête "historique complet" triée par date. Les champs `eleveNom`/`classeNom`
sont dénormalisés : Firestore ne fait pas de jointures.

## 4. Lancer l'app

Prérequis : Flutter SDK (stable), Android Studio / SDK Android.

```bash
cd mobile
flutter pub get
flutter run
```

Le cache hors-ligne Firestore est activé explicitement dans `main.dart`
(`Settings(persistenceEnabled: true)`) — important pour les enseignants en
zone de faible connectivité : les classes/élèves/notes déjà chargés restent
consultables et modifiables hors ligne, la synchronisation se fait au retour
du réseau.

### Premier lancement

L'écran de connexion ne crée pas de compte : utilisez le lien « Créer un
compte enseignant » (ajout pragmatique hors maquette, nécessaire pour
s'inscrire avant la première connexion) pour créer un enseignant, puis
connectez-vous avec l'email + PIN choisis. Un email de vérification est
envoyé automatiquement à l'inscription (lien Firebase natif, pas de backend) ;
tant qu'il n'est pas cliqué, une bannière incitative s'affiche sur le tableau
de bord mais n'empêche pas d'utiliser l'app. « Code oublié ? » sur l'écran de
connexion envoie un vrai email de réinitialisation du PIN.

## 5. Fiches de cours (Gemini)

La génération de fiches de cours (onglet "Fiches") appelle l'API Gemini
(Google AI Studio).

### Obtenir une clé API Gemini

### Où la placer

```bash
cd mobile
cp .env.example .env
```

Puis éditez `mobile/.env` :

```
GEMINI_API_KEY=votre-cle-ici
# optionnel, sinon gemini-2.5-flash par defaut :
# GEMINI_MODEL=gemini-2.5-flash
```

## Choix et limites assumés

- **Auth email + PIN** : l'email saisi à l'inscription est l'identifiant réel
  du compte Firebase Auth (email/mot de passe), le PIN sert de mot de passe.
  Ça permet la vérification d'email et la réinitialisation du PIN nativement
  via Firebase (`sendEmailVerification`, `sendPasswordResetEmail`), sans
  backend. Conséquence : **le PIN doit faire 6 chiffres minimum** (contrainte
  Firebase), pas 4 comme illustré dans la maquette d'origine. Le téléphone
  reste un champ de profil optionnel (contact), plus utilisé pour la
  connexion.
- **Vérification d'email = incitative, pas bloquante** : un compte non
  vérifié a un accès complet à l'app (aucune règle Firestore ni check client
  ne conditionne quoi que ce soit à `emailVerified`). La bannière sur le
  tableau de bord est un nudge, pas un gate — choix assumé pour ne pas
  bloquer un enseignant en zone de faible connectivité qui n'a pas encore pu
  consulter sa boîte mail.
- **wa.me ne permet pas un vrai envoi groupé** : un lien `wa.me` n'ouvre qu'une
  seule conversation WhatsApp à la fois. L'écran "Envoyer aux parents" en mode
  groupé fait donc avancer l'enseignant destinataire par destinataire (bouton
  "Suivant : Prénom (i/N)"), chaque envoi étant journalisé dans
  `enseignants/{uid}/messages`. Un vrai envoi groupé nécessiterait l'API
  WhatsApp Business Cloud + une Cloud Function, explicitement hors scope MVP.
- **Période fixe** : l'app travaille sur une seule période (`T2`, trimestre 2
  affiché) — pas de sélecteur de trimestre, hors scope des maquettes fournies.
- **Historique = messages envoyés** : le modèle de données ne conserve que
  l'historique des envois WhatsApp, pas un journal générique d'activité
  (saisie de notes, absences...).
- **Pas de génération de bulletin PDF** : ni les maquettes ni le cahier des
  charges ne décrivent cette fonctionnalité ; le bouton correspondant n'a pas
  été implémenté pour éviter une fausse promesse.
- **Statut des messages** : sans Cloud Function, le statut enregistré
  (`envoye`/`echec`) reflète seulement l'ouverture réussie de WhatsApp sur
  l'appareil, pas une confirmation de livraison au parent.
- **Fiches de cours — en cours** : génération + affichage fonctionnels.
  Enregistrement dans `enseignants/{uid}/fiches`, historique, édition et
  partage ne sont pas encore branchés (modèle `FicheCours` déjà prêt côté
  code, écrans à venir).
- **Matières par classe** : chaque classe a sa propre liste de matières
  (champ `matieres` sur le document classe), plus une liste globale fixe.
  Modifiable depuis l'écran "Saisir les notes" (bouton "Gérer").
