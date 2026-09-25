# Deploying the Servio website

Servio's web build is hosted on Firebase Hosting, which is free on the
current Spark plan. Everything below is a normal terminal command; the
whole deploy takes about two minutes.

---

## Before the first deploy

1. **A LocationIQ token.** It's compiled into the build and is what makes
   the company address search work. Get it from
   <https://my.locationiq.com> → Access Tokens.
   Then restrict it in the LocationIQ dashboard to the site's domains
   (`servio-e2974.web.app`, `servio-e2974.firebaseapp.com`) — the token is
   visible to anyone who views the page source, and the restriction is what
   stops it being used elsewhere.
2. **Fill in the legal pages.** Replace `[Operator name]` and
   `[contact email]` in `web/privacy.html` and `web/terms.html`.

## Deploying

```bash
cd /Users/dave/Dev/servio
flutter test                       # 90-odd tests, all should pass
flutter build web --release --dart-define=LOCATIONIQ_ACCESS_TOKEN=<token>
firebase deploy --only hosting     # publishes build/web
```

The site is then live at **https://servio-e2974.web.app** (and
`…firebaseapp.com`). Both are already allowed to sign users in.

### Try it before it goes live

```bash
firebase hosting:channel:deploy preview --expires 7d
```

This publishes the same build to a temporary URL that nobody else will
find, with the same headers as production. Open it, click around, then run
the real deploy.

### If a deploy goes wrong

```bash
firebase hosting:releases:list          # find the previous release
firebase hosting:rollback               # or roll back in the console
```

Browsers are told to re-check `index.html` and the app code on every visit,
so a rollback reaches people immediately (no stale service worker: Servio
deliberately doesn't register one).

---

## What's configured for you

In `firebase.json`:

- **Every path serves the app** (`/coordinator/students/<id>` works as a
  bookmark, a shared link, and after a browser refresh).
- **Security headers**: HSTS, `nosniff`, `X-Frame-Options: DENY`, a
  referrer policy, a permissions policy that switches off camera,
  microphone, geolocation, payment, and USB, and a Content-Security-Policy
  that only allows scripts from the site itself and Google's CDN, and
  network calls to Firebase, Google Fonts, and LocationIQ.
  *(Inline scripts are allowed because the Firebase web SDK injects its own
  loader scripts at start-up; their fingerprints change with every Firebase
  version, so pinning them would break the site on the next upgrade.)*
- **Caching**: app code is re-checked on every visit (cheap — unchanged
  files answer "304"); images, fonts, and stylesheets are cached for a day.

## Limits on the free (Spark) plan

| Limit | Amount | What happens when you hit it |
|---|---|---|
| Hosting transfer | 360 MB/day | The site stops serving until the next day |
| Firestore | 50k reads / 20k writes per day | Reads fail; the app shows its error states |
| Cloud Storage | **Unavailable** | Profile photo uploads are switched off in the app for this reason |

A first-time visitor downloads roughly 1.5 MB, so the daily transfer
allowance is about 200 new visitors a day; returning visitors cost almost
nothing. Fine for a pilot. Watch it in the Firebase console → Usage.

## After enabling Blaze

Blaze is pay-as-you-go *beyond* the same free allowances — set a budget
alert first. Then:

1. **Turn profile photos back on**: set
   `AppConstants.profilePhotoUploadsEnabled = true`.
2. **Let the browser display photos** (Storage blocks cross-site reads
   until told otherwise):
   ```bash
   cd scripts && node -e "
   const admin=require('firebase-admin');
   admin.initializeApp({credential:admin.credential.cert(require('./servio-account.json')),
     storageBucket:'servio-e2974.firebasestorage.app'});
   admin.storage().bucket().setCorsConfiguration([
     {origin:['*'],method:['GET','HEAD'],responseHeader:['Content-Type'],maxAgeSeconds:3600}
   ]).then(()=>console.log('done'));"
   ```
3. **Push notifications** become possible (a Cloud Function on new
   `notifications` documents). The data model already carries what it
   needs; see the roadmap's Phase 6.
4. Rebuild and deploy.

## A custom domain

Firebase console → Hosting → Add custom domain, then add the DNS records it
gives you. Afterwards add the domain under Authentication → Settings →
Authorized domains, or sign-in will fail there, and update
`AppConstants.webBaseUrl` plus the LocationIQ token restriction.
