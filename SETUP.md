# Athar (أثر) — Setup Guide

## Prerequisites
- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Firebase account
- Android Studio or VS Code

---

## Step 1 — Initialize Flutter Project

The `lib/` source code is ready. You need a Flutter project shell around it.
If you haven't already run `flutter create`, run this **once** from the parent folder:

```bash
cd C:\Users\moh\Documents\flutterproject
flutter create --org com.athar --project-name athar athar_shell
```

Then **copy** the generated `android/`, `ios/`, `web/`, `pubspec.lock` into the
`athar/` directory (or just use `flutter create athar` to overwrite — your `lib/`
files will not be touched if you answer "n" to overwrite prompts).

---

## Step 2 — Install Dependencies

```bash
cd C:\Users\moh\Documents\flutterproject\athar
flutter pub get
```

---

## Step 3 — Configure Firebase

### 3a. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named **athar**
3. Enable **Authentication** → Email/Password
4. Create **Cloud Firestore** database (start in test mode)
5. Enable **Storage**
6. Enable **Cloud Messaging**

### 3b. Register your apps
- Add **Android** app: `com.athar.app`
- Add **iOS** app: `com.athar.app`

### 3c. Run FlutterFire CLI (replaces firebase_options.dart placeholder)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This auto-generates `lib/firebase_options.dart` with your real keys.

---

## Step 4 — Firestore Security Rules

In Firebase Console → Firestore → Rules, paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    match /campaigns/{campaignId} {
      allow read: if true;
      allow create: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'organization';
      allow update, delete: if request.auth != null &&
        resource.data.organizationId == request.auth.uid;
    }
    match /notifications/{notifId} {
      allow read, write: if request.auth != null &&
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
    match /donor_requests/{requestId} {
      allow read: if request.auth != null &&
        (resource.data.donorId == request.auth.uid ||
         resource.data.organizationId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        resource.data.organizationId == request.auth.uid;
    }
    match /sponsorships/{sponsorshipId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## Step 5 — Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /campaigns/{orgId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == orgId;
    }
    match /avatars/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Step 6 — Android Configuration

In `android/app/build.gradle`, ensure:
```gradle
minSdkVersion 21
targetSdkVersion 34
```

In `android/app/src/main/AndroidManifest.xml`, add permissions:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

---

## Step 7 — Run the App

```bash
flutter run
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # AppColors, AppStrings, AppSizes
│   ├── extensions/      # BuildContext extensions
│   ├── router/          # GoRouter setup
│   ├── theme/           # Material 3 light/dark themes
│   └── utils/           # Form validators
├── features/
│   ├── auth/            # Splash, Onboarding, Login, Register, Role Selection
│   ├── donor/           # Home, Campaign Details, Intent, Notifications, Profile
│   └── organization/    # Dashboard, Campaign Mgmt, Form, Notifications, Settings
├── models/              # UserModel, CampaignModel, NotificationModel, ...
├── services/            # Firebase Auth, Firestore, Storage, FCM
├── shared/
│   └── widgets/         # AppButton, AppTextField, CampaignCard, Skeleton, Empty
└── main.dart
```

---

## Firestore Collections

| Collection       | Description                          |
|-----------------|--------------------------------------|
| `users`         | Donor and organization accounts      |
| `campaigns`     | All charity campaigns                |
| `notifications` | Per-user notifications               |
| `donor_requests`| Donation intent requests             |
| `sponsorships`  | Orphan/student sponsorship profiles  |

---

## Key Features Implemented

- ✅ Splash + Onboarding + Role Selection
- ✅ Email/Password Auth (Donor & Organization)
- ✅ Forgot Password
- ✅ Dark Mode (persisted)
- ✅ RTL Arabic UI throughout
- ✅ Donor Home with Search, Categories, Featured, Urgent campaigns
- ✅ Campaign Details with progress bar, updates timeline
- ✅ Donation Intent flow (no payment — intent only)
- ✅ Save/Unsave campaigns
- ✅ Organization Dashboard with stats
- ✅ Campaign Management (add / edit / delete)
- ✅ Image uploads to Firebase Storage
- ✅ Push notifications via FCM
- ✅ Skeleton loading states
- ✅ Empty & error states
- ✅ Material 3 + Emerald green theme
- ✅ Smooth animations (flutter_animate)
- ✅ Modern bottom navigation (animated pill style for donor, icon+label for org)
