import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Guardians AI'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Guardians AI'**
  String get welcome;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Protecting what matters most'**
  String get tagline;

  /// No description provided for @onboarding_feature1_title.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Protection'**
  String get onboarding_feature1_title;

  /// No description provided for @onboarding_feature1_desc.
  ///
  /// In en, this message translates to:
  /// **'Track family members in real time, monitor journeys with deviation detection, and view risk zones on the map.'**
  String get onboarding_feature1_desc;

  /// No description provided for @onboarding_feature2_title.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Detection'**
  String get onboarding_feature2_title;

  /// No description provided for @onboarding_feature2_desc.
  ///
  /// In en, this message translates to:
  /// **'Our AI detects falls, fights, and screams automatically. All processing happens on your device — no internet needed.'**
  String get onboarding_feature2_desc;

  /// No description provided for @onboarding_feature3_title.
  ///
  /// In en, this message translates to:
  /// **'Community Safety'**
  String get onboarding_feature3_title;

  /// No description provided for @onboarding_feature3_desc.
  ///
  /// In en, this message translates to:
  /// **'Report incidents to warn others in real time. Together, we build safer communities across Cameroon.'**
  String get onboarding_feature3_desc;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsTitle;

  /// No description provided for @permissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Guardians AI needs the following permissions to protect you:'**
  String get permissionsDesc;

  /// No description provided for @grantPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant Permissions'**
  String get grantPermissions;

  /// No description provided for @permissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'Permissions Granted ✓'**
  String get permissionsGranted;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue Without Account'**
  String get continueWithoutAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// No description provided for @doNotHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get doNotHaveAccount;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @journey.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journey;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sosAlert.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert'**
  String get sosAlert;

  /// No description provided for @sosTriggered.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert triggered!'**
  String get sosTriggered;

  /// No description provided for @imOkay.
  ///
  /// In en, this message translates to:
  /// **'I\'m OK'**
  String get imOkay;

  /// No description provided for @sendHelp.
  ///
  /// In en, this message translates to:
  /// **'Send Help'**
  String get sendHelp;

  /// No description provided for @fallDetected.
  ///
  /// In en, this message translates to:
  /// **'Fall Detected'**
  String get fallDetected;

  /// No description provided for @screamDetected.
  ///
  /// In en, this message translates to:
  /// **'Scream Detected'**
  String get screamDetected;

  /// No description provided for @routeDeviation.
  ///
  /// In en, this message translates to:
  /// **'Route Deviation'**
  String get routeDeviation;

  /// No description provided for @planYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Journey'**
  String get planYourJourney;

  /// No description provided for @startingPoint.
  ///
  /// In en, this message translates to:
  /// **'Starting point'**
  String get startingPoint;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @findSafeRoutes.
  ///
  /// In en, this message translates to:
  /// **'Find Safe Routes'**
  String get findSafeRoutes;

  /// No description provided for @startMonitoredJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Monitored Journey'**
  String get startMonitoredJourney;

  /// No description provided for @activeJourney.
  ///
  /// In en, this message translates to:
  /// **'Active Journey'**
  String get activeJourney;

  /// No description provided for @endJourney.
  ///
  /// In en, this message translates to:
  /// **'End Journey'**
  String get endJourney;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @noContacts.
  ///
  /// In en, this message translates to:
  /// **'No Emergency Contacts'**
  String get noContacts;

  /// No description provided for @noContactsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add contacts who will be notified during emergencies'**
  String get noContactsDesc;

  /// No description provided for @alertHistory.
  ///
  /// In en, this message translates to:
  /// **'Alert History'**
  String get alertHistory;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No Alerts Yet'**
  String get noAlerts;

  /// No description provided for @noAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'re safe — no alerts recorded'**
  String get noAlertsDesc;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @aiStillActive.
  ///
  /// In en, this message translates to:
  /// **'AI still active ✓'**
  String get aiStillActive;

  /// No description provided for @traceurDevices.
  ///
  /// In en, this message translates to:
  /// **'Traceur Devices'**
  String get traceurDevices;

  /// No description provided for @pairNewTraceur.
  ///
  /// In en, this message translates to:
  /// **'Pair New Traceur'**
  String get pairNewTraceur;

  /// No description provided for @pairingCode.
  ///
  /// In en, this message translates to:
  /// **'Enter pairing code'**
  String get pairingCode;

  /// No description provided for @pairDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair Device'**
  String get pairDevice;

  /// No description provided for @pairedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Traceur paired successfully!'**
  String get pairedSuccessfully;

  /// No description provided for @deviceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Device not found. Check your pairing code.'**
  String get deviceNotFound;

  /// No description provided for @reportIncident.
  ///
  /// In en, this message translates to:
  /// **'Report an Incident'**
  String get reportIncident;

  /// No description provided for @reportVisible.
  ///
  /// In en, this message translates to:
  /// **'Your report will appear on the map for 2 hours'**
  String get reportVisible;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted — visible for 2 hours'**
  String get reportSubmitted;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @aiDetection.
  ///
  /// In en, this message translates to:
  /// **'AI Detection'**
  String get aiDetection;

  /// No description provided for @movementDetection.
  ///
  /// In en, this message translates to:
  /// **'Movement Detection'**
  String get movementDetection;

  /// No description provided for @movementDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Detect falls, fights, and emergency running'**
  String get movementDetectionDesc;

  /// No description provided for @audioDetection.
  ///
  /// In en, this message translates to:
  /// **'Audio Detection'**
  String get audioDetection;

  /// No description provided for @audioDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Detect screams and emergency keywords'**
  String get audioDetectionDesc;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Safety'**
  String get privacy;

  /// No description provided for @camouflageMode.
  ///
  /// In en, this message translates to:
  /// **'Camouflage Mode'**
  String get camouflageMode;

  /// No description provided for @camouflageModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide the app behind a calculator interface'**
  String get camouflageModeDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get pendingSync;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
