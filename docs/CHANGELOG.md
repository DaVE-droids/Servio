# Servio Changelog

A running, human-readable record of *why* changes were made — not just what changed (git history and diffs already cover that), but the reasoning behind it: which spec section it implements, a decision made mid-build, a deviation from the original docs, or a bug it fixed. Entries cover both frontend/app code and backend/db changes (Firestore rules, indexes, Storage rules, data model).

New entries are appended as work happens, not backfilled after the fact.

---

## 2026-08-28

**Changed:** Renamed all seven files in `docs/` from `.md` back to their correct extension.
**Why:** The files had been manually renamed to `.md` by the user, who no longer remembered their original format. Inspection (`file` command + `unzip -l` on each) confirmed they were untouched Microsoft Word 2007+ (`.docx`) files the whole time — only the extension was wrong, no content was lost. Renamed via `git mv` back to `.docx`.
**Follow-up:** None — verified each file still contains a valid `word/document.xml`.

**Changed:** Created `docs/Servio_Roadmap_v1.0.md`, a phased build-order roadmap for the project (Phases 0–9, covering Coordinator approval UI, Lecturer assignment/role, Attendance, Logbook, Supervision, Notifications, Activity/Audit, Reports, Settings/polish).
**Why:** User asked for a full codebase + docs review and a structured plan for how to proceed. The docs (PRD, SAD, DSS, DDS, ARS, PIG, SRS) fully specify an MVP that the codebase is only partially built against; the roadmap sequences the remaining work using the PIG §21 recommended order, adjusted to match what's actually already done vs. stubbed (verified by reading every file under `lib/features/`, `lib/core/`, `lib/app/`, and the Firebase config).
**Follow-up:** Recommends flagging the `sdk: ^3.13.0-231.0.dev` pre-release Dart constraint in `pubspec.yaml` before deeper investment — not yet resolved, deliberately left as a decision for the user.

**Changed:** Created this file, `docs/CHANGELOG.md`.
**Why:** User wants a standing record of the reasoning behind every future change (both app code and backend/db), separate from the roadmap itself, so they can check back later and understand why a given feature or decision exists.
**Follow-up:** None. This file will be appended to as each roadmap phase's work happens.

**Decision (no code change):** Firebase project remains on the Spark (free) plan; no backend migration.
**Why:** User's Firebase billing balance was removed and the project was downgraded to Spark. Every feature built and every phase in the roadmap runs entirely client-side against Firestore/Auth/Storage/FCM, all within Spark's free quota — the SAD's ADR-005 deliberately avoided Cloud Functions for the MVP, so nothing planned requires Blaze. Migrating to a different backend now would mean redoing the already-complete Authentication/Profile/Internship work for a cost problem that isn't being hit yet.
**Follow-up:** Revisit only if Firestore daily read/write quotas are genuinely being approached, or if a later phase (most likely Phase 6, notification fan-out) needs a Blaze-only feature — in which case re-enable Blaze with a budget alert configured first.

**Changed (app code + backend/db):** Phase 0 — wired the Coordinator "Pending Internships" screen to the previously-unused `pendingInternshipsProvider`/`approveInternship()` backend, and added a full reject path alongside it.
- Added `InternshipStatus.rejected` to `lib/core/enums/internship_status.dart`.
- Added `rejectedAt` field to `InternshipModel` (`lib/features/internship/data/models/internship_model.dart`), mirroring `approvedAt`.
- Added `rejectInternship()` to `InternshipService` and `InternshipRepository` (`lib/features/internship/data/services/internship_service.dart`, `.../repositories/internship_repository.dart`), mirroring the existing `approveInternship()` pattern.
- Changed `PendingInternshipsController.approve()` to return `Result<void>` instead of swallowing it (it previously discarded the repository's result despite a comment claiming "the UI layer will handle showing that error" — that was never actually possible with a `void` return). Added a matching `reject()` method.
- Added `lib/features/coordinator/presentation/screens/coordinator_dashboard_screen.dart` — lists pending placements as cards (company, department/state, student ID, submitted date) with Approve/Reject actions; Reject requires confirmation via `AppDialog` per the DSS's Dialog Standards (§20: "Reject internship?" is listed as a use case requiring confirmation). Wired at `/coordinator/dashboard` in `app_router.dart`, replacing the placeholder for the `coordinator` role only.
- **Backend/db:** extended `firestore.rules` — added `rejectedAt` to `internshipFields()`, added `isValidCoordinatorRejection()` (mirrors `isValidCoordinatorApproval()`, only allows the `pending_review → rejected` transition), and the `internships` update rule now allows either approval or rejection. Added a composite index to `firestore.indexes.json` (`status` ASC + `submittedAt` ASC) — required because `getPendingInternships()` filters on `status` and orders by a different field (`submittedAt`), which Firestore cannot serve from automatic single-field indexes alone.
- Also tightened the generic `permission-denied` error message in `InternshipRepository` (was hardcoded to "...submit this placement," which would have shown on a denied approve/reject too) to a role-neutral message, since the same mapper is now shared by three different actions.

**Why:** This was Phase 0 of the approved roadmap — the backend for coordinator approval already existed but was never used by any screen; the Reject path didn't exist at all (`rejected` wasn't even a valid `InternshipStatus`), even though the ARS's repository spec calls for `rejectInternship()` and the PRD's coordinator journey includes rejecting placements. Adding `rejected` to the enum is a deliberate deviation from the DDS's literal status list (`draft, pending_review, approved, assigned, active, completed, archived`), which appears to have simply omitted it.

**Follow-up:**
- The reject action has no reason/comment field — the ARS's `rejectInternship()` signature doesn't specify one, so this stayed minimal for Phase 0. Worth reconsidering once real coordinators are using it.
- No screen yet lets a student see or act on a rejected placement beyond the dashboard showing "Rejected" in red — resubmission after rejection isn't built.
- Card shows the student's `studentId`, not their name — `internships` documents don't denormalize `studentName` (only `attendance`/`logbook_entries`/`supervision_reports` do, per the DDS), and adding a live lookup was out of scope for a "quick win" phase.
