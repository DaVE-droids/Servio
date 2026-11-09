# Permissions

Every permission Servio asks for, where it is declared, and how to add or
remove one. Written so you can answer an app-store reviewer or a user who
asks "why does it want that?".

---

## What Servio asks for today

| Platform | Permission | When it's asked | Why |
|---|---|---|---|
| Android | `INTERNET` | Never asked — granted at install | Firebase, address search, opening maps |
| Android | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Only when a student taps "Check in" on the attendance screen | Recording how far the check-in was from the company address |
| iOS | Location in use (`NSLocationWhenInUseUsageDescription`) | Only when a student taps "Check in" | Same |
| Web | Geolocation (browser prompt) | Only when a student taps "Check in" | Same |
| Android | `REQUEST_INSTALL_PACKAGES` | Never prompted; Android shows its own install screen when the user taps Update | Installing an update the app downloaded (see `docs/APP_UPDATES.md`) |
| iOS | Camera (`NSCameraUsageDescription`) | Only when someone taps "Take a photo" for their profile picture | Profile photo |
| iOS | Photo library (`NSPhotoLibraryUsageDescription`) | Only when someone chooses an existing photo | Profile photo |
| Web | Nothing else | — | The file picker needs no permission |

That's the whole list. Servio asks for **no contacts, no microphone, no
background access, and no notification permission** (push notifications
aren't built yet — see "If you add push notifications").

Location is **foreground only**: it is read at the moment a student taps
check in, and never while the app is in the background or closed. A student
who refuses it can still check in — the record is simply saved without a
location and shows as "Location not confirmed".

Profile photo uploads are currently switched off in
`AppConstants.profilePhotoUploadsEnabled` because Cloud Storage needs the
Blaze plan, so in practice the camera and photo prompts don't appear yet.

### Permissions Servio deliberately avoids

- **Android camera (`CAMERA`)**: taking a photo hands off to the phone's
  own camera app, which doesn't need the permission. Declaring it would
  mean asking users for something we don't need.
- **Android storage / photos (`READ_MEDIA_IMAGES`)**: choosing a photo uses
  Android's system photo picker, which returns only the file the user
  picked.
- **Storage and media permissions for the updater.** The `open_filex`
  package would have merged `READ_EXTERNAL_STORAGE` and three
  `READ_MEDIA_*` permissions into the manifest for features Servio never
  uses. Writing the install handoff directly (thirty lines of Kotlin in
  `MainActivity.kt`) avoids all four: the update is written to the app's own
  cache directory, which needs no permission at all.
- **Background location** (`ACCESS_BACKGROUND_LOCATION`): Servio never
  tracks where anyone is between check-ins. Google Play and Apple both
  require a separate, heavily scrutinised justification for it, and
  attendance does not need it.
- **Android camera (`CAMERA`)** and **storage**: see above.

---

## Where each one is declared

| File | What's in it |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `INTERNET`, the `<queries>` block (which other apps Servio may hand off to: web links, maps, the camera app), `allowBackup="false"` |
| `ios/Runner/Info.plist` | The two usage descriptions (the exact sentences users see), plus `ITSAppUsesNonExemptEncryption` |
| `ios/Runner/PrivacyInfo.xcprivacy` | Apple's privacy manifest: what Servio collects and that it doesn't track |
| `android/app/src/main/res/xml/servio_file_paths.xml` | Limits the app's `FileProvider` to the cache directory, so the only file it can ever share is a downloaded update |
| `firebase.json` → `Permissions-Policy` header | Turns camera, microphone, payment, and USB **off** for the website, and allows geolocation for Servio's own pages only (`geolocation=(self)`) |

The iOS sentences are what appear in the system prompt, word for word.
Keep them specific ("only when you choose to take a new profile photo") —
Apple rejects vague ones like "This app needs camera access".

---

## Adding a permission

1. **Check you need it.** Many features hand off to another app instead
   (camera app, maps, file picker), which needs no permission.
2. **Declare it**: Android in `AndroidManifest.xml`, iOS with a
   `NS…UsageDescription` in `Info.plist` written in plain language.
3. **Ask at the right moment** — when the person taps the thing that needs
   it, never on launch, and explain why first if it isn't obvious.
4. **Handle refusal.** The app must still work: show what's possible and
   how to change their mind ("You can allow access in your phone's
   Settings"). The profile photo picker already does this.
5. **Update** `web/privacy.html`, `ios/Runner/PrivacyInfo.xcprivacy`, the
   Play "Data safety" form, the App Store "App Privacy" answers, and this
   file.

## Removing one

Delete the declaration, remove the code that used it, and update the same
five places. Stores flag permissions you declare but never use.

---

## When someone says the app "won't let it in"

1. **Which platform?** Web has no OS prompts — a blocked camera there is a
   browser site-setting.
2. **Was it declined once?** iOS and Android only ask once. After that the
   prompt never reappears and the picker fails silently; the user must go
   to Settings → Servio and turn it on. Servio shows a message saying
   exactly that.
3. **Is it an MDM/managed device?** University-managed phones can block the
   camera outright; nothing in the app can override that.
4. **iOS build failing with a "missing usage description" crash** means the
   `Info.plist` key was removed — the app terminates the moment that API is
   touched.

---

## If you add push notifications (needs Blaze)

- **Android 13+**: `POST_NOTIFICATIONS` in the manifest *and* a runtime
  request. Ask after the user has seen why notifications help, not on
  first launch.
- **iOS**: request authorisation through `firebase_messaging`, add the Push
  Notifications capability and an APNs key in the Apple Developer portal.
- **Web**: the browser prompt must follow a tap, not a page load.
- Update this file, the privacy policy, and the store data forms.

## Location check-in (built)

A check-in stores the device's coordinates, the reading's margin of error,
the distance to the company address, and whether Android reported the
position as mocked. `LocationCheck` turns those into one of three verdicts
— at the workplace, away from it, or not confirmed — shown to both the
student and their lecturer.

Things to keep in mind when changing it:

- **Refusing is not failing.** `LocationService` returns an empty reading
  instead of throwing when location is off, permission is denied, or the
  fix times out. Check-in still succeeds. Never make the permission a
  condition of attendance: a phone with a broken GPS would otherwise cost a
  student their record.
- **A vague reading is not evidence.** Anything less accurate than
  `AppConstants.attendanceMaxLocationAccuracyMetres` is treated as no
  reading at all rather than used to place someone outside the fence.
- **The web needs the header.** `firebase.json` sets
  `Permissions-Policy: geolocation=(self)`. Setting it back to
  `geolocation=()` silently disables check-in locations on the website —
  the browser blocks the API before Servio ever asks.
- **Honest limits.** The distance is calculated on the device and sent up
  with the record, so the security rules can only check its shape, not its
  truth (rules have no trigonometry, and there is no server). A student who
  installs a mock-location app or calls Firestore directly can write
  whatever they like. The mocked flag catches the easy case; genuine
  verification needs the employer sign-off in the roadmap.
- **Privacy.** A single coordinate per workday, visible only to that
  student, their assigned lecturer, and coordinators. If that scope ever
  widens, `web/privacy.html` and `ios/Runner/PrivacyInfo.xcprivacy` must
  say so.
