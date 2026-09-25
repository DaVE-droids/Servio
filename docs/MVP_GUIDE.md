# Servio MVP Guide

A plain-language guide to what the Servio MVP does, how to run it, and how to check it works. For *why* things were built the way they were, see `CHANGELOG.md`. For the plan, see `Servio_Roadmap_v1.0.md`.

---

## What Servio does

Servio runs a whole field placement (SIWES / internship) cycle in one app:

1. A **student** registers and submits where they're doing their placement.
2. A **coordinator** approves it and assigns a supervising **lecturer**.
3. The coordinator starts the internship.
4. The student checks in and out each day and writes a daily logbook entry.
5. The lecturer reviews logbook entries and records supervision visits.
6. The coordinator watches progress, then marks the internship completed.

Every step is saved, the people involved are notified, and every important action is recorded in an audit trail that can't be edited or deleted.

---

## What each person can do

### Student
- Create an account and verify their email
- Submit a placement: company, address (searched, so it has a real map location), supervisor, and dates
- See whether the placement is pending, approved, assigned, active, or completed
- Check in and check out each day, and see their attendance history
- Write one logbook entry per day, and edit it until the lecturer reviews it
- Read notifications
- Edit their profile, and delete their account if they want to leave

### Lecturer
- Create an account (it must be **approved by a coordinator** before it does anything)
- See their assigned students
- Open a student's details and get directions to the company in their maps app
- See students' attendance
- Approve logbook entries, or send them back with comments
- Record supervision visit reports (date, time, who was present, observations, a 1–5 rating)
- Read notifications

### Coordinator
Everyone gets the same shape of app: four sections (along the bottom on a phone, down the left on a laptop), with notifications and their profile in the top bar. The coordinator's four are:

| Section | What it's for |
|---|---|
| **Placements** | Approve or reject new placements, assign lecturers, start internships |
| **Students** | Search every student; open one to see their placement and progress, and **mark the internship completed** |
| **Lecturers** | **Approve lecturers who signed up**; see each lecturer's students and workload; deactivate an account |
| **Reports** | Placement numbers, which active students haven't been visited yet, a progress table for every student, and lecturer workload |

The icons at the top open the **audit history** (everything that happened, who did it, and when — filterable), notifications, and the profile menu.

Students see: Home, Placement, Attendance, Logbook. Lecturers see: Home, Students, Reviews, Attendance.

---

## How accounts are created

| Who | How |
|---|---|
| Student | Signs up in the app → verifies email → can use the app straight away |
| Lecturer | Signs up in the app and picks **Lecturer** → verifies email → sees "Awaiting Approval" → a coordinator approves them in **Lecturers** → they tap **Check Again** and they're in |
| Coordinator | Created by an administrator (not through the app) |

A lecturer who hasn't been approved genuinely can't see anything. This is enforced by the database's security rules, not just hidden in the app, so even a modified app couldn't read student records with an unapproved account.

---

## Running the app

The address search needs your LocationIQ token. It lives in `env.local.json` (which is never committed to git), and every command below reads it from there. If that file is missing, copy `env.example.json` to `env.local.json` and paste your token in.

**On a phone or simulator (iOS or Android):**
```
flutter run --dart-define-from-file=env.local.json
```

**In a browser (for coordinators on a laptop):**
```
flutter run -d chrome --dart-define-from-file=env.local.json
```

**Publishing the website:**
```
flutter build web --release --dart-define-from-file=env.local.json
firebase deploy --only hosting
```
This puts the site at `https://servio-e2974.web.app`, free on your current plan. Step-by-step (including how to preview it privately first, and how to roll back): `DEPLOYMENT.md`. Publishing to the App Store and Google Play: `STORE_RELEASE.md`.

---

## Test accounts

Test accounts for every role exist in the live Firebase project: one coordinator, four lecturers, and three students. Their emails and passwords are in `scripts/seed-output.json`, which is **not** committed to git on purpose. The test coordinator has its own password, separate from the others, because it can see every student's details.

To recreate the accounts (needs `scripts/servio-account.json`):
```
cd scripts
SEED_PASSWORD='choose-one' SEED_COORDINATOR_PASSWORD='choose-another' node seed_test_users.js
```
The script is committed to git, so it deliberately doesn't contain passwords. You supply them when you run it.

---

## Checking the whole cycle yourself (about 15 minutes)

Use a laptop browser for the coordinator and a phone or simulator for everyone else, or do it all in the browser by logging out and in.

1. **Lecturer signs up.** On the login screen tap *Create Account*, choose *Lecturer*, and fill it in with an email you can open. Verify the email, then tap *I Have Verified*.
   → You should see **"Awaiting Approval"**.
2. **Coordinator approves them.** Log in as a coordinator → *Lecturers* → the new lecturer is under "Awaiting approval" → *Approve*.
3. **Lecturer gets in.** Back as the lecturer, tap *Check Again*.
   → The lecturer dashboard opens, and the bell shows a new notification.
4. **Student submits a placement.** Log in as a student with no placement → *Submit* on the "Current Internship" card → fill it in. For the address, type part of it and **pick a suggestion from the list**.
5. **Coordinator processes it.** *Placements* → *Pending Review* → *Approve*. Then *Needs Lecturer* → *Assign Lecturer* → pick the lecturer from step 1. Then *Ready to Start* → *Activate*.
6. **Student works.** *Attendance* → *Check In*, later *Check Out*. *Logbook* → write today's entry → *Submit Entry*.
   → The dashboard shows attendance and logbook status.
7. **Lecturer supervises.** *Logbook Reviews* → *Approve*. Then *View Students* → the student → *Submit Visit Report*.
8. **Coordinator checks progress.** *Students* → search for the student → it shows 1 day, 1/1 logbook, 1 visit. Scroll down → *Mark Internship Completed* → confirm.
9. **Student sees it's finished.** Attendance and Logbook now say **"Internship Completed"**, and there's a notification.
10. **Coordinator reviews the record.** *Reports* shows the student as completed. The audit history (clock icon) lists every step above, in order, with who did each one.

---

## Not in this version (and why)

| Missing | Why |
|---|---|
| **Push notifications** (alerts when the app is closed) | Sending them needs a small server program (Cloud Functions), which needs Firebase's paid **Blaze** plan. Blaze only charges beyond the same free allowance you have now, but it needs a billing account. Everything is already in place for it; in-app notifications with the unread badge cover the same events meanwhile. |
| Photos on visit reports | Marked "should have" in the requirements, not "must have". Needs a storage location adding. |
| **Profile photos** | Firebase now requires the paid Blaze plan for file storage, and every upload is refused on the free plan. The button is hidden until you upgrade; everyone gets their initials in a coloured tile meanwhile. |
| Exporting reports (PDF/spreadsheet) | Reports are on-screen for now. |
| Charts and analytics | Your PRD moves these to Version 2. |
| Settings screen | Not in the MVP scope, and nothing needed it. |

---

## Deleting an account

Anyone can delete their own account: **profile picture (top right) → Profile & settings → Delete my account**, confirmed with their password. It removes their sign-in and their profile. Their placement, attendance, logbook, and visit records stay, because those are the institution's academic records — the privacy policy says so. Both app stores require this, which is why it exists.

## Known issues

- **Screen-reader mode on web logs a harmless error.** With a browser screen reader switched on, Flutter itself logs an error while changing screens. It doesn't stop anything working and doesn't happen with the screen reader off.
- **No crash reporting yet.** If the app misbehaves for someone, there's nothing recording it centrally. Worth adding (Firebase Crashlytics, free) before a real launch.
- **Very large institutions.** Coordinator screens load every student and placement at once. That's fine for a pilot. It would need paging once there are thousands of records.
- **Lecturers can view any student's profile**, not only their assigned students'. The database rules can't check the assignment from where the profile is stored. Lecturers still can't see other lecturers' students' attendance, logbooks, or placements.
- **Old records.** A few records created in early testing are missing fields added later (for example, one internship has no country). The app now reads these safely instead of failing.
