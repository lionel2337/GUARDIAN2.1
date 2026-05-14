/// Root widget for Guardians AI.
///
/// Sets up theming, routing (GoRouter), and localisation delegates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/ai_test_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journey_planner_screen.dart';
import 'screens/monitored_journey_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/add_contact_screen.dart';
import 'screens/alert_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/traceur_pairing_screen.dart';
import 'utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/journey-planner',
      builder: (_, __) => const JourneyPlannerScreen(),
    ),
    GoRoute(
      path: '/journey-active',
      builder: (_, __) => const MonitoredJourneyScreen(),
    ),
    GoRoute(path: '/contacts', builder: (_, __) => const ContactsScreen()),
    GoRoute(
      path: '/contacts/add',
      builder: (_, __) => const AddContactScreen(),
    ),
    GoRoute(
      path: '/alert-history',
      builder: (_, __) => const AlertHistoryScreen(),
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(
      path: '/traceur-pairing',
      builder: (_, __) => const TraceurPairingScreen(),
    ),
    GoRoute(
      path: '/ai-test',
      builder: (_, __) => const AiTestScreen(),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────

ThemeData _buildTheme() {
  final base = ThemeData.dark();
  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingM,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingXL,
          vertical: AppDimens.paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    dividerColor: AppColors.divider,
    splashColor: AppColors.accent.withOpacity(0.1),
    highlightColor: AppColors.accent.withOpacity(0.05),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// App Widget
// ─────────────────────────────────────────────────────────────────────────────

class GuardiansApp extends ConsumerWidget {
  const GuardiansApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Guardians AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
      ],
    );
  }
}
