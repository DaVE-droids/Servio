# Location Services — Country/State selection, address search, and navigation

This file explains the full "where is this internship, and how do I get there" feature: picking a Country and State, searching for and picking a real company address, and the lecturer's "Navigate" button. It's a companion to `docs/GEOCODING.md` (which explains the earlier, narrower address-geocoding work this feature replaces) — read that one first if you haven't, since some concepts (like *what geocoding even is*) aren't repeated here.

Like `docs/GEOCODING.md`, this is a teaching document for you to revisit, not a changelog — see `docs/CHANGELOG.md` for the dated "what changed and why" record.

---

## 1. What this feature actually does

When a student submits a placement, they now:
1. Pick a **Country** from a dropdown (defaults to Nigeria).
2. Pick a **State** from a second dropdown, whose options depend on the chosen country.
3. Type into a **Company Address** field and get a live list of real, matching addresses to pick from — like searching for a place in any maps app. Picking one fills in the field and captures that address's exact coordinates immediately.

Once approved and assigned, a lecturer sees each assigned student's company on their Assigned Students screen, with a **Navigate** button that opens Apple/Google Maps with directions straight to that company.

This replaces the earlier design (documented in `docs/GEOCODING.md`) where the student typed a free-text address and the app tried to blindly resolve it to coordinates *after* submission. That approach had a real reliability problem — testing found it failed for a Nigerian address in the iOS Simulator — so this feature closes that gap two ways: by never accepting an address the system can't already find (the student can only submit a *real, matched* address), and by adding structured Country/State data that doesn't depend on address-matching working at all.

## 2. Why blind geocoding wasn't good enough

`docs/GEOCODING.md` covers this in depth, but the short version: typing a free-text address and hoping a geocoding service can match it afterward has no guardrail — if the match fails, you find out only after the student has already submitted, and you're left with either broken coordinates or a rejected submission. Search-and-pick flips this around: the student can only pick from addresses the system has *already confirmed it knows about*, so a bad match is caught immediately, during typing, not after.

## 3. Country and State — how they work

**Package:** [`country_state_city`](https://pub.dev/packages/country_state_city), added via `flutter pub add country_state_city`.

This is a fully offline package — it ships its own bundled JSON data (every country, and every state/province within each country) and does no network calls at all. That's why it needs no API key and never fails due to connectivity.

```dart
import 'package:country_state_city/country_state_city.dart' as csc;

final countries = await csc.getAllCountries();       // every country
final states = await csc.getStatesOfCountry('NG');    // Nigeria's states only
```

It's imported with the `csc` prefix in `student_internship_screen.dart` specifically because the package's `State` class would otherwise collide with Flutter's own `State<T>` (the base class every `StatefulWidget` uses) — without the prefix, the compiler wouldn't know which `State` you meant.

**Where it's wired up:** `lib/features/internship/presentation/screens/student_internship_screen.dart`
- `_loadCountries()` runs once when the screen opens, populates a `Country` dropdown, and defaults the selection to Nigeria (`isoCode == 'NG'`) since that's the overwhelmingly common case — the student can change it for an abroad placement.
- `_loadStates(countryIsoCode)` runs whenever the Country dropdown changes, populating the State dropdown with only that country's states, and clearing any previously selected state (since a state from the old country wouldn't make sense anymore).

**Where it's stored:** `InternshipModel`/`InternshipSubmissionRequest` gained a new `country` field (a plain string, the country's display name, e.g. `"Nigeria"`) alongside the existing `state` field, which now comes from the same structured dropdown instead of being freely typed. `firestore.rules` was updated to require and type-check `country` the same way every other required field is checked.

**Why this actually matters (not just tidiness):** before this, `state` was a free-text field — "Lagos", "lagos", "Lagos State" were all valid, different strings. That's a real problem for anything that groups or filters by location later (a coordinator dashboard, a report, assigning lecturers to a cluster of students in one area) — free text fragments your data. A dropdown guarantees every student's state is one of a fixed, consistent set of values. It also fixes a real gap: there was no `country` field *at all* before, so a student doing an internship outside Nigeria couldn't be represented correctly.

## 4. Address search — how it works

**Provider:** [LocationIQ](https://locationiq.com), specifically its [Autocomplete API](https://docs.locationiq.com/reference/autocomplete). LocationIQ is built on OpenStreetMap data and offers a free tier (a few thousand requests/day) that requires only an email signup — no credit card, no billing account.

### Why LocationIQ and not something else

We considered a few free options, described in `docs/GEOCODING.md`'s companion discussion:
- **Google Places Autocomplete** — the best UX of any option, but it's a paid product requiring a funded Google Cloud billing account. Not usable right now.
- **OpenStreetMap's own Nominatim service** — free and needs no signup at all, but its usage policy *explicitly forbids* using it for autocomplete/type-ahead search (only one-shot lookups), so building this feature on it directly would violate its terms.
- **Photon** (by komoot) — also free, built for autocomplete, but it's a best-effort public demo with no uptime guarantee — fine for a hobby project, riskier for something people rely on.
- **LocationIQ** — free tier, explicitly permits autocomplete, documented rate limits rather than "best effort." This is what's implemented.

**Honest limitation:** no free geocoder — LocationIQ, Nominatim, or even Google's paid one — will find every address perfectly, especially in areas without standardized street addressing. This should meaningfully improve on what we saw fail during testing, but "search finds nothing" will still happen sometimes for genuinely obscure addresses. There's currently no manual-entry fallback for that case — see §8.

### The API key

LocationIQ calls it an "Access Token" in its dashboard (same thing as an API key — a secret string that authenticates your requests). It's read in code via:

```dart
const _locationIqAccessToken = String.fromEnvironment('LOCATIONIQ_ACCESS_TOKEN');
```

`String.fromEnvironment` is a Dart compile-time constant that's empty unless supplied at build/run time — the token is **never** hardcoded into any file, so it can't accidentally get committed to git. To run the app with it:

```bash
flutter run --dart-define=LOCATIONIQ_ACCESS_TOKEN=your_token_here
```

or for a release build:

```bash
flutter build ios --dart-define=LOCATIONIQ_ACCESS_TOKEN=your_token_here
```

If you ever need a new token (the current one was pasted into an AI chat session, which is low-risk for a free-tier dev key on an unreleased app, but you can regenerate it anytime from your LocationIQ dashboard for a clean slate), just swap the value passed to `--dart-define` — no code changes needed.

### The actual implementation

**`lib/core/services/maps_service.dart`** — same `MapsService` class from `docs/GEOCODING.md`, extended with a new method:

```dart
Future<Result<List<AddressSuggestion>>> searchAddress(
  String query, {
  String? countryCode,
}) async {
  // calls https://api.locationiq.com/v1/autocomplete
  // returns a list of AddressSuggestion, each already carrying
  // its own displayName, latitude, and longitude
}
```

`AddressSuggestion` is a small class (also in `maps_service.dart`) holding exactly what's needed: the human-readable name to show, and the coordinates to store. Critically, **picking a suggestion is the entire geocoding step** — there's no separate "now resolve this to coordinates" call afterward, because the suggestion already has them. This is why `SubmitInternshipUseCase` went back to being a plain pass-through (compare it to `docs/GEOCODING.md`'s version, which had to call `MapsService.geocodeAddress()` before submitting) — the resolution already happened, interactively, while the student was picking an address.

**`lib/core/widgets/address_search_field.dart`** — a reusable widget wrapping a text field with live suggestions:
- Debounces input (waits 400ms after the student stops typing) before calling `searchAddress()`, so it's not firing a network request on every keystroke.
- Won't search until at least 3 characters are typed (short queries return junk and waste requests).
- Renders suggestions as a simple list directly below the field; tapping one fills the field and reports the pick via an `onSelected` callback.
- Takes an optional `countryCode` parameter, passed from the screen's selected Country dropdown value, so LocationIQ only returns addresses in that country (this is what makes "abroad" placements work correctly instead of getting Nigeria-biased results).
- Has an `onTextEdited` callback — if the student edits the field *after* picking a suggestion, the parent screen uses this to clear the stored selection, so a stale, no-longer-matching coordinate pair can never be submitted alongside newly-typed text.

**`lib/features/internship/presentation/screens/student_internship_screen.dart`** — holds the picked `AddressSuggestion?` in `_selectedAddress`. Validation (`_validate()`) requires it to be non-null before the form can be submitted — "Please select an address from the suggestions" — matching the "must pick a real match" principle from §2.

## 5. Navigate — how it works, and why it needs no API key at all

**`lib/features/lecturer/presentation/screens/lecturer_assigned_students_screen.dart`** — each assigned student's card has a "Navigate" button:

```dart
AppButton(
  label: 'Navigate',
  onPressed: () => ref.read(mapsServiceProvider).launchNavigation(
    latitude: internship.companyLatitude,
    longitude: internship.companyLongitude,
  ),
)
```

**`MapsService.launchNavigation()`** builds a URL and hands it to the OS:

```dart
Future<bool> launchNavigation({required double latitude, required double longitude}) {
  final uri = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? Uri.parse('https://maps.apple.com/?daddr=$latitude,$longitude')
      : Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
        );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

This is the single most important thing to understand about this whole feature: **opening a maps app for directions is not the paid Google Maps API.** The paid API is for things like embedding a live interactive map *inside* Servio itself, or calling Google's servers programmatically to search/geocode. This is neither — it's a plain URL (Google publishes this exact format specifically so any app can deep-link into Maps for free: [Google Maps URLs documentation](https://developers.google.com/maps/documentation/urls/get-started); Apple's `maps.apple.com` format is the equivalent for Apple Maps). The `url_launcher` package (`flutter pub add url_launcher`) just asks the OS "please open whatever app handles this URL."

**Why two different URLs, not just one:** the first version of this used Google's URL unconditionally. On iOS, that opens Google's *web* result (since the native Google Maps app usually isn't installed — it's not a system app), and that web page's own "Start" button then tries to hand off to the native Google Maps app via its own custom URL scheme. If that app genuinely isn't installed (true on every iOS Simulator, and true on plenty of real iPhones too), the handoff fails with a confusing "Safari cannot open the page because the address is invalid" error — found exactly this way, hands-on, in the Simulator. Apple Maps, by contrast, is a system app guaranteed present on every iPhone and every Simulator, so routing iOS specifically to `maps.apple.com` means the in-app "Start" button always has a real app to open. Android keeps the Google URL since Google Maps is close to universal there. `kIsWeb`/`defaultTargetPlatform` (from `package:flutter/foundation.dart`) are used for this check rather than `dart:io`'s `Platform`, since `dart:io` isn't available when this code is compiled for web — this app also ships a web build (for coordinators, who use Servio from a laptop browser rather than a phone), and `dart:io` would break that build entirely.

## 6. If you want to build something similar yourself

The pattern here is the same one from `docs/GEOCODING.md` §5, applied twice more:
1. Add one method to the relevant `XyzService` class (`searchAddress`, `launchNavigation`) — never let the UI import the underlying package/API directly.
2. Return `Result<SomeAppType>` (or in `launchNavigation`'s case, just a plain `bool`/`Future<void>`, since there's nothing meaningful to fail into a `Result` for a fire-and-forget OS handoff).
3. Keep secrets (API keys/tokens) out of source entirely — `String.fromEnvironment` + `--dart-define`, never a hardcoded string.
4. Build reusable UI (`AddressSearchField`) as its own widget in `lib/core/widgets/`, not copy-pasted into each screen that needs it.

## 7. Switching to Google's paid services later

If you eventually fund a Google Cloud billing account, two independent upgrades become available — you don't have to do both at once:

**Address search → Google Places Autocomplete API.** Only `MapsService.searchAddress()` needs to change — same pattern as `docs/GEOCODING.md` §6 for the geocoding swap. You'd call Google's Places Autocomplete endpoint instead of LocationIQ's, map its response shape into the same `AddressSuggestion` class, and nothing in `AddressSearchField` or `student_internship_screen.dart` needs to know the difference.

**Navigate → embed a live map (optional, bigger change).** The current "open an external maps app" approach already works great and costs nothing — you'd only want the `google_maps_flutter` SDK if you specifically wanted a map *rendered inside Servio itself* (e.g., a visual pin-drop address picker in place of the search field, or a live map on the lecturer's screen). That's a materially bigger addition (a new widget, a Google Maps API key restricted to your app, platform-specific setup in `AndroidManifest.xml`/`AppDelegate.swift`) — worth its own dedicated pass rather than a quick swap, if you ever want it.

## 8. Known limitations / not built

- **No manual fallback if search finds nothing.** If LocationIQ genuinely can't find an address (rare, but possible for very informal/rural locations), the student currently has no way to submit anyway. Worth revisiting if this turns out to block real students.
- **Country/State aren't denormalized into `attendance`, `logbook_entries`, or `supervision_reports`** the way `state` alone already was for some of those collections (per the DDS's field-denormalization table). Only `internships` gained the new `country` field. This was a deliberate scope decision to keep this change focused — extending it further is straightforward if a future feature needs country-level filtering on those other collections too.
- **The Navigate button only exists on the lecturer's Assigned Students screen.** The full Supervision module (visit reports, etc. — PIG/Roadmap Phase 5) isn't built yet; this button was added as a small, immediately useful piece of that future work, not the whole thing.
- **"Directions Not Available" in the iOS Simulator is expected, not a bug.** Hands-on testing confirmed the deep link itself is correct — Apple Maps opens directly (no Safari involved) and correctly resolves the destination coordinate to its real place name (e.g. "Ikeja City Mall", not raw numbers), proving both the URL and the coordinate are right. But the Simulator's own route-calculation service frequently refuses to compute directions at all ("Directions are not available from this location"), regardless of how reasonable the origin/destination are — this is a known limitation of MapKit routing specifically inside the Simulator, which lacks the device-level service authentication a real iPhone has. This should work correctly on a real device; it just couldn't be confirmed end-to-end without one.

## 9. Testing this yourself

1. Run the app with your LocationIQ token: `flutter run --dart-define=LOCATIONIQ_ACCESS_TOKEN=your_token`.
2. As a student, start a placement submission. Confirm the Country dropdown defaults to Nigeria and the State dropdown populates once a country is picked.
3. Type a few characters of a real company address into Company Address — after a brief pause, a list of suggestions should appear. Pick one and confirm it fills the field.
4. Try submitting without picking a suggestion (just typing and leaving it) — you should get "Please select an address from the suggestions," not a silent bad submission.
5. Submit, get it approved and assigned to a lecturer (via the coordinator/assignment flow from earlier phases), then log in as that lecturer and confirm the company's Navigate button opens Maps with the correct location.
