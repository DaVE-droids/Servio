# Servio — Project Roadmap

## Context

Servio has seven detailed planning documents in `docs/` (PRD, SAD, DSS, DDS, ARS, PIG, SRS) that fully specify an MVP: a Flutter + Riverpod + Firebase field-placement platform for three roles (Student, Lecturer, Coordinator) covering six modules — Authentication, Placement/Internship, Attendance, Digital Logbook, Supervision, and Administration/Reporting — backed by eight Firestore collections (`users`, `internships`, `attendance`, `logbook_entries`, `supervision_reports`, `notifications`, `audit_events`, `activity_logs`).

The docs were recently un-corrupted (they'd been renamed `.md` but were valid `.docx` all along — no content was lost) and are the authoritative spec. The codebase already follows their architecture precisely (feature-first folders, Repository → Service → Firestore layering, `Result<T>` error handling, Riverpod DI) — so the job now is not to design the system, it's to finish building it against the spec that already exists, in the order that unblocks the most work.

**Current state vs. the spec**, from reading every file in `lib/features/`, `lib/core/`, `lib/app/`, and the Firebase config:

| Area | Status |
|---|---|
| Authentication | ✅ Complete — register/login/logout/password reset/email verification, real Firebase Auth + Firestore |
| Profile | ✅ Complete — view/edit, photo upload to Storage |
| Internship (student side) | ✅ Complete — multi-step submission form, validation, Firestore write |
| Internship (coordinator side) | ⚠️ Backend only — `pendingInternshipsProvider` + `approveInternship()` exist in `lib/features/coordinator/presentation/providers/pending_internships_provider.dart` but are **never used by any screen** (dead code) |
| Dashboard | ⚠️ Student screen works, but bypasses its own repo — `lib/features/dashboard/data/repositories/dashboard_repository.dart` unconditionally returns `Failure('...not implemented yet')`; the real screen pulls data from the `profile` and `internship` controllers directly |
| Lecturer role | ❌ No feature module exists at all. Routes (`/lecturer/dashboard`, `/lecturer/assigned-students`, `/lecturer/visit-reports`) render `AuthenticatedPlaceholderScreen` |
| Attendance, Logbook, Supervision, Notifications, Activity, Audit, Reports, Settings | ❌ Scaffolding only — model + empty service + repo stub (`Failure('...not implemented yet')`) + empty controller, **no screens**, matching `StudentComingSoonScreen`/placeholder routes |
| Firestore rules & indexes | ⚠️ Only `users` and `internships` are modeled in `firestore.rules`; only one composite index exists. The DDS specifies rules and ~14 composite indexes across all 8 collections |
| Storage rules | ⚠️ Only `profile_photos/{userId}/avatar.jpg` allowed; DDS also specifies `logbook_attachments/` and `supervision_photos/` paths |
| Tests | Genuine unit/widget tests exist for auth, profile, internship validators/models, and the student dashboard shell — none for the unbuilt features |
| pubspec | `sdk: ^3.13.0-231.0.dev` is a Dart **dev/pre-release channel** constraint — worth flagging as a stability risk before this goes further |

## Recommended Build Order

The PIG (`Servio_PIG_v1.0.docx`, §21) already prescribes a dependency-minimizing order, and it lines up with what's actually missing. Each phase below is a full vertical slice — model → service → repository → use case → provider → controller → screen → tests — following the existing feature's own pattern (e.g. `internship/`) as the template, and each should satisfy the Definition of Done from PIG §20 / ARS §30 (loading/empty/error states, Firestore rules validated, audit + activity events generated, tests passing).

### Phase 0 — Quick win: wire up the Coordinator approval UI
The backend already exists and is idle. Build the Coordinator dashboard's "Pending Internships" screen in `lib/features/coordinator/presentation/screens/` that consumes the existing `pendingInternshipsProvider`, lists submissions, and calls `.approve()`. Add a reject path (repository currently only has `approveInternship()` — add `rejectInternship()` alongside it per ARS §8). Replace the `/coordinator/dashboard` and related placeholder routes. This closes the loop on the one workflow that's 90% done and gives the coordinator role its first real screen.

### Phase 1 — Lecturer Assignment
Nothing today assigns a lecturer to an internship — it's a hard prerequisite for Attendance, Logbook, and Supervision, since all three are scoped to "the assigned lecturer" per business rules in the SRS/ARS. Add `assignLecturer()` to `InternshipRepository`, a coordinator screen to pick a lecturer, and update `firestore.rules` (`internships` update rule currently only allows the `pending_review → approved` transition — extend it for lecturer assignment per DDS §5 status flow: `approved → assigned`).

### Phase 2 — Lecturer role & dashboard
Create the `lecturer` feature module (doesn't exist yet). Minimum: a real `LecturerDashboardScreen` showing assigned students (SAD §22.2 nav: Assigned Students, Visit Reports, Notifications, Profile), replacing the `AuthenticatedPlaceholderScreen` at `/lecturer/dashboard` and `/lecturer/assigned-students`. This unblocks Supervision (Phase 5) and gives lecturers something other than Profile to use.

### Phase 3 — Attendance
Build out `lib/features/attendance/` (currently pure stub). Implement `checkIn()`/`checkOut()`/`getTodayAttendance()`/`getAttendanceHistory()` in `AttendanceRepository` per ARS §10, using a Firestore **transaction** for check-in (read-then-write to prevent duplicate same-day records — ARS §9 explicitly calls this out as the one place a transaction, not a batch, is required). Add the composite indexes from DDS §6 (`studentId+date`, `lecturerId+date`, `internshipId+date`) and attendance security rules. Wire the student `/attendance` route and a lecturer attendance view.

### Phase 4 — Digital Logbook
Build out `lib/features/logbook/`. One entry per working day (business rule, enforced client + repository + rules), editable until reviewed, lecturer approve/request-changes flow (DDS §5 logbook status: `pending → approved` / `changes_requested`). Reuses the `ProfilePhotoUploadRequest`-style pattern already established for attachments via Storage. Wire student `/logbook` (currently `StudentComingSoonScreen`) and a lecturer review queue.

### Phase 5 — Supervision (built 2026-09-03)
Build out `lib/features/supervision/`. Depends on Phase 2 (lecturer role) and Phase 1 (assignment). Visit report form (visit date/time, presence flags, observation, recommendations, 1–5 rating, optional photos) per DDS §5, `createReport()` immutable after submission. Wire `/lecturer/visit-reports`.

**Built:** every MUST-HAVE requirement — FR-SUP-001 (assigned students list, from Phase 2), FR-SUP-002 (`LecturerStudentDetailScreen`), FR-SUP-003 (Navigate, built early alongside the location work), FR-SUP-004 (`LecturerVisitReportScreen`), FR-SUP-006 (report + audit event written as one batch). `supervision_reports` and `audit_events` rules plus a `supervision_reports` composite index are deployed. See `docs/CHANGELOG.md` for the deliberate scope cuts.

**Still open from this phase:**
- FR-SUP-005 (SHOULD HAVE) — visit photo upload. `photoUrls` exists on the model and passes rules validation, but nothing populates it; needs the Storage path (`supervision_photos/{reportId}/...`) that DDS §7 specifies and which `storage.rules` doesn't have yet.
- `getReports()` / `getVisitSchedule()` from the ARS's `SupervisionRepository` method list — no FR-SUP requirement or UI slot maps to either yet.
- The `users` read rule currently lets a lecturer read *any* student's profile, not only assigned ones (Firestore rules can't do the assignment lookup from that path). Tighten if it matters.

**Hard prerequisite for this phase:** FR-SUP-003 requires "Navigate" to open the device's maps app using the company's *real* saved coordinates — meaningless with placeholder `(0.0, 0.0)` values. See "Known gap — company location capture" below; that is now resolved, and the Navigate button was built ahead of the rest of this phase.

### Known gap — company location capture (resolved)
The PRD (§10, §17 Placement Module) and SAD (ADR-007) both call for company location to come from Google Maps — an address/coordinate picker, or geocoding a typed address — not manual coordinate entry. The original internship submission screen (built before this roadmap existed) shipped with two raw Latitude/Longitude text fields instead, which was unusable in practice and got removed during Phase 1 testing; a `(0.0, 0.0)` placeholder was submitted in its place as a stopgap.

**2026-08-28:** `StudentInternshipScreen` first geocoded a free-text `companyAddress` via `MapsService.geocodeAddress()` (the free, on-device `geocoding` package) before saving. See `docs/GEOCODING.md`.

**2026-08-30 — superseded by search-and-pick:** blind free-text geocoding was replaced with `AddressSearchField`, a debounced live-suggestion search (LocationIQ, free tier) — the student now picks a real matched address rather than typing free text and hoping it resolves, and the picked suggestion carries its own coordinates directly. A Country dropdown (defaulting to Nigeria) and dependent State dropdown were added alongside it, replacing the old free-text `state` field and adding a `country` field that didn't exist before (needed to represent an abroad placement correctly, and to keep coordinator-facing filtering/reporting data consistent instead of free-text-fragmented). The original "full Maps picker" idea from ADR-007 (a visual pin-drop/map preview) is still not built, and Google's Places Autocomplete remains the eventual upgrade path once a Google Cloud billing account is funded — see `docs/LOCATION_SERVICES.md` for the full explanation, the reasoning for LocationIQ over the alternatives, and how to switch later.

**Navigate button — first version already built, ahead of the rest of Phase 5:** `MapsService.launchNavigation()` plus a "Navigate" button on the lecturer's Assigned Students screen were added alongside the search-and-pick work, since they only needed real coordinates to exist (which they now do) and needed no other part of the Supervision module. Opens the device's installed maps app via a free deep link (Apple Maps on iOS, Google Maps elsewhere) — no paid Maps SDK/API involved. The rest of Phase 5 (visit report form, `createReport()`, `/lecturer/visit-reports`) is still not built.

**Related gap found in Phase 3 (Attendance):** check-in/check-out GPS capture (`checkInLatitude`/`checkInLongitude`/etc. on `AttendanceModel`) has the same problem — no `geolocator` dependency, no platform permission config, fields present in the schema but never populated. A real fix needs the `geolocator` package, `NSLocationWhenInUseUsageDescription` in `Info.plist`, Android location permissions, and an NFR-PRIV-003-compliant "why we're asking" screen before the OS permission prompt. Separate from the company-location gap above (that's Maps/geocoding for a fixed address; this is live device GPS at the moment of check-in), but likely worth tackling together given the overlapping permission/package setup.

### Phase 6 — Notifications (in-app built 2026-09-03; push blocked on Blaze)

**Built:** the full in-app half — `notifications` collection, list screen with unread count and mark-as-read, and notification writes retrofitted into all five existing actions (placement approve/reject, lecturer assignment, logbook review, visit report), each inside the action's own batch. Rules and indexes deployed.

**Not built — and not buildable on Spark:** actual push delivery. Sending an FCM message requires a server (Cloud Functions → Blaze); a client can only receive. When Blaze is enabled, a function triggering on `notifications` document creation can fan out to the recipient's device token — the data model already carries what it would need. See `docs/CHANGELOG.md`.

**Original plan:**
Build out `lib/features/notifications/`, replacing the stub. This is cross-cutting — every write path from Phases 0–5 above should already be calling into it once it exists (internship approval, lecturer assignment, logbook review, etc., per ARS §19 application-service pattern). Implement `NotificationService` (currently empty in `lib/core/services/`) against `firebase_messaging`, and the Firestore-backed in-app list. Retrofit notification-triggering into the repositories built in earlier phases as part of their batched writes (ARS §9's "Approve Internship → update + notify + activity + audit, single batch" pattern) — this is intentionally sequenced last so it isn't rebuilt repeatedly as each business action is added.

### Phase 7 — Audit Trail & Activity History (built 2026-09-07)

**Built:** audit events retrofitted into all twelve write paths (placement submitted/approved/rejected, lecturer assigned, internship activated, logbook created/edited/approved/changes-requested, attendance in/out, visit recorded), each committed inside its action's own batch or transaction. Coordinator audit history at `/coordinator/audit` — day-grouped chronological view (FR-AUDIT-004) with user/action/entity/date filters (FR-AUDIT-005). No rules or index changes were needed; the generic `audit_events` create rule from Phase 5 already covered the retrofit.

**Deliberate deviation:** `activity_logs` is not written and its stub module was deleted. The SRS says the audit trail and activity log are "generated from the same underlying events but serve different audiences", so Servio records each event once in `audit_events` and renders it two ways. See `docs/CHANGELOG.md`.

**Still open from this phase:** the coordinator view filters client-side over the 300 most recent events (server-side filtering needs three composite indexes); "Student Created" and "Internship Completed" audit events await a registration hook and a completion flow that doesn't exist yet.

**Original plan:**
Build out `lib/features/activity/` and `lib/features/audit/`, again retrofitting into every write path built so far. These are both "generated from the same underlying events" (SRS §1) so should share the batched-write hookup added in Phase 6. Add a Coordinator-facing audit history view (SRS FR-AUDIT-004/005 — filterable by user/date/action/entity).

### Phase 8 — Reports & Coordinator admin screens (built 2026-09-15)

**Built:** coordinator navigation shell (Placements · Students · Lecturers · Reports; bottom bar on phones, side rail on laptops); student management with search and a detail page; **internship completion** (`active → completed`), the last step of the cycle; lecturer management with **lecturer self-registration and coordinator approval**; on-screen reports (placement summary, supervision coverage, student progress, lecturer workload) using Firestore `count()` aggregations. Rules deployed: lecturer permissions now require an approved account. The full placement cycle was driven end to end through the web build. See `docs/CHANGELOG.md` and `docs/MVP_GUIDE.md`.

**Original plan:** Build out `lib/features/reports/` and the remaining Coordinator screens (`/coordinator/students`, `/coordinator/lecturers`) now that the underlying data (attendance, logbook, supervision, audit) actually exists to report on.

## Hosting and store preparation (2026-09-22)

A design pass over every screen (see `docs/DESIGN.md` for the concept), the
fixes a hosted multi-device app needs (real URLs that survive a refresh, a
router that no longer resets on the hourly token refresh, per-role scoped
queries), in-app account deletion for the app stores, and the web hosting
configuration with security headers. Full detail in `docs/CHANGELOG.md`.

**Still open from this phase:**
- The site has not been deployed yet: the owner wants to run the deploy
  together (`docs/DEPLOYMENT.md`), and the legal pages still need the
  operator's name and contact email.
- The app ID is still `com.example.servio`, which Google Play rejects and
  which can never change after the first upload (`docs/STORE_RELEASE.md`).
- Profile photo uploads are switched off: Cloud Storage now refuses every
  write on the free plan.
- No crash reporting yet (Crashlytics needs native setup).

## MVP status (2026-09-15)

Every item in PRD §18's MVP scope is built **except push notifications**, which need Cloud Functions and therefore the Blaze plan (in-app notifications cover the same events). PRD §21's success definition — completing an entire placement cycle in the platform — was demonstrated end to end.

**Still open after the MVP:**
- Push notification delivery (billing decision: Blaze + Cloud Functions).
- FR-SUP-005 visit photos (SHOULD HAVE) — needs the `supervision_photos/` Storage path.
- Report export (CSV/PDF).
- Pagination for coordinator screens and audit history once records reach the thousands.
- Lecturers can read any student's profile, not only assigned ones (a Firestore rules limitation noted in Phase 5).
- The Dart SDK constraint still points at a pre-release channel (see "Cross-cutting work" below).

### Phase 9 — Settings & polish
Lowest priority: ~~`lib/features/settings/`~~ (stub removed in Phase 8 — nothing linked to it and it isn't in PRD MVP scope; rebuild if a real need appears), plus cross-cutting polish — Crashlytics/error monitoring (SRS NFR-REL-003/NFR-LOG-001, not yet integrated), dark mode theme (DSS §4 says build with theme support in mind — confirm no hardcoded colors have crept into any feature screens), and closing test-coverage gaps for every feature built in Phases 0–8.

## Waiting on a budget decision (as of 2026-09-26)

Four things are blocked on spending rather than on engineering. Three of
them unblock together the moment billing is enabled, so it's worth doing
them in one session rather than three.

| | Cost | Unblocks |
|---|---|---|
| **Blaze plan** (pay-as-you-go) | ₦0 in practice at pilot scale — Cloud Functions' 2M monthly calls are free | Email notifications, push notifications, profile photo uploads |
| **A domain** (e.g. `servio.ng`) | ~$10/year | Email deliverability, a real address instead of `servio-e2974.web.app` |
| **Google Play** | $25 once | Public Android distribution (APK sharing works meanwhile) |
| **Apple Developer** | $99/year | iOS at all — no sideloading, so iPhone users are on the website until then |

Set a budget alert before enabling Blaze. Blaze charges only *beyond* the
same free quotas Spark has; the risk isn't normal use, it's a runaway loop.

### Phase 10 — Email notifications (blocked on Blaze)

Firebase sends email only for its own auth flows (verification, password
reset). Custom email needs somewhere server-side to send from, which means
Cloud Functions, which means Blaze. Sending from the app itself is not an
option: the credentials would ship inside the app for anyone to extract.

**The design fits what's already built.** All nine events already write a
`notifications` document (`NotificationFactory`). So the whole feature is a
Cloud Function triggered on the creation of one of those documents: look up
the recipient's email, send it. No client changes, no second write path, and
the same trigger later carries push notifications.

**Which events should email.** Not all nine. `logbookApproved` and
`logbookChangesRequested` fire every working day for every active student —
daily email people will mute or mark as spam, and most of the quota. Email
the milestones only:

- Placement approved / rejected
- Lecturer assigned (to the student and to the lecturer)
- Supervision visit recorded
- Internship completed
- Lecturer account approved

That is roughly six emails per student per placement cycle. The daily
logbook events stay in-app, and could become a weekly digest if anyone asks.

**Provider.** Brevo's free tier is the most generous (300/day, ~9,000/month);
Resend gives 3,000/month and is the pleasanter API. SendGrid ended its free
plan in 2025 — ignore older tutorials recommending it. Do **not** build on
Firebase's "Trigger Email" extension: Firebase Extensions shut down on
31 March 2027.

**Deliverability needs the domain.** Without one, mail goes out from the
provider's shared sending domain and a good share lands in spam, which is
worse than sending nothing — people stop trusting it. With a domain, two DNS
records (SPF and DKIM) make placement reliable.

**Also in scope:** a per-user notification preference so people can opt out,
which most jurisdictions require for non-transactional mail and is decent
practice regardless.

**Estimated work:** about half a day — a `functions/` folder with one
trigger, the recipient lookup, a branded HTML template, the event filter
above, and the opt-out flag.

## Firebase plan constraints

The Firebase project was recently downgraded back to the **Spark (free) plan** after the linked billing balance was removed. This is not a reason to migrate off Firebase, and the roadmap above assumes staying on Spark:

- Every feature implemented so far, and every phase planned above, runs entirely client-side against Firestore, Firebase Auth, Storage, and FCM — all included in Spark's free quota (Firestore: 50K reads / 20K writes / 20K deletes per day; Storage: 5GB stored, 1GB/day download; Auth and FCM are free regardless of plan).
- The SAD's own ADR-005 chose the simpler Layered Feature Architecture specifically to avoid needing Cloud Functions for the MVP — Cloud Functions is listed under §25.3 "Extension Points" as *future* work, not part of v1. So nothing in Phases 0–9 requires Blaze.
- Migrating to a different backend now (e.g. Supabase) would mean re-doing the already-complete Authentication, Profile, and Internship features plus the Firestore security-rules model in the DDS/ARS, for a cost problem that isn't actually being hit yet.
- If a future phase does need a paid feature (most likely: server-side notification fan-out via Cloud Functions in Phase 6), re-enable Blaze with a budget alert configured first — Blaze is pay-as-you-go *beyond* the same free quota Spark has, not "billing starts immediately."
- Keep an eye on Firestore quota usage as the pilot's user count grows (Firebase console → Usage tab); revisit this note only if the app is genuinely approaching the daily read/write caps.

## Cross-cutting work, not a separate phase

- **Firestore rules & indexes**: extend `firestore.rules` and `firestore.indexes.json` incrementally *within* each phase above (not deferred), following the field-list + role-check pattern already used for `users`/`internships`. The DDS §6 index table is the checklist.
- **Storage rules**: add `logbook_attachments/{internshipId}/{entryId}/...` and `supervision_photos/{reportId}/...` paths in Phase 4/5 respectively, matching the existing `profile_photos/` pattern in `storage.rules`.
- **Dart SDK constraint**: flag `sdk: ^3.13.0-231.0.dev` in `pubspec.yaml` to the user before deeper investment — this pins to a pre-release Dart channel, which is a risk for build reproducibility and CI. Worth a deliberate decision (pin to stable, or confirm it's intentional) rather than discovering it mid-phase.

## Change log requirement

The user wants a standing, human-readable record of *why* each future change was made — not just what changed (git history already covers that) but the reasoning behind it, so they can check back later and understand why a given feature or decision exists. This covers **both frontend and backend/db changes** — Firestore schema edits, security rules, indexes, and Storage rules are just as much a "change" as a new screen, and must get an entry too.

`docs/CHANGELOG.md` is that record. From this point forward, every phase's work should append an entry to it — new entries added as work happens, not backfilled after the fact. Each entry should include:
- Date
- What changed (feature/area, brief — explicitly note if it touched `firestore.rules`, `firestore.indexes.json`, `storage.rules`, or the Firestore data model, in addition to any app code)
- Why (the driving reason — spec section it implements, a decision made mid-build, a deviation from the original docs, a bug it fixed)
- Any follow-up or known limitation left for later

This file is separate from this roadmap — the roadmap is the plan, the changelog is the running record of what actually happened and why.

**Git discipline**: files are created/edited in the working tree only. No `git add`, `git commit`, or `git push` — for the changelog, this roadmap, or any code from Phase 0 onward — without the user's explicit go-ahead each time. Staging and committing are separate, permissioned steps, not an automatic part of finishing a phase.

## Verification

Each phase should be considered done per the existing test conventions already in `test/` (validator unit tests, model serialization tests, widget tests for the screen) plus the Definition of Done checklists in PIG §20 and ARS §30 — run `flutter test`, manually exercise the golden path in the running app (loading/empty/error states), and confirm the relevant Firestore rules/indexes were added alongside the feature rather than after.
