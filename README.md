# Human Rhythms

Track your daily routines. Discover what truly works for you.

## Setup Before Building

### 1. Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project (or open existing)
3. Add an **Android app** with package name: `com.humanrhythms.app`
4. Download `google-services.json` → place it in `android/app/`
5. Enable **Authentication** → Sign-in methods → Google + Anonymous
6. Enable **Cloud Firestore** → Start in production mode
7. Deploy security rules: copy `firestore.rules` content into Firestore Rules tab

### 2. FlutterFire CLI (run once locally or in Codemagic)
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
```
This generates `lib/firebase_options.dart` automatically.

### 3. Update main.dart after running flutterfire configure
Replace `await Firebase.initializeApp();` with:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```
And add the import:
```dart
import 'firebase_options.dart';
```

### 4. Build
```bash
flutter pub get
flutter run   # for local testing
```

## Security Model
- All user data (entries, outcomes, routines) is **private by default**
- Only the authenticated owner can read/write their own data — enforced at Firestore rules level, not just app level
- Routines can optionally be made **public** for the community library
- Diary entries and health outcomes are **never** public — hardcoded in rules
- Anonymous sign-in supported as fallback during testing

## Tech Stack
Flutter · Firebase Auth · Cloud Firestore · Riverpod · go_router

## App Structure
```
lib/
  main.dart               ← Entry point
  app.dart                ← MaterialApp.router setup
  core/
    theme.dart            ← Teal design system
    router.dart           ← go_router with auth guard
    utils/date.dart
    widgets/app_scaffold.dart  ← Bottom nav + logo
  data/
    models/               ← Routine, Entry, Outcome, Badge
    repositories/         ← Firestore CRUD
    services/             ← Firebase instance
  features/
    auth/                 ← Sign-in screen + controller
    diary/                ← Today screen + bubbles + entry sheet
    routines/             ← List + editor
    summary/              ← Weekly insights
    settings/             ← Profile + privacy
  providers/
    global.dart           ← Riverpod providers
```
