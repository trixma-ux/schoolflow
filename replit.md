# SchoolFlow

A comprehensive Flutter web school management application with Firebase backend.

## Overview

SchoolFlow is a school management platform supporting four user roles:
- **Admin** — manages users, classes, and school data
- **Teacher** — views schedule, grades, student absences, and sends messages
- **Student** — views grades, schedule, and notifications
- **Parent** — views their child's progress and receives notifications

## Tech Stack

- **Framework:** Flutter 3.32.0 (web target)
- **State Management:** flutter_riverpod
- **Navigation:** go_router
- **Backend:** Firebase (Auth + Firestore)
- **UI:** Google Fonts, Phosphor Flutter icons, Material Design

## Project Structure

```
lib/
  core/
    router/      # App routing (go_router)
    theme/       # Colors and theme
  data/
    datasources/ # Dummy/seed data
    models/      # Data models
    repositories/# Firebase repository implementations
  domain/
    repositories/# Abstract repository interfaces
  presentation/
    providers/   # Riverpod providers
    screens/     # UI screens by role (admin, teacher, student, parent, auth)
  firebase_options.dart  # Firebase configuration
  main.dart
web/             # Flutter web entry point files
build/web/       # Built Flutter web output (served in dev)
```

## Development Workflow

- **Build command:** `flutter build web --release`
- **Serve command:** `npx serve -s build/web -l 5000`
- **Workflow:** "Start application" runs both commands sequentially on port 5000

## Deployment

Configured as a static site deployment:
- **Build:** `flutter build web --release`
- **Public dir:** `build/web`

## Firebase Configuration

Firebase project: `schoolflow-42186`
- Authentication enabled
- Firestore enabled
- Config in `lib/firebase_options.dart`

## Known Issues Fixed

- Flutter 3.32 removed `initialValue` parameter from `DropdownButtonFormField` — replaced with `value` parameter in all affected files:
  - `lib/presentation/screens/teacher/message_dialog.dart`
  - `lib/presentation/screens/teacher/teacher_profile_dialog.dart`
  - `lib/presentation/screens/admin/add_user_dialog.dart`
  - `lib/presentation/screens/admin/link_student_dialog.dart`
