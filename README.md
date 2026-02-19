# CarLog

CarLog now supports two runtime modes:

- Local mock mode: no Firebase setup required. This is the default fallback and keeps your demo data active.
- Firebase mode: email/password auth + Cloud Firestore sync.

## Keep Demo Data

The demo dataset is kept in `lib/mock_data.dart` and is still used:

- in guest mode
- when Firebase is not configured
- as first-time seed data for new Firebase users

Do not delete `lib/mock_data.dart` if you need demo recordings.

## Firebase Setup (What To Do)

1. Create a Firebase project in the Firebase Console.
2. In Authentication, enable `Email/Password` sign-in.
3. Create a Firestore database (start in test mode for development).
4. In Firestore Rules, use the rules from `firestore.rules` (user-isolated access by `uid`).
5. Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

6. Configure Firebase for this Flutter app:

```bash
flutterfire configure
```

7. Place platform config files if needed by your setup (for example `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`).
8. Get packages and run:

```bash
flutter pub get
flutter run
```

If Firebase init fails, the app automatically falls back to local mock mode.

## Firestore Data Shape

Data is stored per user under:

- `users/{uid}/vehicles/{vehicleId}`
- `users/{uid}/expenses/{expenseId}`
- `users/{uid}/reminders/{reminderId}`
