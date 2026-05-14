/// Supabase project configuration for Guardians AI.
///
/// Configuration values are read from compile-time constants
/// (--dart-define) with hardcoded fallbacks for development.
///
/// To build with custom values:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
library;

class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL.
  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cgjgpykyibvklblwbwhz.supabase.co',
  );

  /// Anon (public) key — safe to embed in the client app.
  /// In production, pass via --dart-define=SUPABASE_ANON_KEY=...
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnamdweWt5aWJ2a2xibHdid2h6'
        'Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0MTE2MjEsImV4cCI6MjA5MTk4'
        'NzYyMX0.Jwwi1DVvGOy6dibHhfpc9CFcK7uDWq8il--b97i5YjA',
  );

  /// Storage bucket for evidence (audio / screenshots).
  static const String storageBucket = 'evidence';

  /// Realtime channel name used for device position streaming.
  static const String realtimeChannel = 'realtime';

  /// Heartbeat interval for Dead Man Switch (milliseconds).
  static const int heartbeatIntervalMs = 30000;

  /// Dead Man Switch timeout before server-side alert (milliseconds).
  static const int deadManSwitchTimeoutMs = 120000;
}
