# servio

A Flutter & Firebase internship management platform that streamlines student placements, attendance, digital logbooks, lecturer supervision, and coordinator administration.

Servio is a cross-platform application designed to simplify the management of industrial training and internship programs for educational institutions. It replaces manual workflows with a digital platform that allows students, lecturers, and coordinators to manage internship activities efficiently.

---

# Overview

Many institutions still manage internships manually using paper logbooks, spreadsheets, emails, and Google Forms. These processes are often slow, difficult to track, and prone to errors.

Servio centralizes the entire internship workflow into a single application.

Students can submit internship details, record attendance, complete digital logbooks, and receive updates.

Lecturers can monitor assigned students, review logbooks, submit supervision reports, and manage visits.

Coordinators can approve placements, assign lecturers, monitor progress, and oversee the internship process from a centralized dashboard.

---

# Features (MVP)

### Authentication

- Email & Password Authentication
- Email Verification
- Password Reset
- Role-Based Access Control
- Secure Session Management

---

### Student

- Complete Profile
- Submit Internship Placement
- View Internship Status
- Daily Attendance Check-In / Check-Out
- Digital Logbook
- Notifications
- Activity Timeline

---

### Lecturer

- View Assigned Students
- Review Student Logbooks
- Submit Supervision Reports
- View Attendance
- Receive Notifications

---

### Coordinator

- Approve Internship Placements
- Assign Lecturers
- Monitor Student Progress
- Dashboard & Reports
- Notification Management

---

# Technology Stack

| Layer | Technology |
|---------|------------|
| Framework | Flutter |
| Language | Dart |
| Backend | Firebase |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging |
| Maps | Google Maps Platform |
| State Management | Riverpod |
| Routing | GoRouter |

---

# Architecture

Servio follows a layered architecture.

```
UI
    ↓
Riverpod Providers
    ↓
Controllers / Notifiers
    ↓
Application Services (Use Cases)
    ↓
Repositories
    ↓
Firebase Services
    ↓
Firebase SDK
```

Each layer has a single responsibility.

Business logic is separated from presentation and infrastructure.

---

# Project Structure

```
lib/
│
├── app/
├── core/
├── features/
│
│   ├── authentication/
│   ├── dashboard/
│   ├── internship/
│   ├── attendance/
│   ├── logbook/
│   ├── supervision/
│   ├── notifications/
│   ├── profile/
│   └── settings/
│
└── main.dart
```

Each feature follows the same internal architecture.

```
feature/
│
├── data/
├── domain/
├── presentation/
│
├── models/
├── repositories/
├── services/
├── use_cases/
├── controllers/
├── providers/
├── screens/
└── widgets/
```

---

# Documentation

Project documentation is located in the `/docs` directory.

| Document | Purpose |
|----------|---------|
| PRD | Product Requirements |
| SAD | System Architecture |
| DDS | Database Design |
| ARS | API & Repository Specification |
| PIG | Project Implementation Guide |
| DSS | UI/UX Design System |

These documents are the source of truth for the project.

If implementation differs from documentation, the documentation should be reviewed before changing the code.

---

# Development Principles

Servio follows these principles:

- Feature-first architecture
- Single Responsibility Principle
- Thin UI
- Repository Pattern
- Use Case Pattern
- Consistent error handling
- Strong typing
- Predictable folder structure
- Readable code over clever code

---

# Getting Started

## Prerequisites

- Flutter SDK
- Dart SDK
- Firebase CLI
- FlutterFire CLI
- Android Studio or VS Code
- Xcode (macOS for iOS builds)

---

## Installation

Clone the repository.

```bash
git clone <repository-url>
```

Move into the project.

```bash
cd servio
```

Install packages.

```bash
flutter pub get
```

Configure Firebase.

```bash
flutterfire configure
```

Run the project.

```bash
flutter run
```

---

# Development Workflow

When implementing new functionality:

1. Update documentation if requirements change.
2. Create or update models.
3. Create services.
4. Create repositories.
5. Create use cases.
6. Create providers.
7. Create controllers.
8. Build the UI.
9. Write tests.
10. Verify Firestore security rules.

---

# Coding Standards

- Widgets must not communicate directly with Firebase.
- Repositories must not depend on Flutter UI.
- Business logic belongs in Use Cases.
- Controllers manage UI state only.
- All asynchronous methods return `Result<T>`.
- Shared utilities belong in `core/`.

---

# Branch Naming

```
feature/authentication
feature/dashboard
feature/attendance
feature/logbook

fix/login
fix/firestore-rules

refactor/theme
```

---

# Commit Convention

Servio follows Conventional Commits.

Examples:

```
feat: implement attendance module

fix: resolve duplicate check-in bug

docs: update architecture specification

refactor: simplify notification repository
```

---

# Testing

The project includes:

- Unit Tests
- Widget Tests
- Integration Tests

Every feature should be tested before merging.

---

# Future Roadmap

Future releases may include:

- Multi-University Support
- Web Application
- Offline Mode
- Analytics Dashboard
- AI-Based Reports
- Calendar Integration
- QR Code Attendance
- GPS Verification Improvements
- Cloud Functions
- Admin Portal

---

# Contributing

Before contributing:

1. Read the documentation in `/docs`.
2. Follow the architecture.
3. Follow the implementation guide.
4. Write tests.
5. Keep commits small and descriptive.

---

# License

This project is currently private.

All rights reserved.

---

# Author

Developed by Dave.

Built with Flutter and Firebase.

AI Development Guidelines:
- Always read /docs before making changes.
- Never bypass the architecture.
- Never introduce new dependencies without justification.
- Never modify multiple features in a single task unless explicitly requested.
- Keep generated code aligned with the documented folder structure and coding standards.
- Explain any conflict between implementation requests and the documented design before making changes.
