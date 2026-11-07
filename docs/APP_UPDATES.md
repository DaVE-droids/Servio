# Updating the app without an app store

**Status: designed and approved, not built.** Nothing described here exists
in the app yet. Reviewed 2026-11-07: the in-app download with a progress
bar (§9) was chosen over a browser handoff, and the Firestore config
document (§5) and GitHub Releases (§6) were both approved as described.

The goal: when a student or lecturer opens Servio and a newer build exists,
the app tells them and offers to install it — instead of you chasing people
over Socials to send them a new APK.

---

## 1. How app stores normally do this, and what you're replacing

When an app comes from Google Play, Play itself checks for new versions in
the background and updates it. You get that for free, and you lose it
entirely when you hand someone an APK directly. The app becomes frozen at
whatever version they installed, forever, unless they go and get a new one.

That is the actual problem: not that updating is hard, but that **users
have no way of knowing an update exists.**

So you replace the only part you are missing — the announcement. The app
asks a server "what is the newest version?", compares it to itself, and
tells the user if they are behind. Everything else (downloading, installing)
is already handled by Android and the user's browser.

## 2. The whole mechanism in five sentences

1. Somewhere online, you keep a small note saying "the newest version is
   4, and here is where to download it."
2. Every Servio build knows its own version number, baked in at build time.
3. When the app starts, it reads the note and compares.
4. If the note's number is higher, it shows a dialog: what's new, and an
   Update button.
5. The button opens the download link; Android installs it over the top of
   the existing app.

That's it. There is no magic in HappyMod or any similar app — this is what
they do.

## 3. Why the update installs over the old one instead of failing

This is the part that would have quietly broken a month ago, and it is
worth understanding.

Android identifies an app by two things: its **application ID**
(`com.davedroids.servio`) and the **key it was signed with**. An update is
accepted only if *both* match the installed app. If either differs, Android
refuses with "App not installed" and the user's only option is to uninstall
first — losing nothing in Servio's case, since data lives in Firebase, but
confusing and a terrible experience.

Two things already done make this work:

- The application ID was moved off Flutter's placeholder
  (`com.example.servio`) to `com.davedroids.servio`.
- Builds are signed with your real upload key in `android/key.properties`,
  not the throwaway debug key Flutter generates.

**Keep that keystore safe and keep using it.** If you lose it, no build you
make afterwards can update any app already installed by anyone. There is no
recovery, no reset, no support line — the same key is what Google Play will
require later. `docs/STORE_RELEASE.md` covers where it lives.

## 4. Version numbers — the bit that is easy to get wrong

`pubspec.yaml` currently has:

```yaml
version: 1.0.0+1
```

Two separate things, and only one of them matters to the machinery:

- **`1.0.0`** — the *version name*. For humans. Shown in dialogs. Can be
  anything: "1.0.0", "1.2-beta", "Christmas release".
- **`+1`** — the *build number* (Android calls it `versionCode`). For
  machines. **Must be a whole number, and must increase with every single
  build you give to anyone.**

The comparison is done on the build number alone, never on the name. "1.10"
versus "1.9" is a trap if you compare names as text — as text, "1.10" sorts
*before* "1.9". Comparing integers avoids the whole class of bug.

Practical rule: **increment `+N` every time you build something you hand
out, even for a one-line fix.** Reusing a build number means users who
already have that number will never be offered the new one.

## 5. Where the "note" lives

A single Firestore document, `app_config/android`:

| Field | Example | What it's for |
|---|---|---|
| `latestBuildNumber` | `4` | Compared against the running app's build number |
| `latestVersionName` | `"1.1.0"` | Shown to the user |
| `downloadUrl` | `"https://github.com/.../app-release.apk"` | Where the Update button sends them |
| `releaseNotes` | `"Attendance now records…"` | Shown in the dialog so the update is worth tapping |
| `minimumBuildNumber` | `2` | Below this, the update is required rather than optional (see §7) |

Firestore rather than a file on the website for three reasons: you are
already using it, it is readable with one line of code the app already has
the plumbing for, and you can edit the fields by hand in the Firebase
console without a deploy. One extra read per app start is negligible
against the 50,000/day free allowance.

It needs a rules block allowing any signed-in user to read it and nobody to
write it — editing happens in the console, not from the app.

## 6. Where the APK lives — and why NOT on Firebase Hosting

**Do not host the APK on Firebase Hosting.** The APK is about **37 MB** and
the free Spark plan allows **360 MB of transfer per day**. That is **nine
downloads a day** before the quota is exhausted — and when it goes, it
takes *the whole website* with it until midnight Pacific. Ten testers
updating on the same morning would take Servio offline.

Use one of these instead:

**GitHub Releases (recommended).** Free, built for exactly this, no
meaningful bandwidth limit, keeps every past version, and gives a permanent
link per release. You upload the APK to a release, copy the link, paste it
into the Firestore field. It also gives you a changelog for free. The
repository can stay private, though the download link then requires a
GitHub login — for public testers, a public repo (or a public repo holding
only releases) is simpler.

**Google Drive.** Works, and is familiar. Two annoyances: Drive shows an
"unable to scan for viruses" interstitial for files this size, which looks
alarming to non-technical users, and the direct-download link format is
fiddly and occasionally changes.

Recommendation: GitHub Releases, and keep Firebase Hosting for the website
only.

## 7. Optional versus required updates

Two levels, because they solve different problems:

**Optional** (`latestBuildNumber` is higher): a dismissible dialog. The
user can tap "Later" and keep using the app. This is the normal case.

**Required** (their build is below `minimumBuildNumber`): a dialog that
cannot be dismissed, and the app does not proceed until they update.

Required updates exist for one specific situation worth understanding
clearly. Servio's permissions live in Firestore rules that are deployed
separately from the app. The attendance location work is a live example:
the rules now accept new fields, and old builds don't send them. That
direction is safe. But a future change could go the other way — rules that
*require* a field, with old builds that don't send it. Those users would see
check-ins simply failing, with no clue why, and no way to fix it.

`minimumBuildNumber` is the escape hatch for that: you raise it, and the
old clients stop guessing and tell their users exactly what to do. Use it
rarely — a forced update is hostile when it isn't necessary.

## 8. What Android will show the user, and what you cannot avoid

Be ready to explain this to testers, because it looks alarming and is
completely normal:

- **"Install unknown apps"** — the first time, Android asks the user to
  allow installs from whatever app opened the link (usually Chrome). They
  must grant it once, in system settings. You cannot skip this; it is the
  OS protecting them, and it is the price of not being on the Play Store.
- **Play Protect warning** — Android may warn that the app is unrecognised,
  because it has not been scanned by Play. "Install anyway" proceeds. This
  will happen to every build you distribute this way.
- **An install screen** — the user taps Install. **You cannot update
  silently.** Only the Play Store can do that. The app can prompt, download
  and hand off; the final tap is always the user's. This holds whether the
  browser downloads the file or Servio does it itself (§9).

None of this is a bug or a sign of something done wrong. It is what
sideloading is.

## 9. Downloading inside the app, with a progress bar

Two ways to get the APK onto the phone. Servio will do the second.

**Hand off to the browser.** The Update button opens the link, Chrome
downloads it, the user taps the finished file. Almost no code. The downside
is that the user leaves Servio and watches a browser download — it feels
like being dumped somewhere else mid-task, and if they miss the
notification the update is simply forgotten.

**Download inside the app (chosen).** Servio fetches the file itself and
shows a real progress bar, then hands the finished file to Android's
installer. The user never leaves the app. This is what makes it feel like a
real update rather than a link.

What that needs:

- The file is written to the app's **own private storage**, so no storage
  permission is involved and Android cleans it up with the app.
- A **`FileProvider`** declared in the manifest. Since Android 7 you cannot
  hand another app a raw file path; it has to be a content URI, and the
  installer is another app. This is pure configuration, but the install
  silently fails without it.
- The **`REQUEST_INSTALL_PACKAGES`** permission, which is what lets Servio
  ask Android to install a package at all.
- Handling the unhappy paths: connection lost halfway, no space left, a
  download that completes but is corrupt. A failed download must leave the
  app completely usable and simply offer to retry.

### The one real cost, and how it is handled

**Google Play does not allow an app distributed through Play to update
itself by any other means.** Publishing this feature in a Play release
risks rejection or removal, and `REQUEST_INSTALL_PACKAGES` is a sensitive
permission that draws extra review scrutiny on top.

This is not a reason to avoid it — it is a reason to put it behind a
switch. The feature is gated on a single flag in `AppConstants`, exactly
the way `profilePhotoUploadsEnabled` already gates profile photos:

- **Sideloaded builds** (what testers get today): on. Servio checks for
  updates and installs them.
- **Play builds** (once the $25 account exists): off. The whole update
  check is skipped, because Play does it properly.

One flag flipped per release channel, with no other code to remove. Nothing
is deleted if you later go to Play, and nothing has to be rebuilt if you
keep distributing APKs alongside it.

## 10. iPhone users cannot have this

Apple does not permit installing apps from outside the App Store or
TestFlight. Not with a link, not with a profile, not with a workaround —
apps distributed that way get their certificates revoked.

For iOS the options are the $99/year developer account (then TestFlight,
which has its own built-in update notifications) or the website, which works
well in mobile Safari and can be added to the home screen.

So this feature is Android-only, and the config document is named
`app_config/android` to leave room for an iOS story later.

## 11. The release routine once this is built

```bash
# 1. Bump the build number in pubspec.yaml: 1.0.0+1 → 1.1.0+2
# 2. Build
flutter build apk --release \
  --target-platform android-arm,android-arm64 \
  --dart-define-from-file=env.local.json

# 3. Upload build/app/outputs/flutter-apk/app-release.apk to a new
#    GitHub Release, and copy its download link.

# 4. In the Firebase console, edit app_config/android:
#      latestBuildNumber: 2
#      latestVersionName: "1.1.0"
#      downloadUrl: <the link>
#      releaseNotes: "What changed"
```

Everyone who opens the app after that is told. No store, no review, no
waiting.

**Order matters when a release includes rules changes:** deploy the rules
*before* publishing the APK link, so nobody updates into an app whose
permissions have not landed yet.

## 12. What building this involves

| Piece | Work |
|---|---|
| `package_info_plus` dependency | Reads the running app's own build number |
| An update service | Reads the config document, compares, decides none/optional/required |
| A downloader | Fetches the APK to private storage, reporting progress |
| A `FileProvider` + `REQUEST_INSTALL_PACKAGES` | Lets Servio hand the finished file to Android's installer |
| A dialog | Version, release notes, a progress bar while downloading, Update and (if optional) Later |
| A startup check | Runs once per app start, after sign-in |
| An `AppConstants` flag | Off for Play builds (§9) |
| Rules | A read-only `app_config` block |
| The config document | Created by hand in the console |
| Tests | The comparison logic, which is where the real bugs live |

Roughly a day with the in-app download, half that with a browser handoff. The comparison logic gets unit tests — same reasoning
as the attendance verdict logic: it's pure arithmetic on three numbers and
every edge case (equal, behind, below minimum, missing field, malformed
document) can be tested without a phone or a network.

**Failure must be silent.** If the config document can't be read — offline,
rules misconfigured, document deleted — the app logs it and carries on.
Nobody should ever be blocked from checking in because an update check
failed.

## 13. Honest limitations

- **No automatic background checking.** The check happens when the app
  starts. Someone who leaves Servio open for a week is not interrupted.
- **No gradual rollout.** Everyone is offered the update at once. There is
  no "release to 10% first", so a broken build reaches everyone who opens
  the app.
- **No way to force an uninstall or roll back.** If you ship a bad build,
  you fix it forward with another build and a higher number.
- **The user can always decline** an optional update, indefinitely.
- **The final install tap is always the user's**, however good the progress
  bar is. Android does not allow otherwise outside the Play Store.
- **The feature has to be switched off in Play builds** (§9), so for a
  period you may be maintaining two channels that update differently.
