# Geocoding — what it is, and how Servio uses it

This file exists so you (not a future AI session) can understand, revisit, and edit the geocoding feature yourself. It's a teaching document, not a changelog — for the "what changed and why" record, see `docs/CHANGELOG.md`.

---

## 1. What is geocoding?

**Geocoding** is the process of turning a human-readable address (`"14 Adeola Odeku St, Victoria Island, Lagos"`) into geographic coordinates (`latitude: 6.4281, longitude: 3.4219`) that a computer can actually do math with — measure distance, drop a pin on a map, open turn-by-turn navigation, etc.

- **Forward geocoding**: address → coordinates. This is what Servio needs (student types a company address, we need coordinates to store).
- **Reverse geocoding**: coordinates → address. The opposite direction (e.g. "what's the address at my current GPS location?"). Servio doesn't use this yet, but the same package supports it if a future feature needs it (see §5).

Every geocoding provider works the same way under the hood: it has a huge database of addresses/places mapped to coordinates (built from postal data, satellite imagery, business listings, etc.), and it does fuzzy matching — "Victoria Island, Lagos" and "Victoria Island Lagos Nigeria" will usually resolve to the same or a very close point, even though the strings don't match exactly.

## 2. Why does this need a "service" at all — why not just hardcode coordinates?

A student can't be expected to know their internship company's exact latitude/longitude — nobody knows that off the top of their head. The only realistic input a student can type is the address itself. So the app has to do the address → coordinates conversion *for* them, automatically, at submission time.

## 3. The two ways to do this, and why we picked the free one

There are two categories of geocoding service:

1. **A cloud API you call over HTTP** (e.g. Google's Geocoding API). You send it an address string, it sends back JSON with coordinates. This requires an API key, a Google Cloud **billing account** (even though there's a free monthly quota, Google requires a card on file to unlock the API at all), and a network request every time.
2. **On-device / native geocoding** built into the phone's own operating system. iOS ships with `CLGeocoder` (part of Apple's CoreLocation framework) and Android ships with its own `Geocoder` class. Both do the exact same address→coordinates job, using Apple's or Google's respective map data, but **entirely on-device, for free, with no API key and no billing account.**

We hit a wall trying option 1: Google requires a billing account to be linked before the Geocoding API will respond to any request at all, and there was no funded billing account available. Rather than provision a Google Maps "Demo Key" (an unofficial workaround not meant for production use, with no reliability guarantee), we went with option 2: Flutter's [`geocoding`](https://pub.dev/packages/geocoding) package, which is a thin Dart wrapper around the native `CLGeocoder`/`Geocoder` APIs. It costs nothing, needs no API key, and needs no location permission (forward geocoding an address string isn't "using the device's location" — that permission is only needed for *reverse* geocoding the phone's live GPS position, which we don't do).

The tradeoff: native geocoding's address database is generally good for well-known places and formatted addresses, but can be less consistent than Google's cloud service for obscure or malformed addresses. If that ever becomes a real problem (e.g. students in a pilot report their companies aren't being found), that's the signal to consider paying for Google's API — see §6 for exactly how to switch.

## 4. How it's implemented in this codebase

### 4.1 Where the logic lives: `MapsService`

`lib/core/services/maps_service.dart` is the **only** place that knows *how* geocoding is done. Every other layer of the app (the use case, the repository, the UI) just calls `MapsService.geocodeAddress(someAddressString)` and gets back a `Result<GeocodedLocation>` — either a `Success` with a `latitude`/`longitude`, or a `Failure` with a user-facing error message.

This "put the swappable implementation detail behind one small service class" pattern is deliberate — it's the same Service Layer pattern already used everywhere else in this codebase (`AuthService` wraps Firebase Auth, `StorageService` wraps Firebase Storage, etc., per the Architecture Spec's ADR on layering). It means if we ever change *how* geocoding happens, we only ever touch this one file — nothing above it needs to know or care.

```dart
class MapsService {
  MapsService({geocoding.Geocoding? geocoder})
    : _geocoder = geocoder ?? geocoding.Geocoding();

  final geocoding.Geocoding _geocoder;

  Future<Result<GeocodedLocation>> geocodeAddress(String address) async {
    // ...validates the address isn't empty, then:
    final matches = await _geocoder.locationFromAddress(trimmed);
    // ...takes the first match, wraps it in a Success(GeocodedLocation(...))
    // ...or returns a Failure if nothing matched / an exception was thrown.
  }
}
```

`GeocodedLocation` is a tiny class (also in this file) holding just `latitude`/`longitude` — the app's own internal shape for "a resolved coordinate," independent of whatever shape the underlying package happens to return.

### 4.2 How the pieces connect (top to bottom)

This is the same layering pattern every other feature in Servio uses — UI → Provider → Use Case → Repository → Service → SDK:

1. **`student_internship_screen.dart`** — the student fills in a `companyAddress` text field (a plain string, no coordinate fields shown to the user at all — they don't exist in this layer anymore).
2. **`InternshipSubmissionRequest`** (`internship_submission_request.dart`) — the DTO carrying the form data. It only has `companyAddress` (a string), not `companyLatitude`/`companyLongitude` — those don't exist yet at this point, because nothing has been geocoded.
3. **`SubmitInternshipUseCase`** (`submit_internship_use_case.dart`) — this is where geocoding actually gets triggered. It calls `MapsService.geocodeAddress(request.companyAddress)` *before* touching the repository. If geocoding fails (address not found), the use case returns that failure straight to the UI and **never calls the repository** — so a placement can never be saved with fake or missing coordinates.
4. **`InternshipRepository.submitInternship(...)`** — now takes `companyLatitude`/`companyLongitude` as explicit required parameters (not read off the request DTO anymore), supplied by the use case above. This repository has no idea geocoding even exists — it just receives numbers and writes them to Firestore.
5. **`InternshipModel`** — stores the resolved `companyLatitude`/`companyLongitude` in Firestore, same as before this feature existed (the Firestore schema/rules didn't need to change at all — only where the numbers come from changed).

### 4.3 How it's wired up (Riverpod)

`mapsServiceProvider` in `lib/core/providers/firebase_providers.dart` provides the single `MapsService` instance app-wide:

```dart
final mapsServiceProvider = Provider<MapsService>((ref) {
  return MapsService();
});
```

`submitInternshipUseCaseProvider` (`internship_providers.dart`) injects it alongside the repository:

```dart
final submitInternshipUseCaseProvider = Provider<SubmitInternshipUseCase>((ref) {
  return SubmitInternshipUseCase(
    ref.watch(internshipRepositoryProvider),
    ref.watch(mapsServiceProvider),
  );
});
```

This is standard Riverpod dependency injection — nothing geocoding-specific about it, it's the exact same pattern every other use case in this app follows.

### 4.4 The package itself

Added via `flutter pub add geocoding`, which pulled in:
- `geocoding` — the Dart API surface (`Geocoding().locationFromAddress(...)`).
- `geocoding_ios` / `geocoding_android` — the platform-specific native implementations (these are what actually call `CLGeocoder`/`Geocoder`).

No `Info.plist` or `AndroidManifest.xml` permission entries were needed — forward geocoding a typed address doesn't touch the device's own location, so it doesn't require the location permission that live GPS features (like Attendance's future check-in capture) will need.

## 5. If you want to build something similar yourself

The general recipe, if you ever want to add another "call an external capability, but keep it swappable" feature:

1. Find (or create) a small `XyzService` class in `lib/core/services/` — one class, one job, no business logic, just "talk to this SDK/package and translate its shape into ours."
2. Give it a method that returns `Future<Result<SomeAppType>>` (never throws, never returns the raw SDK type to callers).
3. Add a `Provider<XyzService>` in `lib/core/providers/firebase_providers.dart` (or a new file if it's not Firebase-related).
4. Inject it into whichever use case needs it, the same way `SubmitInternshipUseCase` now takes `MapsService` as a constructor parameter.
5. Never let the UI or the repository import the underlying package directly — only the service should ever `import 'package:whatever/whatever.dart'`.

If you later want **reverse** geocoding (turn the device's live GPS coordinates into a readable address — e.g. for "detect my current location" during attendance check-in), the same `geocoding` package already supports it via `Geocoding().placemarkFromCoordinates(lat, lng)`. You'd add a second method to `MapsService`, e.g. `reverseGeocode(double lat, double lng)`, following the exact same pattern as `geocodeAddress` above. That one *would* need a location permission though, since it needs the device's actual GPS position first.

## 6. Switching to Google's Geocoding API later

If you decide to pay for a Google Cloud billing account later, switching is intentionally a small, contained change — because of the service-layer boundary described in §4.1, **only `maps_service.dart` needs to change.** Nothing in the use case, repository, provider wiring, or UI needs to know or care which implementation is behind `MapsService`.

Steps:

1. **Get a Google Maps Platform API key.** In the Google Cloud Console, enable the "Geocoding API" for your project, then create an API key restricted to that API (and ideally restricted to your app's bundle ID / package name for security).
2. **Store the key safely** — do not hardcode it into `maps_service.dart` or commit it to git. Use `--dart-define=GOOGLE_MAPS_API_KEY=xxx` at build time (read via `String.fromEnvironment('GOOGLE_MAPS_API_KEY')`), matching how other secrets in this project are kept out of source control.
3. **Rewrite the body of `MapsService.geocodeAddress`** to call the HTTP API instead of the native package:

   ```dart
   Future<Result<GeocodedLocation>> geocodeAddress(String address) async {
     final trimmed = address.trim();
     if (trimmed.isEmpty) {
       return const Failure(AppFailure(
         message: 'Company address is required to resolve its location.',
         type: FailureType.validation,
       ));
     }

     final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
       'address': trimmed,
       'key': _apiKey,
     });

     try {
       final response = await http.get(uri);
       final body = jsonDecode(response.body) as Map<String, dynamic>;

       if (body['status'] != 'OK') {
         return const Failure(AppFailure(
           message: 'We could not find that company address. Please check it and try again.',
           type: FailureType.validation,
         ));
       }

       final location = (body['results'] as List).first['geometry']['location'];
       return Success(GeocodedLocation(
         latitude: location['lat'] as double,
         longitude: location['lng'] as double,
       ));
     } catch (error) {
       return Failure(AppFailure(
         message: 'We could not find that company address. Please check it and try again.',
         type: FailureType.validation,
         technicalDetails: error,
       ));
     }
   }
   ```

   You'd add the `http` package (`flutter pub add http`) and remove the `geocoding` package (`flutter pub remove geocoding`) if you're not keeping it as a fallback.
4. **`GeocodedLocation` stays exactly the same** — it's Servio's own type, not the package's, so nothing about it needs to change regardless of which provider fills it in.
5. **Nothing else changes.** `SubmitInternshipUseCase`, `InternshipRepository`, `internship_providers.dart`, and every screen keep working exactly as they do today, because they only ever depended on `MapsService.geocodeAddress()` returning a `Result<GeocodedLocation>` — never on how that result was produced.

### A middle-ground option worth knowing about

You don't have to pick *only* native or *only* Google — a common production pattern is: try the free native geocoder first, and only fall back to the paid API if it returns no match. That would look like:

```dart
Future<Result<GeocodedLocation>> geocodeAddress(String address) async {
  final nativeResult = await _geocodeNative(address);
  if (nativeResult.isSuccess) return nativeResult;
  return _geocodeGoogle(address); // only costs money on native's misses
}
```

This is worth considering if you do get a Google billing account funded but want to keep costs near-zero — most addresses will resolve natively for free, and only the rare miss falls through to the paid API.

## 7. Testing this yourself

Native geocoding needs the Simulator/emulator (or a real device) to actually resolve addresses — it calls into the OS, so it can't be exercised in a plain `flutter test` unit test without mocking. To manually verify it's working:

1. Run the app on the iOS Simulator or an Android emulator (not `flutter test`).
2. Submit a placement with a real, well-known address (e.g. a real Lagos or Abuja business address).
3. Check the written Firestore document (via the `scripts/` admin script, or the Firebase Console) — `companyLatitude`/`companyLongitude` should be real, non-zero decimal values that actually correspond to that location (paste them into Google Maps to sanity-check).
4. Try an obviously invalid address (e.g. `"asdkjaslkdj"`) — you should see the validation error message, and no Firestore document should be written.
