# Updating the app without an app store

**Status: built 2026-11-07, not yet verified on a device.** The code is in
`lib/features/updates/`. Two things remain before anyone can use it: the
`app_config/android` document has to be created (§5), and a release APK has
to be built and installed on a real phone, which has not happened yet
(§14).

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
into the Firestore field. It also gives you a changelog for free. §11 is
the step-by-step.

**The repository has to be public for this to work.** A private
repository's release assets need an `Authorization` header, and Servio's
downloader sends no credentials — it would get a 401 or a login page where
it expected an APK, and fail with "Download failed". `DaVE-droids/Servio`
is public, so this is already satisfied; if it is ever made private again,
the in-app updater stops working that same day and the APK has to move
somewhere else.

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

What that needs, and how each part was built:

- The file is written to the app's **own cache directory**, so no storage
  permission is involved and Android reclaims it with the app. It is
  written under a `.part` name and renamed only when complete, so an
  interrupted download can never be handed to the installer as though it
  were whole.
- A **`FileProvider`** in the manifest, because since Android 7 you cannot
  hand another app a raw file path — it must be a content URI, and the
  installer is another app. Scoped by
  `android/app/src/main/res/xml/servio_file_paths.xml` to the cache
  directory alone, so nothing else is ever exposed.
- The **`REQUEST_INSTALL_PACKAGES`** permission, which is what lets Servio
  ask Android to install a package at all.
- The unhappy paths: a download that ends early is deleted and reported, a
  non-200 response is an error, and the dialog offers "Try again" while the
  rest of the app stays usable.

### Why there is Kotlin in this feature

The handoff to the installer is about thirty lines in
`android/app/src/main/kotlin/.../MainActivity.kt`, called from Dart over a
method channel, rather than a package from pub.dev.

`open_filex` was tried first and removed. Despite a recent publish date its
Android build pins **Android Gradle Plugin 8.1.0** in its own buildscript
and uses `compileSdkVersion`, `lintOptions` and `minSdkVersion 16` — DSL
that AGP 9 has removed, while Servio is on AGP 9.0.1 and Gradle 9.1. It
also merges four media permissions into the manifest that Servio has no use
for. The alternatives (`apk_manager`, `android_package_installer`,
`flutter_app_installer`, and a fork of the last one) were variously
pre-release, unmaintained, or wanted `READ_EXTERNAL_STORAGE`.

For the one call in the app that installs software onto someone's phone,
thirty readable lines we own beat a dependency like that. There is nothing
clever in it: resolve a content URI, grant read access, fire
`ACTION_VIEW`.

### What the progress bar actually measures

The bar is driven by the `Content-Length` the server sends. GitHub Releases
sends one, so it fills properly. A host that doesn't gets an indeterminate
bar and the word "Downloading…" rather than an invented percentage.

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

## 11. The release routine, step by step

### What a GitHub Release actually is

Three things bundled together:

1. **A tag** — a permanent name for one commit, like `v1.0.1`. It is how
   you know months later which source code produced a given APK.
2. **A title and notes** — the changelog, written by you.
3. **Assets** — files attached to the release. This is the part that
   matters here: an uploaded APK gets a permanent public download link.

The link is built from the repository, the tag, and the filename, so you
can predict it before you even upload:

```
https://github.com/DaVE-droids/Servio/releases/download/v1.0.1/app-release.apk
```

That URL answers with a **302 redirect** to GitHub's file storage rather
than the file itself. Servio's downloader follows redirects (`package:http`
does so by default, up to five hops), so this is handled — but it is the
usual reason a hand-rolled downloader fails on its first real release, and
worth remembering if the progress bar ever sits at zero.

Nothing about a release is private or reviewed: it is live the moment you
publish it, and anyone with the link can download it. There is no store, no
review queue, and no waiting.

### The routine

```bash
# 1. Bump the version in pubspec.yaml: 1.0.0+1 → 1.0.1+2
#    The +N must increase or Android refuses to install over the old app.

# 2. Build
flutter build apk --release \
  --target-platform android-arm,android-arm64 \
  --dart-define-from-file=env.local.json

# 3. Commit the work, so the tag points at the code that is in the APK.

# 4. Create the release and attach the APK in one command
gh release create v1.0.1 \
  build/app/outputs/flutter-apk/app-release.apk \
  --title "Servio 1.0.1" \
  --notes "What changed, in the words a student would use."

# 5. Confirm the link works with no credentials — this is the exact
#    request the app makes. Expect "HTTP/2 200" and a content-length of
#    roughly 40000000.
curl -sIL \
  https://github.com/DaVE-droids/Servio/releases/download/v1.0.1/app-release.apk \
  | grep -i "^HTTP/\|^content-length"

# 6. In the Firebase console, edit app_config/android:
#      latestBuildNumber: 2          (number)
#      latestVersionName: "1.0.1"    (string)
#      downloadUrl: <the link from step 5>
#      releaseNotes: "What changed"
#      minimumBuildNumber: 1         (number — see §7)
```

Everyone who opens the app after step 6 is told.

**Keep the filename stable.** `app-release.apk` is what `flutter build apk`
produces and what the predictable URL above assumes. If you ever switch to
`--split-per-abi`, there is a separate APK per processor type and one
`downloadUrl` can no longer serve every phone — that is a real change, not
a detail.

**A tag can only be made from a commit.** If the working tree has
uncommitted changes, `gh release create` still tags the last commit, and
the tag will point at code that is *not* what the APK contains. Commit
first (step 3), or the tag quietly lies.

**Order matters when a release includes rules changes:** deploy the rules
*before* publishing the APK link, so nobody updates into an app whose
permissions have not landed yet.

## 12. What building this involves

| Piece | Work |
|---|---|
| File | What it does |
|---|---|
| `lib/features/updates/domain/update_decision.dart` | **The decision.** Compares build numbers; returns none, optional or required. Pure logic. |
| `lib/features/updates/data/models/app_update_config.dart` | The config document, parsed so that a hand-typed mistake cannot crash the app. |
| `lib/features/updates/data/services/app_update_service.dart` | Reads the document, downloads the build with progress, calls the installer channel. |
| `lib/features/updates/presentation/providers/update_providers.dart` | The one-per-launch check and the download state. |
| `lib/features/updates/presentation/widgets/update_dialog.dart` | The dialog, with the progress bar. |
| `lib/features/updates/presentation/widgets/update_prompt.dart` | Shows it once per launch, from inside the signed-in shell. |
| `android/app/src/main/kotlin/.../MainActivity.kt` | The install handoff (§9). |
| `android/app/src/main/res/xml/servio_file_paths.xml` | Limits the FileProvider to the cache directory. |
| `test/update_decision_test.dart` | 14 tests on the comparison and the parsing. |

Dependencies added: `package_info_plus` (reads the running build number),
`path_provider` (finds the cache directory). The download uses the `http`
package already in the project; no HTTP client was added.

**Everything fails quietly.** Being unable to check for an update — offline,
no document, rules misconfigured, a malformed field — resolves to "no
update" and is logged, never surfaced. Nobody should be blocked from
checking in because an update check failed. The comparison logic gets unit tests — same reasoning
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
- **The download starts over if it is interrupted.** There is no resume;
  the partial file is discarded. For a 37 MB file on a poor connection
  that is a real annoyance, and worth revisiting if testers hit it.

## 14. Before this can be used

1. **Create the config document.** Firebase console → Firestore → start a
   collection `app_config`, document ID `android`, with the five fields in
   §5. Until it exists the app checks, finds nothing, and carries on
   silently — which is why this is safe to ship ahead of the document.
2. ~~**Build a release APK and install it on a real phone.**~~ **Done
   2026-11-09.** A release APK of build 1 was built and sideloaded onto an
   Android phone, and it installed over the previous build without asking
   for an uninstall first — which already proves the signing key is
   consistent (§3), the failure that would otherwise have surfaced at the
   worst moment. Verified by unpacking that APK that it contains both the
   Kotlin install channel and the Dart update code, so **the phone in hand
   can already receive an update** — the updater does not have to be
   sideloaded in before it can be tested.
3. **Then test the whole path**: publish build 2 per §11, set
   `latestBuildNumber: 2`, reopen the app, and confirm the dialog appears,
   the bar fills, and Android's install screen opens and updates in place.
   Still entirely unwalked: the download, the progress bar, the
   FileProvider hand-off, and the install prompt. The Kotlin in
   `MainActivity.kt` has compiled but has never run.
