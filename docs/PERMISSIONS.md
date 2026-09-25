# Permissions

Every permission Servio asks for, where it is declared, and how to add or
remove one. Written so you can answer an app-store reviewer or a user who
asks "why does it want that?".

---

## What Servio asks for today

| Platform | Permission | When it's asked | Why |
|---|---|---|---|
| Android | `INTERNET` | Never asked — granted at install | Firebase, address search, opening maps |
| iOS | Camera (`NSCameraUsageDescription`) | Only when someone taps "Take a photo" for their profile picture | Profile photo |
| iOS | Photo library (`NSPhotoLibraryUsageDescription`) | Only when someone chooses an existing photo | Profile photo |
| Web | None | — | The file picker needs no permission |

That's the whole list. Servio asks for **no location, no contacts, no
microphone, no background access, and no notification permission** (push
notifications aren't built yet — see "If you add push notifications").

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
- **Location**: the company's map position comes from the address the
  student searches for, not from the device. (Check-in records a time, not
  a place. The model has coordinate fields that were never filled — see
  "If you add GPS check-in".)

---

## Where each one is declared

| File | What's in it |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `INTERNET`, the `<queries>` block (which other apps Servio may hand off to: web links, maps, the camera app), `allowBackup="false"` |
| `ios/Runner/Info.plist` | The two usage descriptions (the exact sentences users see), plus `ITSAppUsesNonExemptEncryption` |
| `ios/Runner/PrivacyInfo.xcprivacy` | Apple's privacy manifest: what Servio collects and that it doesn't track |
| `firebase.json` → `Permissions-Policy` header | Turns camera, microphone, geolocation, payment, and USB **off** for the website |

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

## If you add GPS check-in

`AttendanceModel` has latitude/longitude fields that were never filled.
Doing it properly means: the `geolocator` package;
`NSLocationWhenInUseUsageDescription` on iOS; `ACCESS_FINE_LOCATION` and
`ACCESS_COARSE_LOCATION` on Android; a screen explaining why before the OS
prompt (SRS NFR-PRIV-003); and a fallback when someone declines — check-in
must still work, or students can be locked out of their own attendance.
