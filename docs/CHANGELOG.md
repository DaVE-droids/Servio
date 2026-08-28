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
