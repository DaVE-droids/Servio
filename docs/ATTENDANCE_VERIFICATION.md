# Attendance verification — checking a student was really at work

Built 2026-11-06. This explains how Servio decides whether a student's
check-in is backed up by where their phone actually was, why it is built
this way, and what it genuinely cannot do.

Related: `docs/LOCATION_SERVICES.md` (how the company's address and
coordinates get into the system in the first place), `docs/PERMISSIONS.md`
(the OS permissions this needs).

---

## 1. The problem

A student taps "Check in" and Servio records the time. Before this change
that was *all* it recorded, so a student could check in from bed and the
record looked identical to one made at their desk. A lecturer signing off
months of attendance had nothing to go on but trust.

What a lecturer or coordinator now gets is a second piece of information
next to every check-in: whether the phone was at the company address at
the time.

## 2. The one thing to understand before anything else

**This does not prove attendance, and nothing built on a phone can.**

Location on a phone is self-reported. The phone says where it is, and the
app believes it. Free apps exist that make a phone report any location you
type in. Servio can make lying inconvenient and leave a trail worth
questioning — it cannot make lying impossible.

So the design goal is not proof. It is:

1. Catch the careless case (checking in from home, having changed nothing).
2. Give a lecturer something concrete to ask about.
3. Never punish an honest student whose phone simply failed.

Point 3 matters more than it sounds. GPS is unreliable indoors, in dense
city areas, and on cheap phones. If a bad reading marked a student absent,
the feature would do more harm than the problem it solves.

## 3. How it works, step by step

When a student taps **Check in**:

1. **Servio asks the phone where it is.** First time, the OS shows the
   permission prompt. The student can refuse.
2. **The phone answers with a position and a margin of error** — "I am at
   this point, give or take 30 metres." That margin matters as much as the
   position, and most apps throw it away.
3. **Servio measures the distance** from that point to the company address
   stored on the placement (which came from the address the student
   searched for when they submitted it — see `LOCATION_SERVICES.md`).
4. **Servio saves all of it** on the attendance record: coordinates, the
   margin of error, the distance, and — on Android — whether the OS said
   the position came from a fake-location app.
5. **A verdict is worked out from those numbers** and shown to the student
   and their lecturer.

If step 1 or 2 fails — location switched off, permission refused, phone
can't get a fix, taking too long — **the check-in still succeeds**. It is
saved with no location and reads as "not confirmed".

## 4. The three verdicts

| Shown as | What it means |
|---|---|
| **At the workplace** | A trustworthy reading put the phone at the company address. |
| **Away from the workplace** | A trustworthy reading put the phone somewhere else. Worth asking about. |
| **Location not confirmed** | Nothing usable to judge. Not an accusation. |

"Not confirmed" covers three different situations, and tapping the chip
says which one:

- **No reading** — permission refused, location off, or no fix. Also every
  attendance record created before this feature existed.
- **Too imprecise** — the phone's own margin of error was so wide the
  reading means nothing either way.
- **Faked location** — Android reported a mock-location app. This is the
  only one that is genuinely suspicious, and it is deliberately *not*
  "away from the workplace", because a spoofed position usually claims to
  be *at* work. Reporting it as on-site would be the exact wrong answer.

## 5. The two numbers you can tune

Both live in `lib/app/constants/app_constants.dart`:

**`attendanceGeofenceRadiusMetres` — currently 250 m.** How far from the
company address still counts as being there. 250 m is generous on purpose:
the address was geocoded from a text search, so the pin can easily sit on
the wrong corner of a large compound, and a phone indoors is often tens of
metres out. The job is telling "at the office" apart from "at home", not
working out which floor someone is on.

**`attendanceMaxLocationAccuracyMetres` — currently 200 m.** Readings
vaguer than this are thrown away rather than used. A phone that only knows
its position to within half a kilometre should not be placing anyone
anywhere.

**The margin of error is added to the fence.** A student 300 m away with a
±80 m reading is marked *at the workplace*, because they genuinely might be
inside the 250 m fence. The same 300 m with a ±10 m reading is marked away.
This is the single most important rule in the feature: it is what stops
honest students being flagged by their hardware.

Changing either number takes effect immediately and changes nothing about
stored records, because of the next section.

## 6. Why the verdict isn't stored

Only raw facts are saved: coordinates, margin of error, distance, mocked
flag. The verdict is calculated fresh every time it is displayed.

Two benefits:

- **You can retune the thresholds whenever you like.** Change 250 to 400
  and every past record is re-judged. If the verdict were stored you would
  have to rewrite thousands of documents.
- **Old records degrade gracefully.** Every check-in made before this
  feature has no coordinates, so it comes out "not confirmed" — never
  "away from the workplace". No migration, no false accusations against
  students who checked in last month.

## 7. Where the code lives

| File | What it does |
|---|---|
| `lib/features/attendance/domain/location_check.dart` | **The decision.** Pure logic — no GPS, no Firebase. Takes distance, margin of error, mocked flag; returns a verdict and a plain-English explanation. This is the file to read first. |
| `lib/core/services/location_service.dart` | Asks the phone where it is. Never throws; returns an empty reading on any failure. |
| `lib/features/attendance/data/models/attendance_model.dart` | The stored fields: `checkInLatitude`, `checkInLongitude`, `checkInAccuracyMetres`, `checkInDistanceMetres`, `checkInLocationMocked`. |
| `lib/features/attendance/data/repositories/attendance_repository.dart` | Takes the reading and measures the distance while building the record. |
| `lib/features/attendance/presentation/widgets/attendance_location_chip.dart` | The chip. Tap it for the explanation. |
| `test/location_check_test.dart` | 7 tests covering every verdict and both thresholds. |

The decision logic is deliberately separated from everything else so it can
be tested without a phone, a GPS signal, or a Firebase connection. If you
change one file in this feature, make it that one, and the tests will tell
you immediately if you broke a case.

## 8. Who sees it

- **The student** sees the verdict for today on their own attendance card.
  This is on purpose: someone whose location keeps failing should be able
  to notice and fix a phone setting, rather than being quietly flagged
  behind their back.
- **The lecturer** sees a chip on every row of their attendance list, plus
  a count at the top when any check-in was recorded away from the
  workplace, so they do not have to open each day to spot a problem.
- **Coordinators** see it wherever they view a student's attendance.

Access is unchanged from before: a student sees only their own records, a
lecturer only their assigned students', coordinators all of them. That is
enforced by `firestore.rules`, not by the screens.

## 9. What the security rules do and don't check

The rules were extended (`attendanceFields()` plus a new
`isValidAttendanceLocation()`) to check the new fields' **shape**:
coordinates are numbers in valid ranges, the distance is not negative, and
a distance is never claimed without coordinates behind it.

They cannot check its **truth**. The distance is calculated on the phone,
and the rules language has no trigonometry to recompute it with — and there
is no server in this architecture to do it instead. A student who installs
a mock-location app, or who calls Firestore directly with a patched build,
can write whatever numbers they like.

Closing that properly needs one of:

- **A Cloud Function** that recomputes the distance server-side on write.
  Needs the Blaze plan. Still trusts the coordinates the phone reported,
  so it raises the bar without reaching proof.
- **Employer sign-off** — the student's workplace supervisor confirms the
  week. This is the only approach that brings in someone who actually saw
  the student, and it is in the roadmap for exactly that reason.

## 10. Privacy

One coordinate per workday, captured only when the student taps check in.
Never in the background, never between check-ins. Visible only to that
student, their assigned lecturer, and coordinators.

`ACCESS_BACKGROUND_LOCATION` is deliberately **not** requested. Both app
stores scrutinise it heavily, and attendance has no need for it.

If this scope ever widens, `web/privacy.html` and
`ios/Runner/PrivacyInfo.xcprivacy` have to be updated to match.

## 11. Testing it yourself

Rules must be deployed first (`firebase deploy --only firestore:rules`), or
every check-in is rejected — the rules only accept fields they know about.

1. Run as a student with an approved, active, lecturer-assigned placement.
2. Tap **Check in**. Accept the location prompt. Expect "At the workplace"
   only if you are genuinely near the address on the placement — otherwise
   "Away from the workplace" is the correct answer.
3. To see the away case deliberately, submit a placement with an address in
   another city and check in from home.
4. Turn location off entirely and check in: it should still succeed, and
   read "Location not confirmed".
5. Log in as that student's lecturer and confirm the chip appears on the
   row, and the count appears at the top when something is away.

In the iOS Simulator, location is whatever you set under Features →
Location; a simulator reporting Apple HQ while the placement is in Lagos
will correctly say away from the workplace. That is the feature working,
not a bug.

## 12. Known gaps

- **Check-out captures nothing.** Only check-in has a location. The model
  has `checkOutLatitude`/`checkOutLongitude` fields ready if a half-day
  check (arrived, then left after ten minutes) ever matters.
- **No history of a student's location pattern.** Each day is judged alone.
  A student who is "away" twenty times is twenty separate chips, not a
  flagged pattern.
- **No notification.** Nobody is told when a check-in comes in away from
  the workplace; a lecturer has to look. This fits naturally into the
  notification work in the roadmap.
- **Untested on a real device.** The logic has unit tests and the app
  builds and analyzes clean, but no physical phone has been through the
  flow yet.
