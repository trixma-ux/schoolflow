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

- **Build command:** `flutter build web --release --no-pub`
- **Serve command:** `npx serve -s build/web -l 5000`
- **Workflow:** "Start application" runs both commands sequentially on port 5000

## Deployment

Configured as a static site deployment:
- **Build:** `flutter build web --release`
- **Public dir:** `build/web`
- **No build command in deployment section** (pre-built files served directly)

## Firebase Configuration

Firebase project: `schoolflow-42186`
- Authentication enabled
- Firestore enabled
- Config in `lib/firebase_options.dart`
- Collections: users, classes, subjects, grades, assignments, schedules, notifications, complaints

## Features Implemented

### Filières de Côte d'Ivoire
- 10 filières: A (Littéraire), B (Économique), C (Mathématiques), D (Sciences Expérimentales), E (Techniques), G1, G2 (Commerciales), T1, T2, T3 (Techniques)
- Each filière has subjects with coefficients and unique IDs (`{filiere}_{code}`, e.g., `C_maths`)
- Admin can seed all CI subjects via the "Initialiser les matières CI" button
- Teachers select their filière → subjects → classes (max 5) via a multi-step profile dialog

### Dark Mode
- ThemeNotifier with SharedPreferences persistence (key: `theme_mode_dark`)
- Toggle in Settings screen accessible from AppBar

### Standardized AppBar (all dashboards)
- Notifications bell with unread count badge
- Profile icon → ProfileScreen (name edit, role info, subjects, classes)
- Settings icon → SettingsScreen (dark mode toggle, logout)

### Admin Complaints Tab
- Lists all student grievances (pending/resolved/rejected)
- Admin can reply and change status via inline dialog

### Student Complaints Tab
- Students can submit complaints (grade / absence / other)
- See their own complaints with admin responses

### Class Members View
- Teachers: tab per class showing all enrolled students
- Students: view all classmates with "Moi" badge

### Known Issues / Notes
- Flutter 3.32.0 Nix SDK: `flutter build web --release --no-pub` works but full workflow rebuild may fail with DDC/Dart2JS in some environments. Use `--no-pub` to skip pub get in workflow.
- SubjectModel requires `filiere` field — always pass it when creating instances
- ComplaintModel: `subjectId` field is optional in Firestore (can be empty string)
