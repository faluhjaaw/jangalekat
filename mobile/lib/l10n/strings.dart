/// Langue de l'interface de l'application (distincte de la langue de la
/// fiche de cours generee par l'IA, qui reste FR/Wolof separement).
enum AppLocale { fr, en }

/// Dictionnaire de traduction minimaliste : pas de generation de code ni de
/// fichiers .arb (architecture simple), juste une map cle -> {fr, en}.
/// Les cles suivent la convention "ecran.element".
class Strings {
  Strings._();

  static const Map<String, Map<AppLocale, String>> _dict = {
    // Commun
    'common.seeAll': {AppLocale.fr: 'Voir tout', AppLocale.en: 'See all'},
    'common.manage': {AppLocale.fr: 'Gérer', AppLocale.en: 'Manage'},

    // Parametres (langue + deconnexion)
    'settings.title': {AppLocale.fr: 'Paramètres', AppLocale.en: 'Settings'},
    'settings.language': {
      AppLocale.fr: 'Langue de l\'application',
      AppLocale.en: 'App language',
    },
    'settings.logout': {
      AppLocale.fr: 'Se déconnecter',
      AppLocale.en: 'Log out',
    },
    'settings.darkMode': {
      AppLocale.fr: 'Mode sombre',
      AppLocale.en: 'Dark mode',
    },
    'settings.support': {
      AppLocale.fr: 'Aide & Support',
      AppLocale.en: 'Help & Support',
    },
    'settings.recommendations': {
      AppLocale.fr: 'Recommandations',
      AppLocale.en: 'Recommendations',
    },

    // Aide & Support
    'support.title': {AppLocale.fr: 'Aide & Support', AppLocale.en: 'Help & Support'},
    'support.faqTitle': {
      AppLocale.fr: 'Questions fréquentes',
      AppLocale.en: 'Frequently asked questions',
    },
    'support.faq1Q': {
      AppLocale.fr: "J'ai oublié mon code PIN, que faire ?",
      AppLocale.en: 'I forgot my PIN code, what should I do?',
    },
    'support.faq1A': {
      AppLocale.fr:
          "Appuyez sur \"Code oublié ?\" sur l'écran de connexion et entrez votre adresse email : un lien de réinitialisation vous sera envoyé.",
      AppLocale.en:
          'Tap "Forgot code?" on the login screen and enter your email address: a reset link will be sent to you.',
    },
    'support.faq2Q': {
      AppLocale.fr: 'Comment ajouter une classe ?',
      AppLocale.en: 'How do I add a class?',
    },
    'support.faq2A': {
      AppLocale.fr:
          'Depuis l\'onglet "Mes classes", appuyez sur "+ Ajouter une classe" et renseignez son nom et niveau.',
      AppLocale.en:
          'From the "My classes" tab, tap "+ Add a class" and fill in its name and level.',
    },
    'support.faq3Q': {
      AppLocale.fr: 'Mes données sont-elles sauvegardées hors ligne ?',
      AppLocale.en: 'Is my data saved offline?',
    },
    'support.faq3A': {
      AppLocale.fr:
          'Oui, les modifications faites hors ligne sont synchronisées automatiquement dès que la connexion revient.',
      AppLocale.en:
          'Yes, changes made offline are synced automatically once the connection is back.',
    },
    'support.contactTitle': {
      AppLocale.fr: 'Nous contacter',
      AppLocale.en: 'Contact us',
    },
    'support.contactWhatsapp': {
      AppLocale.fr: 'Contacter via WhatsApp',
      AppLocale.en: 'Contact via WhatsApp',
    },
    'support.contactEmail': {
      AppLocale.fr: 'Contacter par email',
      AppLocale.en: 'Contact by email',
    },
    'support.openError': {
      AppLocale.fr: "Impossible d'ouvrir l'application",
      AppLocale.en: 'Unable to open the app',
    },

    // Recommandations
    'recommendations.title': {
      AppLocale.fr: 'Recommandations',
      AppLocale.en: 'Recommendations',
    },
    'recommendations.subtitle': {
      AppLocale.fr:
          'Une idée pour améliorer Jàngalekat ? Partagez-la avec nous.',
      AppLocale.en: 'An idea to improve Jàngalekat? Share it with us.',
    },
    'recommendations.hint': {
      AppLocale.fr: 'Décrivez votre recommandation...',
      AppLocale.en: 'Describe your recommendation...',
    },
    'recommendations.send': {AppLocale.fr: 'Envoyer', AppLocale.en: 'Send'},
    'recommendations.sending': {
      AppLocale.fr: 'Envoi...',
      AppLocale.en: 'Sending...',
    },
    'recommendations.sent': {
      AppLocale.fr: 'Merci, votre recommandation a été envoyée ✓',
      AppLocale.en: 'Thank you, your recommendation was sent ✓',
    },
    'recommendations.empty': {
      AppLocale.fr: 'Veuillez écrire un message avant d\'envoyer',
      AppLocale.en: 'Please write a message before sending',
    },
    'recommendations.error': {
      AppLocale.fr: "Impossible d'envoyer la recommandation",
      AppLocale.en: 'Unable to send the recommendation',
    },

    // Connexion
    'login.subtitle': {
      AppLocale.fr: 'Espace enseignant',
      AppLocale.en: 'Teacher space',
    },
    'login.email': {
      AppLocale.fr: 'Adresse email',
      AppLocale.en: 'Email address',
    },
    'login.pin': {AppLocale.fr: 'Code PIN', AppLocale.en: 'PIN code'},
    'login.connect': {AppLocale.fr: 'Se connecter', AppLocale.en: 'Sign in'},
    'login.connecting': {
      AppLocale.fr: 'Connexion...',
      AppLocale.en: 'Signing in...',
    },
    'login.error': {
      AppLocale.fr: 'Impossible de se connecter',
      AppLocale.en: 'Unable to sign in',
    },
    'login.forgot': {
      AppLocale.fr: 'Code oublié ?',
      AppLocale.en: 'Forgot code?',
    },
    'login.emailRequired': {
      AppLocale.fr: 'Adresse email requise',
      AppLocale.en: 'Email address is required',
    },
    'login.emailInvalid': {
      AppLocale.fr: 'Adresse email invalide',
      AppLocale.en: 'Invalid email address',
    },
    'login.pinRequired': {
      AppLocale.fr: 'Code PIN requis',
      AppLocale.en: 'PIN code is required',
    },
    'login.createAccount': {
      AppLocale.fr: 'Créer un compte enseignant',
      AppLocale.en: 'Create a teacher account',
    },
    'login.forgotTitle': {
      AppLocale.fr: 'Réinitialiser le code PIN',
      AppLocale.en: 'Reset PIN code',
    },
    'login.forgotMessage': {
      AppLocale.fr:
          'Entrez votre adresse email : si elle correspond à un compte, un lien de réinitialisation vous sera envoyé.',
      AppLocale.en:
          "Enter your email address: if it matches an account, a reset link will be sent to you.",
    },
    'login.forgotSend': {
      AppLocale.fr: 'Envoyer le lien',
      AppLocale.en: 'Send link',
    },
    'login.forgotSending': {
      AppLocale.fr: 'Envoi...',
      AppLocale.en: 'Sending...',
    },
    'login.forgotResend': {
      AppLocale.fr: 'Renvoyer le lien',
      AppLocale.en: 'Resend link',
    },
    'login.forgotSuccess': {
      AppLocale.fr:
          'Si cette adresse est associée à un compte, un email de réinitialisation vient d\'être envoyé.',
      AppLocale.en:
          'If this address is linked to an account, a reset email was just sent.',
    },

    // Tableau de bord
    'dashboard.greeting': {AppLocale.fr: 'Bonjour', AppLocale.en: 'Hello'},
    'dashboard.offlineBanner': {
      AppLocale.fr:
          'Hors ligne — les modifications seront synchronisées plus tard',
      AppLocale.en: 'Offline — changes will sync later',
    },
    'dashboard.verifyEmailBanner': {
      AppLocale.fr:
          'Un email de vérification vous a été envoyé — cliquez sur le lien reçu, ou renvoyez-le ci-dessous.',
      AppLocale.en:
          'A verification email was sent to you — click the link you received, or resend it below.',
    },
    'dashboard.verifyEmailResend': {
      AppLocale.fr: 'Renvoyer',
      AppLocale.en: 'Resend',
    },
    'dashboard.verifyEmailCheck': {
      AppLocale.fr: "J'ai vérifié",
      AppLocale.en: 'I verified',
    },
    'dashboard.verifyEmailSent': {
      AppLocale.fr: 'Email de vérification envoyé',
      AppLocale.en: 'Verification email sent',
    },
    'dashboard.verifyEmailStillNot': {
      AppLocale.fr: 'Pas encore vérifié — vérifiez votre boîte mail',
      AppLocale.en: 'Not verified yet — check your inbox',
    },
    'dashboard.verifyEmailError': {
      AppLocale.fr: "Impossible d'envoyer l'email",
      AppLocale.en: 'Unable to send the email',
    },
    'dashboard.error': {
      AppLocale.fr: 'Impossible de charger le tableau de bord',
      AppLocale.en: 'Unable to load the dashboard',
    },
    'dashboard.statClasses': {AppLocale.fr: 'Classes', AppLocale.en: 'Classes'},
    'dashboard.statStudents': {
      AppLocale.fr: 'Élèves',
      AppLocale.en: 'Students',
    },
    'dashboard.statSchoolAvg': {
      AppLocale.fr: 'Moyenne école',
      AppLocale.en: 'School average',
    },
    'dashboard.quickActions': {
      AppLocale.fr: 'Actions rapides',
      AppLocale.en: 'Quick actions',
    },
    'dashboard.actionGrades': {
      AppLocale.fr: 'Saisir des notes',
      AppLocale.en: 'Enter grades',
    },
    'dashboard.actionWhatsapp': {
      AppLocale.fr: 'Envoyer aux parents',
      AppLocale.en: 'Send to parents',
    },
    'dashboard.actionClasses': {
      AppLocale.fr: 'Mes classes',
      AppLocale.en: 'My classes',
    },
    'dashboard.actionHistory': {
      AppLocale.fr: 'Historique',
      AppLocale.en: 'History',
    },
    'dashboard.actionFiches': {
      AppLocale.fr: 'Fiches de cours (IA)',
      AppLocale.en: 'Lesson plans (AI)',
    },
    'dashboard.myClasses': {
      AppLocale.fr: 'Mes classes',
      AppLocale.en: 'My classes',
    },
    'dashboard.recentActivity': {
      AppLocale.fr: 'Dernières activités',
      AppLocale.en: 'Recent activity',
    },
    'dashboard.noRecentActivity': {
      AppLocale.fr: 'Aucune activité récente',
      AppLocale.en: 'No recent activity',
    },
    'dashboard.messageSentTo': {
      AppLocale.fr: 'Message envoyé à',
      AppLocale.en: 'Message sent to',
    },
    'time.justNow': {AppLocale.fr: "À l'instant", AppLocale.en: 'Just now'},
    'time.today': {AppLocale.fr: "Aujourd'hui", AppLocale.en: 'Today'},
    'time.yesterday': {AppLocale.fr: 'Hier', AppLocale.en: 'Yesterday'},

    // Navigation
    'nav.home': {AppLocale.fr: 'Accueil', AppLocale.en: 'Home'},
    'nav.classes': {AppLocale.fr: 'Classes', AppLocale.en: 'Classes'},
    'nav.history': {AppLocale.fr: 'Historique', AppLocale.en: 'History'},
    'nav.fiches': {AppLocale.fr: 'Fiches', AppLocale.en: 'Plans'},

    // Periode / trimestre actif (voir AppState.periode)
    'period.t1': {AppLocale.fr: 'Trimestre 1', AppLocale.en: 'Term 1'},
    'period.t2': {AppLocale.fr: 'Trimestre 2', AppLocale.en: 'Term 2'},
    'period.t3': {AppLocale.fr: 'Trimestre 3', AppLocale.en: 'Term 3'},
    'period.sectionLabel': {AppLocale.fr: 'Trimestre', AppLocale.en: 'Term'},

    // Langues (labels des boutons FR/Wolof choisis pour la fiche generee —
    // suit la langue d'interface, independant du choix lui-meme)
    'lang.fr': {AppLocale.fr: 'Français', AppLocale.en: 'French'},
    'lang.wolof': {AppLocale.fr: 'Wolof', AppLocale.en: 'Wolof'},

    // Mes classes
    'classes.title': {AppLocale.fr: 'Mes classes', AppLocale.en: 'My classes'},
    'classes.summaryClasses': {
      AppLocale.fr: 'classes',
      AppLocale.en: 'classes',
    },
    'classes.summaryStudents': {
      AppLocale.fr: 'élèves',
      AppLocale.en: 'students',
    },
    'classes.error': {
      AppLocale.fr: 'Impossible de charger les classes',
      AppLocale.en: 'Unable to load classes',
    },
    'classes.add': {
      AppLocale.fr: '+ Ajouter une classe',
      AppLocale.en: '+ Add a class',
    },
    'classes.sheetTitle': {
      AppLocale.fr: 'Ajouter une classe',
      AppLocale.en: 'Add a class',
    },
    'classes.name': {AppLocale.fr: 'Nom', AppLocale.en: 'Name'},
    'classes.level': {AppLocale.fr: 'Niveau', AppLocale.en: 'Level'},
    'classes.create': {
      AppLocale.fr: 'Créer la classe',
      AppLocale.en: 'Create class',
    },
    'classes.createError': {
      AppLocale.fr: 'Impossible de créer la classe',
      AppLocale.en: 'Unable to create the class',
    },
    'classes.requiredFields': {
      AppLocale.fr: 'Nom et niveau requis',
      AppLocale.en: 'Name and level are required',
    },

    // Detail classe
    'classDetail.error': {
      AppLocale.fr: 'Impossible de charger la classe',
      AppLocale.en: 'Unable to load the class',
    },
    'classDetail.classAverage': {
      AppLocale.fr: 'Moyenne classe',
      AppLocale.en: 'Class average',
    },
    'classDetail.best': {AppLocale.fr: 'Meilleur', AppLocale.en: 'Top'},
    'classDetail.worst': {AppLocale.fr: 'Plus faible', AppLocale.en: 'Lowest'},
    'classDetail.distribution': {
      AppLocale.fr: 'Répartition des moyennes',
      AppLocale.en: 'Grade distribution',
    },
    'classDetail.enterGrades': {
      AppLocale.fr: 'Saisir les notes',
      AppLocale.en: 'Enter grades',
    },
    'classDetail.addStudent': {
      AppLocale.fr: '+ Ajouter un élève',
      AppLocale.en: '+ Add a student',
    },
    'classDetail.students': {AppLocale.fr: 'Élèves', AppLocale.en: 'Students'},
    'classDetail.searchHint': {
      AppLocale.fr: 'Rechercher un élève...',
      AppLocale.en: 'Search a student...',
    },
    'classDetail.noResults': {
      AppLocale.fr: 'Aucun élève ne correspond à la recherche',
      AppLocale.en: 'No student matches your search',
    },
    'classDetail.addStudentSheetTitle': {
      AppLocale.fr: 'Ajouter un élève',
      AppLocale.en: 'Add a student',
    },
    'classDetail.firstName': {
      AppLocale.fr: 'Prénom',
      AppLocale.en: 'First name',
    },
    'classDetail.lastName': {AppLocale.fr: 'Nom', AppLocale.en: 'Last name'},
    'classDetail.parentName': {
      AppLocale.fr: 'Nom du parent',
      AppLocale.en: 'Parent name',
    },
    'classDetail.parentPhone': {
      AppLocale.fr: 'Téléphone parent',
      AppLocale.en: 'Parent phone',
    },
    'classDetail.add': {AppLocale.fr: 'Ajouter', AppLocale.en: 'Add'},
    'classDetail.addStudentError': {
      AppLocale.fr: "Impossible d'ajouter l'élève",
      AppLocale.en: 'Unable to add the student',
    },
    'classDetail.studentRequiredFields': {
      AppLocale.fr: 'Prénom, nom et téléphone du parent requis',
      AppLocale.en: 'First name, last name and parent phone are required',
    },
    'classDetail.editSheetTitle': {
      AppLocale.fr: 'Modifier la classe',
      AppLocale.en: 'Edit class',
    },
    'classDetail.editError': {
      AppLocale.fr: 'Impossible de modifier la classe',
      AppLocale.en: 'Unable to update the class',
    },
    'classDetail.deleteClass': {
      AppLocale.fr: 'Supprimer la classe',
      AppLocale.en: 'Delete class',
    },
    'classDetail.deleteConfirmTitle': {
      AppLocale.fr: 'Supprimer cette classe ?',
      AppLocale.en: 'Delete this class?',
    },
    'classDetail.deleteConfirmMessage': {
      AppLocale.fr:
          'La classe sera retirée de vos listes. Les élèves et notes restent conservés.',
      AppLocale.en:
          'The class will be removed from your lists. Students and grades are kept.',
    },
    'classDetail.deleteError': {
      AppLocale.fr: 'Impossible de supprimer la classe',
      AppLocale.en: 'Unable to delete the class',
    },
    'common.cancel': {AppLocale.fr: 'Annuler', AppLocale.en: 'Cancel'},
    'common.close': {AppLocale.fr: 'Fermer', AppLocale.en: 'Close'},
    'app.releaseExpiredTitle': {
      AppLocale.fr: 'Version de test expirée',
      AppLocale.en: 'Test version expired',
    },
    'app.releaseExpiredMessage': {
      AppLocale.fr:
          'Cette version de test de Jàngalekat n\'est plus disponible. Contactez l\'équipe pour obtenir la dernière version.',
      AppLocale.en:
          'This test version of Jàngalekat is no longer available. Contact the team to get the latest version.',
    },
    'common.delete': {AppLocale.fr: 'Supprimer', AppLocale.en: 'Delete'},

    // Fiche eleve
    'student.title': {
      AppLocale.fr: 'Fiche élève',
      AppLocale.en: 'Student profile',
    },
    'student.generalAverage': {
      AppLocale.fr: 'moyenne générale',
      AppLocale.en: 'overall average',
    },
    'student.belowThreshold': {
      AppLocale.fr: 'Sous le seuil — alerte recommandée',
      AppLocale.en: 'Below threshold — alert recommended',
    },
    'student.parentContact': {
      AppLocale.fr: 'Contact parent',
      AppLocale.en: 'Parent contact',
    },
    'student.call': {AppLocale.fr: 'Appeler', AppLocale.en: 'Call'},
    'student.notesTitle': {AppLocale.fr: 'Notes', AppLocale.en: 'Grades'},
    'student.noNotes': {
      AppLocale.fr: 'Aucune note saisie pour cette période',
      AppLocale.en: 'No grades entered for this period',
    },
    'student.quickMessage': {
      AppLocale.fr: 'Message rapide',
      AppLocale.en: 'Quick message',
    },
    'student.congratulate': {
      AppLocale.fr: 'Féliciter',
      AppLocale.en: 'Congratulate',
    },
    'student.summon': {AppLocale.fr: 'Convoquer', AppLocale.en: 'Summon'},
    'student.alert': {AppLocale.fr: 'Alerter', AppLocale.en: 'Alert'},
    'student.editSheetTitle': {
      AppLocale.fr: 'Modifier les informations',
      AppLocale.en: 'Edit information',
    },
    'student.save': {AppLocale.fr: 'Enregistrer', AppLocale.en: 'Save'},
    'student.editError': {
      AppLocale.fr: "Impossible de modifier l'élève",
      AppLocale.en: 'Unable to update the student',
    },
    'student.deleteConfirmTitle': {
      AppLocale.fr: 'Supprimer cet élève ?',
      AppLocale.en: 'Delete this student?',
    },
    'student.deleteConfirmMessage': {
      AppLocale.fr: 'Cette action est définitive.',
      AppLocale.en: 'This action cannot be undone.',
    },
    'student.deleteError': {
      AppLocale.fr: "Impossible de supprimer l'élève",
      AppLocale.en: 'Unable to delete the student',
    },
    'student.callError': {
      AppLocale.fr: "Aucune application d'appel disponible sur cet appareil",
      AppLocale.en: 'No calling app available on this device',
    },
    'student.callInvalidNumber': {
      AppLocale.fr: 'Numéro de téléphone du parent invalide',
      AppLocale.en: 'Invalid parent phone number',
    },
    'student.bulletin': {AppLocale.fr: 'Bulletin', AppLocale.en: 'Report card'},

    // Bulletin de notes (le contenu du PDF lui-meme reste toujours en
    // francais — document officiel remis aux parents — seul le chrome de
    // l'ecran suit la langue de l'interface)
    'bulletin.title': {
      AppLocale.fr: 'Bulletin de notes',
      AppLocale.en: 'Report card',
    },
    'bulletin.loadError': {
      AppLocale.fr: 'Impossible de préparer le bulletin',
      AppLocale.en: 'Unable to prepare the report card',
    },
    'bulletin.pdfGenError': {
      AppLocale.fr: 'Impossible de générer le PDF.',
      AppLocale.en: 'Unable to generate the PDF.',
    },
    'bulletin.pdfShareError': {
      AppLocale.fr: 'Impossible de partager le PDF.',
      AppLocale.en: 'Unable to share the PDF.',
    },
    'bulletin.download': {
      AppLocale.fr: 'Télécharger PDF',
      AppLocale.en: 'Download PDF',
    },
    'bulletin.share': {AppLocale.fr: 'Partager PDF', AppLocale.en: 'Share PDF'},

    // Saisie des notes
    'grades.title': {
      AppLocale.fr: 'Saisir les notes',
      AppLocale.en: 'Enter grades',
    },
    'grades.loadError': {
      AppLocale.fr: 'Impossible de charger les notes',
      AppLocale.en: 'Unable to load grades',
    },
    'grades.updateMatieresError': {
      AppLocale.fr: 'Échec de la mise à jour des matières',
      AppLocale.en: 'Unable to update subjects',
    },
    'grades.saveError': {
      AppLocale.fr: "Échec de l'enregistrement",
      AppLocale.en: 'Unable to save',
    },
    'grades.subject': {AppLocale.fr: 'Matière', AppLocale.en: 'Subject'},
    'grades.manageTitlePrefix': {
      AppLocale.fr: 'Matières',
      AppLocale.en: 'Subjects',
    },
    'grades.noSubjects': {
      AppLocale.fr: 'Aucune matière — ajoutez-en une ci-dessous',
      AppLocale.en: 'No subjects yet — add one below',
    },
    'grades.newSubject': {
      AppLocale.fr: 'Nouvelle matière',
      AppLocale.en: 'New subject',
    },
    'grades.coeffLabel': {AppLocale.fr: 'Coeff', AppLocale.en: 'Coeff'},
    'grades.noSubjectsForClass': {
      AppLocale.fr:
          'Aucune matière pour cette classe — appuyez sur "Gérer" pour en ajouter.',
      AppLocale.en: 'No subjects for this class yet — tap "Manage" to add one.',
    },
    'grades.coefficient': {
      AppLocale.fr: 'Coefficient',
      AppLocale.en: 'Coefficient',
    },
    'grades.average': {AppLocale.fr: 'Moyenne : ', AppLocale.en: 'Average: '},
    'grades.classAverage': {
      AppLocale.fr: 'Moyenne classe · ',
      AppLocale.en: 'Class average · ',
    },
    'grades.saving': {
      AppLocale.fr: 'Enregistrement...',
      AppLocale.en: 'Saving...',
    },
    'grades.saved': {
      AppLocale.fr: 'Notes enregistrées ✓',
      AppLocale.en: 'Grades saved ✓',
    },
    'grades.save': {AppLocale.fr: 'Enregistrer', AppLocale.en: 'Save'},

    // Envoi WhatsApp (chrome de l'ecran uniquement — le contenu du message
    // envoye aux parents reste en francais, langue des destinataires)
    'whatsapp.title': {
      AppLocale.fr: 'Envoyer aux parents',
      AppLocale.en: 'Send to parents',
    },
    'whatsapp.individual': {
      AppLocale.fr: 'Individuel',
      AppLocale.en: 'Individual',
    },
    'whatsapp.group': {AppLocale.fr: 'Groupé', AppLocale.en: 'Group'},
    'whatsapp.messageType': {
      AppLocale.fr: 'Message type',
      AppLocale.en: 'Message type',
    },
    'whatsapp.templateCongrats': {
      AppLocale.fr: 'Félicitations',
      AppLocale.en: 'Congratulations',
    },
    'whatsapp.templateSummon': {
      AppLocale.fr: 'Convocation',
      AppLocale.en: 'Summon',
    },
    'whatsapp.templateAlert': {
      AppLocale.fr: 'Alerte baisse',
      AppLocale.en: 'Grade alert',
    },
    'whatsapp.templateCustom': {
      AppLocale.fr: 'Personnalisé',
      AppLocale.en: 'Custom',
    },
    'whatsapp.preview': {
      AppLocale.fr: 'Aperçu WhatsApp',
      AppLocale.en: 'WhatsApp preview',
    },
    'whatsapp.recipients': {
      AppLocale.fr: 'Destinataires',
      AppLocale.en: 'Recipients',
    },
    'whatsapp.selected': {
      AppLocale.fr: 'sélectionnés',
      AppLocale.en: 'selected',
    },
    'whatsapp.sending': {AppLocale.fr: 'Envoi...', AppLocale.en: 'Sending...'},
    'whatsapp.sent': {AppLocale.fr: 'Envoyé', AppLocale.en: 'Sent'},
    'whatsapp.sendButton': {
      AppLocale.fr: 'Envoyer via WhatsApp',
      AppLocale.en: 'Send via WhatsApp',
    },
    'whatsapp.messagesSuffix': {
      AppLocale.fr: 'messages',
      AppLocale.en: 'messages',
    },
    'whatsapp.next': {AppLocale.fr: 'Suivant', AppLocale.en: 'Next'},
    'whatsapp.openError': {
      AppLocale.fr: "Impossible d'ouvrir WhatsApp",
      AppLocale.en: 'Unable to open WhatsApp',
    },
    'whatsapp.skip': {
      AppLocale.fr: 'Passer ce destinataire',
      AppLocale.en: 'Skip this recipient',
    },

    // Historique
    'history.title': {AppLocale.fr: 'Historique', AppLocale.en: 'History'},
    'history.subtitle': {
      AppLocale.fr: 'Journal des actions',
      AppLocale.en: 'Activity log',
    },
    'history.pendingSync': {
      AppLocale.fr: 'Modifications en attente de synchronisation',
      AppLocale.en: 'Changes pending sync',
    },
    'history.synced': {
      AppLocale.fr: 'Toutes les données sont synchronisées',
      AppLocale.en: 'All data is synced',
    },
    'history.reconnect': {
      AppLocale.fr: 'Se reconnecter',
      AppLocale.en: 'Reconnect',
    },
    'history.view': {AppLocale.fr: 'Voir', AppLocale.en: 'View'},
    'history.loadError': {
      AppLocale.fr: "Impossible de charger l'historique",
      AppLocale.en: 'Unable to load history',
    },
    'history.noActivity': {
      AppLocale.fr: 'Aucune activité pour le moment',
      AppLocale.en: 'No activity yet',
    },
    'history.sendFailed': {
      AppLocale.fr: "Échec de l'envoi",
      AppLocale.en: 'Send failed',
    },
    'history.sentTo': {AppLocale.fr: 'Envoyé à', AppLocale.en: 'Sent to'},
    'history.typeAlerte': {AppLocale.fr: 'Alerte', AppLocale.en: 'Alert'},
    'history.typeGroupe': {
      AppLocale.fr: 'Message groupé',
      AppLocale.en: 'Group message',
    },
    'history.typeMessage': {AppLocale.fr: 'Message', AppLocale.en: 'Message'},
    'history.detailStudent': {AppLocale.fr: 'Élève', AppLocale.en: 'Student'},
    'history.detailClass': {AppLocale.fr: 'Classe', AppLocale.en: 'Class'},
    'history.detailPhone': {AppLocale.fr: 'Téléphone', AppLocale.en: 'Phone'},
    'history.detailDate': {AppLocale.fr: 'Date', AppLocale.en: 'Date'},
    'history.detailStatus': {AppLocale.fr: 'Statut', AppLocale.en: 'Status'},
    'history.detailContent': {
      AppLocale.fr: 'Message envoyé',
      AppLocale.en: 'Message sent',
    },
    'history.statusSent': {AppLocale.fr: 'Envoyé', AppLocale.en: 'Sent'},
    'history.statusFailed': {AppLocale.fr: 'Échec', AppLocale.en: 'Failed'},
    'history.deleteMessage': {
      AppLocale.fr: 'Supprimer ce message',
      AppLocale.en: 'Delete this message',
    },
    'history.deleteConfirmTitle': {
      AppLocale.fr: 'Supprimer ce message ?',
      AppLocale.en: 'Delete this message?',
    },
    'history.deleteConfirmMessage': {
      AppLocale.fr: "Il sera retiré de l'historique.",
      AppLocale.en: 'It will be removed from the history.',
    },
    'history.deleteError': {
      AppLocale.fr: 'Impossible de supprimer le message',
      AppLocale.en: 'Unable to delete the message',
    },

    // Fiches de cours (IA)
    'fiche.tabTitle': {
      AppLocale.fr: 'Fiches de cours',
      AppLocale.en: 'Lesson plans',
    },
    'fiche.tabSubtitle': {
      AppLocale.fr: 'Générées par IA',
      AppLocale.en: 'Generated by AI',
    },
    'fiche.formTitle': {
      AppLocale.fr: 'Fiche de cours',
      AppLocale.en: 'Lesson plan',
    },
    'fiche.level': {
      AppLocale.fr: 'Niveau / classe',
      AppLocale.en: 'Level / class',
    },
    'fiche.themeLabel': {
      AppLocale.fr: 'Thème du cours',
      AppLocale.en: 'Lesson topic',
    },
    'fiche.objectivesLabel': {
      AppLocale.fr: 'Objectifs pédagogiques (optionnel)',
      AppLocale.en: 'Learning objectives (optional)',
    },
    'fiche.durationLabel': {
      AppLocale.fr: 'Durée prévue (optionnel)',
      AppLocale.en: 'Planned duration (optional)',
    },
    'fiche.languageLabel': {
      AppLocale.fr: 'Langue de la fiche',
      AppLocale.en: 'Lesson plan language',
    },
    'fiche.generating': {
      AppLocale.fr: 'Génération en cours...',
      AppLocale.en: 'Generating...',
    },
    'fiche.generate': {AppLocale.fr: 'Générer', AppLocale.en: 'Generate'},
    'fiche.requiredFields': {
      AppLocale.fr: 'Matière, niveau et thème sont obligatoires.',
      AppLocale.en: 'Subject, level and topic are required.',
    },
    'fiche.genericError': {
      AppLocale.fr: 'Erreur inattendue pendant la génération.',
      AppLocale.en: 'Unexpected error during generation.',
    },
    'fiche.sectionResume': {AppLocale.fr: 'Résumé', AppLocale.en: 'Summary'},
    'fiche.sectionObjectifs': {
      AppLocale.fr: 'Objectifs',
      AppLocale.en: 'Objectives',
    },
    'fiche.sectionPrerequis': {
      AppLocale.fr: 'Prérequis',
      AppLocale.en: 'Prerequisites',
    },
    'fiche.sectionDeroulement': {
      AppLocale.fr: 'Déroulement',
      AppLocale.en: 'Lesson flow',
    },
    'fiche.sectionActivites': {
      AppLocale.fr: 'Activités',
      AppLocale.en: 'Activities',
    },
    'fiche.sectionEvaluation': {
      AppLocale.fr: 'Évaluation',
      AppLocale.en: 'Assessment',
    },
    'fiche.download': {
      AppLocale.fr: 'Télécharger PDF',
      AppLocale.en: 'Download PDF',
    },
    'fiche.share': {AppLocale.fr: 'Partager PDF', AppLocale.en: 'Share PDF'},
    'fiche.saving': {
      AppLocale.fr: 'Enregistrement...',
      AppLocale.en: 'Saving...',
    },
    'fiche.saved': {
      AppLocale.fr: 'Fiche enregistrée ✓',
      AppLocale.en: 'Lesson plan saved ✓',
    },
    'fiche.save': {AppLocale.fr: 'Enregistrer', AppLocale.en: 'Save'},
    'fiche.saveError': {
      AppLocale.fr: "Impossible d'enregistrer la fiche.",
      AppLocale.en: 'Unable to save the lesson plan.',
    },
    'fiche.pdfGenError': {
      AppLocale.fr: 'Impossible de générer le PDF.',
      AppLocale.en: 'Unable to generate the PDF.',
    },
    'fiche.pdfShareError': {
      AppLocale.fr: 'Impossible de partager le PDF.',
      AppLocale.en: 'Unable to share the PDF.',
    },
    'fiche.historyTitle': {
      AppLocale.fr: 'Fiches enregistrées',
      AppLocale.en: 'Saved lesson plans',
    },
    'fiche.historyLoadError': {
      AppLocale.fr: "Impossible de charger l'historique des fiches",
      AppLocale.en: 'Unable to load lesson plan history',
    },
    'fiche.historyEmpty': {
      AppLocale.fr: 'Aucune fiche enregistrée pour le moment',
      AppLocale.en: 'No saved lesson plans yet',
    },
    'fiche.edit': {AppLocale.fr: 'Modifier', AppLocale.en: 'Edit'},
    'fiche.editSave': {AppLocale.fr: 'Enregistrer', AppLocale.en: 'Save'},
    'fiche.editSaving': {
      AppLocale.fr: 'Enregistrement...',
      AppLocale.en: 'Saving...',
    },
    'fiche.editError': {
      AppLocale.fr: 'Impossible d\'enregistrer les modifications',
      AppLocale.en: 'Unable to save the changes',
    },
    'fiche.deleteConfirmTitle': {
      AppLocale.fr: 'Supprimer cette fiche ?',
      AppLocale.en: 'Delete this lesson plan?',
    },
    'fiche.deleteConfirmMessage': {
      AppLocale.fr: 'Cette action est définitive.',
      AppLocale.en: 'This action cannot be undone.',
    },
    'fiche.deleteError': {
      AppLocale.fr: 'Impossible de supprimer la fiche',
      AppLocale.en: 'Unable to delete the lesson plan',
    },

    // Inscription
    'register.title': {
      AppLocale.fr: 'Créer un compte',
      AppLocale.en: 'Create an account',
    },
    'register.fullName': {
      AppLocale.fr: 'Nom complet',
      AppLocale.en: 'Full name',
    },
    'register.school': {
      AppLocale.fr: 'École (optionnel)',
      AppLocale.en: 'School (optional)',
    },
    'register.email': {AppLocale.fr: 'Email', AppLocale.en: 'Email'},
    'register.ia': {
      AppLocale.fr: 'IA (optionnel)',
      AppLocale.en: 'IA (optional)',
    },
    'register.ief': {
      AppLocale.fr: 'IEF (optionnel)',
      AppLocale.en: 'IEF (optional)',
    },
    'register.phone': {
      AppLocale.fr: 'Téléphone (optionnel)',
      AppLocale.en: 'Phone number (optional)',
    },
    'register.pinHint': {
      AppLocale.fr: '6 chiffres minimum',
      AppLocale.en: 'At least 6 digits',
    },
    'register.creating': {
      AppLocale.fr: 'Création...',
      AppLocale.en: 'Creating...',
    },
    'register.createButton': {
      AppLocale.fr: 'Créer mon compte',
      AppLocale.en: 'Create my account',
    },
    'register.error': {
      AppLocale.fr: 'Impossible de créer le compte',
      AppLocale.en: 'Unable to create the account',
    },
    'register.fullNameRequired': {
      AppLocale.fr: 'Le nom complet est requis',
      AppLocale.en: 'Full name is required',
    },
    'register.emailRequired': {
      AppLocale.fr: 'Adresse email requise',
      AppLocale.en: 'Email address is required',
    },
    'register.pinRequired': {
      AppLocale.fr: 'Code PIN requis',
      AppLocale.en: 'PIN code is required',
    },
    'register.pinTooShort': {
      AppLocale.fr: 'Le code PIN doit contenir au moins 6 chiffres',
      AppLocale.en: 'The PIN code must be at least 6 digits',
    },
    'register.emailInvalid': {
      AppLocale.fr: 'Adresse email invalide',
      AppLocale.en: 'Invalid email address',
    },
  };

  static String t(AppLocale locale, String key) {
    final entry = _dict[key];
    if (entry == null) return key;
    return entry[locale] ?? entry[AppLocale.fr] ?? key;
  }
}
