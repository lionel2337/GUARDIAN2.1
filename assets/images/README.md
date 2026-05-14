# Guardians AI — Asset Placeholders

This directory contains placeholder files for images used in the application.

## Required images:
- `logo.png` — App logo (512×512 PNG with transparency)
- `onboarding_*.png` — Onboarding illustrations (optional)
- `shield_icon.svg` — Shield icon for branding

## Generating the app icon:
When Flutter is installed, add `flutter_launcher_icons` to dev_dependencies
and run:
```bash
flutter pub run flutter_launcher_icons
```

## Generating the splash screen:
Add `flutter_native_splash` to dev_dependencies and run:
```bash
flutter pub run flutter_native_splash:create
```
