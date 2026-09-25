# Servio — Design

How Servio looks and why, so new screens fit without guesswork.

---

## The idea: the placement journey

A placement travels through five stops:

**Submitted → Approved → Lecturer assigned → Active → Completed**

Every screen should answer two questions: *where is this placement on that
journey*, and *what happens next*. That is the whole concept, and it shows
up as one reusable component, the **journey track**
(`lib/core/widgets/journey_track.dart`):

- Stops already passed are solid ink with a tick.
- The stop a placement is waiting at is a sky-blue ring.
- Stops ahead are hollow.
- A rejected placement shows its first stop crossed out.

It appears full-size (with labels) on the student's home and on both detail
pages, and compact (dots only) in coordinator lists. Below ~420px wide it
drops the labels and says "Active · step 4 of 5" instead, so it never
crowds a phone.

Next to it, the student's home states the next step in one plain sentence
(`PlacementJourneyCard.nextStepFor`) — "Approved. Next, your coordinator
assigns the lecturer who will supervise you." Say what happens next and who
it is waiting on; never leave someone guessing.

## One colour per module

Three hues carry meaning everywhere, so people learn them without being
told:

| Colour | Token | Means |
|---|---|---|
| Ink (navy) | `AppColors.ink` | Placement decisions, supervision, primary actions |
| Sky (cyan) | `AppColors.sky` | Attendance |
| Blush (pink) | `AppColors.blush` | The logbook |

Everything else is a neutral. Semantic colours (`success`, `warning`,
`error`) are kept for genuine outcomes — approved, needs attention,
rejected — not for decoration. Components ask for an `AppTone` rather than
a raw colour (`lib/app/theme/app_tone.dart`), which keeps the mapping
consistent.

The attendance calendar is the clearest example: a day checked in and out
is stamped sky; checked in but never out is amber; a past working day with
no record is grey. Colour never carries meaning alone — there is always a
word or a number beside it.

## Surfaces and type

- **Flat, not floating.** White cards, 20px radius, a 1px `line` border, on
  a mist background. No drop shadows except on menus and dialogs.
- **One typeface:** Plus Jakarta Sans, bundled in `assets/fonts/` (SIL Open
  Font License) so it renders the same everywhere and never depends on a
  font CDN. Numbers use tabular figures so they line up and don't jiggle
  as they change.
- **Rounded, but not soft:** cards 20px, controls 12px, status pills fully
  rounded.
- **Restraint:** no gradients, no glass, no emoji, no stock illustration.
  Density and hierarchy do the work.

## Layout

- The shell (`lib/app/shell/app_shell.dart`) is a sidebar plus top bar from
  900px, and an app bar plus bottom navigation below it. Detail pages use
  the same shell with a back button.
- Every role has exactly four sections. Notifications and the profile live
  in the top bar for everyone; a coordinator's audit history sits beside
  the bell.
- Content is capped at 1240px so text doesn't stretch across a wide
  monitor, and detail pages use `ResponsiveColumns`: identity on the left,
  activity on the right, stacked into one column on phones.

## Motion

Short and purposeful: sections ease in with a small fade and rise
(`FadeSlideIn`, staggered ~45ms apart), loading uses a single shimmer
sweep, and buttons swap their label for a spinner while they work. Every
animation checks `MediaQuery.disableAnimationsOf` and stops if the viewer
has asked for reduced motion.

## Loading, empty, and error states

Three rules:

1. **Loading** shows a skeleton in the shape of the content
   (`AppLoading(layout: …)`), never a bare spinner on a blank screen.
2. **Empty** says what will appear here and offers the action that fills it
   ("Submit my placement").
3. **Error** is plain language with a way forward ("Check your connection
   and try again"), never a raw exception.

Writing style throughout: sentence case, contractions, second person, no
exclamation marks, and no jargon. "Start internship", not "Activate".

## Accessibility

- Contrast: body text and pill text are checked against their backgrounds;
  never rely on colour alone.
- Tap targets are at least 44px.
- Icon-only buttons have tooltips, avatars carry the person's name, star
  ratings announce "Rate 3 out of 5", and the journey track announces its
  stage.
- Text scales with the system setting; layouts wrap rather than clip.

## Adding a screen

1. Use `AppShell` via the router; don't add a `Scaffold`.
2. Build from `SectionCard`, `StatTile`, `InfoRow`/`InfoPanel`,
   `AppStatusChip`, `AppAvatar`, `AppButton`, `AppTextField`.
3. Pick the module tone for anything attendance- or logbook-related.
4. Give it all three states above.
5. Format dates through `Formatters` (calendar days in UTC, moments in
   local time) so dates never shift by a day.

## The logo

`BrandMark` is drawn in code: a route curving from a start stop to a
finishing ring — the journey, in one stroke. It is a **placeholder** until
the real logo arrives; see `docs/BRANDING.md` for swapping it, including
the app icons, the splash, and the favicon.
