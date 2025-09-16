# Human Rhythms (MVP)

A Flutter app that lets people track routines as **bubbles**, reflect in a **diary-like** way, and see **simple insights** over a week. Private-first, with optional self-awarded badges.

## ✨ MVP Features
- Bubble diary for routines (done / skipped / partial, intensity, duration).
- Daily outcomes (mood, energy, sleep quality, pain, focus).
- Notes & quick tags per day.
- Weekly summary with simple insights (non-judgmental).
- Self-awarded badges (win, consistency, insight).
- Privacy-first data model (per-user; no public sharing yet).

## 🧱 Tech Stack
- Flutter (mobile-first; web later)
- Firebase: Auth, Firestore (offline enabled)
- State mgmt: Riverpod
- Routing: go_router

## 🚀 Getting Started

1. **Install Flutter** and set up iOS/Android toolchains.
2. **Clone this repo**, then run:
   ```bash
   flutter pub get
   ```
3. **Create Firebase project**:
   - Enable **Authentication** (Email/Password + Google).
   - Enable **Cloud Firestore** (in *production* mode if you have rules set).
   - Add iOS and Android apps in Firebase.
   - Download config files and place them at:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
   - Run:
     ```bash
     flutter pub add firebase_core firebase_auth cloud_firestore firebase_analytics google_sign_in
     dart run flutterfire_cli flutterfire configure
     ```
4. **Run the app**:
   ```bash
   flutter run
   ```

## 📁 Structure
```
lib/
  app.dart
  main.dart
  core/
    router.dart
    theme.dart
    utils/date.dart
    widgets/app_scaffold.dart
  data/
    models/
      enums.dart
      routine.dart
      entry.dart
      outcome.dart
      badge.dart
    services/
      firebase_service.dart
    repositories/
      routines_repo.dart
      entries_repo.dart
      outcomes_repo.dart
  features/
    auth/
      sign_in_screen.dart
    diary/
      diary_screen.dart
      bubble.dart
      edit_entry_sheet.dart
    routines/
      routine_list_screen.dart   (placeholder)
      routine_editor.dart        (placeholder)
    summary/
      weekly_summary_screen.dart
    badges/
      badges_sheet.dart          (placeholder)
    settings/
      settings_screen.dart       (placeholder)
  providers/
    global.dart
```

## 🔐 Security
See `firestore.rules` for privacy-first rules. In MVP, all user data is private to the owner.

## 🧪 Roadmap Next
- Wire Firestore repo calls into UI (save Entry/Outcome).
- Outcome chip on diary header (🙂😐🙁) → save to `outcomes`.
- Routine editor + reminder scaffolding.
- Weekly insights aggregation (client-side MVP; server later).
- Apple Health / Google Fit hooks (Phase 2).
- AI insights & community sharing (Phase 2+).

## 🧰 Scripts
- `tool/seed_dummy.dart` (optional) can seed local data for UI testing.

## 🧑‍⚖️ License
MIT

## Firebase Quickstart
- Create project → add iOS & Android apps.
- Place config files (`google-services.json`, `GoogleService-Info.plist`).
- Run `flutterfire configure`.
- Launch with `flutter run`.

## Notes on Sign-in (MVP)
- The current sign-in button uses anonymous sign-in as a safe default until Google Sign-In is configured on iOS/Android.
- Once your Google Sign-In is set up, replace `signInWithGoogle()` in `lib/features/auth/auth_controller.dart` with a real Google flow.
