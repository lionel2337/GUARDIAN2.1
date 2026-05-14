// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Guardians AI';

  @override
  String get welcome => 'Bienvenue sur Guardians AI';

  @override
  String get tagline => 'Protéger ce qui compte le plus';

  @override
  String get onboarding_feature1_title => 'Protection en Temps Réel';

  @override
  String get onboarding_feature1_desc =>
      'Suivez vos proches en temps réel, surveillez les trajets avec détection de déviation, et visualisez les zones à risque sur la carte.';

  @override
  String get onboarding_feature2_title => 'Détection par IA';

  @override
  String get onboarding_feature2_desc =>
      'Notre IA détecte automatiquement les chutes, les bagarres et les cris. Tout le traitement se fait sur votre appareil — sans internet.';

  @override
  String get onboarding_feature3_title => 'Sécurité Communautaire';

  @override
  String get onboarding_feature3_desc =>
      'Signalez les incidents pour prévenir les autres en temps réel. Ensemble, nous construisons des communautés plus sûres à travers le Cameroun.';

  @override
  String get permissionsTitle => 'Autorisations Requises';

  @override
  String get permissionsDesc =>
      'Guardians AI a besoin des autorisations suivantes pour vous protéger :';

  @override
  String get grantPermissions => 'Accorder les autorisations';

  @override
  String get permissionsGranted => 'Autorisations accordées ✓';

  @override
  String get getStarted => 'Commencer';

  @override
  String get continueWithoutAccount => 'Continuer sans compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'Créer un compte';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get phone => 'Numéro de téléphone';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get doNotHaveAccount => 'Pas de compte ? S\'inscrire';

  @override
  String get map => 'Carte';

  @override
  String get journey => 'Trajet';

  @override
  String get contacts => 'Contacts';

  @override
  String get history => 'Historique';

  @override
  String get settings => 'Paramètres';

  @override
  String get sosAlert => 'Alerte SOS';

  @override
  String get sosTriggered => 'Alerte SOS déclenchée !';

  @override
  String get imOkay => 'Je vais bien';

  @override
  String get sendHelp => 'Envoyer de l\'aide';

  @override
  String get fallDetected => 'Chute Détectée';

  @override
  String get screamDetected => 'Cri Détecté';

  @override
  String get routeDeviation => 'Déviation de Route';

  @override
  String get planYourJourney => 'Planifiez Votre Trajet';

  @override
  String get startingPoint => 'Point de départ';

  @override
  String get destination => 'Destination';

  @override
  String get findSafeRoutes => 'Trouver des itinéraires sûrs';

  @override
  String get startMonitoredJourney => 'Démarrer le trajet surveillé';

  @override
  String get activeJourney => 'Trajet Actif';

  @override
  String get endJourney => 'Terminer le trajet';

  @override
  String get emergencyContacts => 'Contacts d\'Urgence';

  @override
  String get addContact => 'Ajouter un contact';

  @override
  String get noContacts => 'Aucun contact d\'urgence';

  @override
  String get noContactsDesc =>
      'Ajoutez des contacts qui seront notifiés en cas d\'urgence';

  @override
  String get alertHistory => 'Historique des Alertes';

  @override
  String get noAlerts => 'Aucune alerte';

  @override
  String get noAlertsDesc =>
      'Vous êtes en sécurité — aucune alerte enregistrée';

  @override
  String get offlineMode => 'Mode Hors Ligne';

  @override
  String get aiStillActive => 'IA toujours active ✓';

  @override
  String get traceurDevices => 'Traceurs GPS';

  @override
  String get pairNewTraceur => 'Associer un nouveau traceur';

  @override
  String get pairingCode => 'Entrez le code d\'appairage';

  @override
  String get pairDevice => 'Associer l\'appareil';

  @override
  String get pairedSuccessfully => 'Traceur associé avec succès !';

  @override
  String get deviceNotFound => 'Appareil non trouvé. Vérifiez votre code.';

  @override
  String get reportIncident => 'Signaler un Incident';

  @override
  String get reportVisible =>
      'Votre signalement sera visible sur la carte pendant 2 heures';

  @override
  String get submitReport => 'Envoyer le signalement';

  @override
  String get reportSubmitted => 'Signalement envoyé — visible pendant 2 heures';

  @override
  String get profile => 'Profil';

  @override
  String get aiDetection => 'Détection IA';

  @override
  String get movementDetection => 'Détection de mouvement';

  @override
  String get movementDetectionDesc =>
      'Détecter les chutes, bagarres et courses d\'urgence';

  @override
  String get audioDetection => 'Détection audio';

  @override
  String get audioDetectionDesc => 'Détecter les cris et mots-clés d\'urgence';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get language => 'Langue';

  @override
  String get privacy => 'Confidentialité et Sécurité';

  @override
  String get camouflageMode => 'Mode Camouflage';

  @override
  String get camouflageModeDesc =>
      'Cacher l\'application derrière une calculatrice';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get pendingSync => 'Synchronisation en attente';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get aiTestAndDiagnostics => 'Test IA & Diagnostics';

  @override
  String get testAiModels => 'Test Modèles IA';

  @override
  String get verifyAudioMovementModels =>
      'Vérifier les modèles audio et mouvement';

  @override
  String get showDiagnostics => 'Afficher Diagnostics';

  @override
  String get displayRealTimeSensorStatus =>
      'Afficher l\'état des capteurs en temps réel';

  @override
  String get receiveAlertsAndReminders => 'Recevoir alertes et rappels';

  @override
  String get managePairedGpsTraceurs => 'Gérer les traceurs GPS appairés';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';

  @override
  String get anonymous => 'Anonyme';

  @override
  String get noEmail => 'Pas d\'email';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get currentLocation => 'Position Actuelle';

  @override
  String alertingContactsInSeconds(int seconds) {
    return 'Alerte aux contacts dans $seconds secondes...';
  }
}
