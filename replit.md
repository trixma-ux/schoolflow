# SchoolFlow

A comprehensive Flutter web school management application with Firebase backend.

## Overview

SchoolFlow is a school management platform supporting four user roles:
- **Admin** — manages users, classes, subjects (filières CI), complaints, and school data
- **Teacher** — views classes, grades, class members; configures filière + subjects + classes
- **Student** — views grades, schedule, class members, submits complaints
- **Parent** — views child's progress and receives notifications

## Tech Stack

- **Framework:** Flutter 3.32.0 (web target)
- **State Management:** flutter_riverpod
- **Navigation:** go_router
- **Backend:** Firebase (Auth + Firestore)
- **UI:** Google Fonts, Material Design 3
- **Persistence:** shared_preferences (dark mode)

## Project Structure

```
lib/
  core/
    data/        # filieres_ci.dart — 10 Ivorian series (A,B,C,D,E,G1,G2,T1,T2,T3)
    router/      # App routing (go_router)
    theme/       # Colors and theme (light + dark)
  data/
    models/      # Data models (user, subject, grade, class, complaint…)
    repositories/# Firebase repository implementations
  domain/
    repositories/# Abstract repository interfaces
  presentation/
    providers/   # Riverpod providers (auth, data, theme)
    screens/
      admin/     # AdminDashboard (overview + users + classes + complaints)
      teacher/   # TeacherDashboard (home + grades + class members + messages)
      student/   # StudentDashboard (home + grades + schedule + class + complaints)
      parent/    # ParentDashboard (children + messages)
      shared/    # ProfileScreen + SettingsScreen (shared across all roles)
      auth/      # Login screen
  firebase_options.dart  # Firebase configuration
  main.dart
build/web/       # Built Flutter web output (served in dev + deployment)
```

## Development Workflow

- **Build command:** `flutter build web --release` (run manually when source changes)
- **Serve command (workflow):** `npx serve -s build/web -l 5000`
- **Workflow:** "Start application" serves pre-built files on port 5000 (no rebuild)
- **NOTE:** Flutter 3.32.0 + Nix Dart SDK requires `flutter pub get` before `flutter build web --release`.
  Use `flutter build web --release --no-pub` ONLY if you have previously run `flutter pub get`.

## Deployment

Configured as a static site deployment:
- **Build:** `flutter build web --release`
- **Public dir:** `build/web`

## Firebase Configuration

Firebase project: `schoolflow-42186`
- Authentication enabled
- Firestore enabled
- Config in `lib/firebase_options.dart`
- Collections: users, classes, subjects, grades, assignments, schedules, notifications, complaints

## Firestore Rules (firestore.rules)

All 4 roles (admin, teacher, student, parent) have properly scoped read/write rules.
- `complaints` collection: students/teachers create, admin updates (respond/resolve)
- `grades`: teachers & admins write, students read own, parents read child's
- `classes`: admins and teachers write
- `users`: admins can create/delete; users update their own profile (except role field)

### Deploying Firestore Rules

The project is configured for Firebase CLI deployment via `firebase.json` and `.firebaserc`.

**Prerequisites (one-time setup):**
```bash
npm install -g firebase-tools
firebase login
```

**Deploy rules after any change to `firestore.rules`:**
```bash
firebase deploy --only firestore:rules
```

**Deploy indexes after any change to `firestore.indexes.json`:**
```bash
firebase deploy --only firestore:indexes
```

**Deploy both at once:**
```bash
firebase deploy --only firestore
```

- Firebase project: `schoolflow-42186` (set in `.firebaserc`)
- Rules file: `firestore.rules`
- Indexes file: `firestore.indexes.json`
- Config file: `firebase.json`

> Without deploying, changes to `firestore.rules` only exist locally and have no effect on the live database. Always deploy after editing rules to avoid `permission-denied` errors in production.

## Bug Fixes Applied (May 2026)

### Critical Fixes
1. **Admin user creation** — Firebase `createUserWithEmailAndPassword` used to sign out
   the admin when creating a new user. Fixed using a secondary Firebase app instance
   so the admin session is preserved throughout user creation.
   - File: `lib/data/repositories/auth_repository_impl.dart`

2. **Missing Firestore rules for `complaints`** — Collection had no rules (default deny).
   All complaint reads/writes were silently blocked. Added proper rules for all roles.
   - File: `firestore.rules`

3. **Date picker crash** — `showDatePicker` in AssignmentDialog used
   `locale: Locale('fr', 'FR')` without `flutter_localizations` in pubspec → crash.
   Removed the locale parameter.
   - File: `lib/presentation/screens/teacher/assignment_dialog.dart`

### UI/UX Fixes
4. **Admin "Gérer les classes" button** — Was calling an empty `() {}` callback.
   Now correctly navigates to the Classes tab via a parent callback.
   - File: `lib/presentation/screens/admin/admin_dashboard.dart`

5. **Assignment dialog subjects** — Now filters subjects by the teacher's
   `effectiveSubjectIds` so teachers only see their own subjects.
   - File: `lib/presentation/screens/teacher/assignment_dialog.dart`

## Features Implemented

### Filières de Côte d'Ivoire
- 10 filières: A (Littéraire), B (Économique), C (Mathématiques), D (Sciences Expérimentales),
  E (Techniques), G1, G2 (Commerciales), T1, T2, T3 (Techniques)
- Each filière has subjects with coefficients and unique IDs (`{filiere}_{code}`, e.g., `C_maths`)
- Admin can seed all CI subjects via "Initialiser les matières CI" button
- Teachers select filière → subjects → classes (max 5) via multi-step profile dialog

### Dark Mode
- ThemeNotifier with SharedPreferences persistence
- Toggle in Settings screen accessible from AppBar

### Standardized AppBar (all dashboards)
- Notifications bell with unread count badge
- Profile icon → ProfileScreen
- Settings icon → SettingsScreen

### Admin Features
- Create users (any role) without losing admin session
- Assign classes to students at creation time
- Link students to parents via dedicated dialog
- Manage classes (create/delete)
- View and respond to student complaints (resolve/reject)
- Initialize CI subjects in one click
- View KPI dashboard: student/teacher/class/parent counts

### Teacher Features
- Configure filière, subjects, and up to 5 classes via profile dialog
- Enter grades per student/class/subject
- Publish assignments with deadline
- View class members per class (tabbed)
- Send messages to parents/admin
- View received notifications

### Student Features
- View grades with subject and type breakdown
- View class schedule
- View classmates in their class
- Submit complaints (grade/absence/other) and track admin responses

### Parent Features
- View linked children
- Receive grade and notification alerts
