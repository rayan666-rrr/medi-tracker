# The fix: publish Firestore rules (3 minutes, manual)

## Diagnosis — settled

AI Studio's seven answers eliminated every possibility except one.

| Question | Answer | Verdict |
|---|---|---|
| 1. Project id | `linen-math-v6shk`, matches config | ✅ fine |
| 2–3. Named database | exists, active, responding | ✅ fine |
| 4. **Deployed rules** | **default locked policy — `allow read, write: if false`** | ❌ **root cause** |
| 5. `list` on `students` | **No — 403 PERMISSION_DENIED** | ❌ blocks the probe |
| 7. API key | valid, reaches Firestore and evaluates rules | ✅ fine |

Your code is correct. The probe hits `403`, catches it, and falls back to
localStorage exactly as designed. The database is locked, not the app.

This also confirms the offline badge is working — it told the truth.

## Why you must do this by hand

AI Studio said it **cannot** deploy rules: that needs GCP/IAM permissions it does not
have. Do not ask it to try again — it will start editing working application code to
work around a permissions problem it cannot solve.

Editing `firestore.rules` in this repo changes nothing on its own. Rules only take
effect when published to the live database.

---

## Do this

### 1. Open the Rules editor
Go to https://console.firebase.google.com/project/linen-math-v6shk/firestore/rules

### 2. ⚠️ Select the correct database — the step people miss
There is a **database selector** at the top of the Firestore page. Set it to:

    ai-studio-medicaltrackerbd-74a36dc8-bb14-40cd-a17d-522eb9ae35f1

AI Studio confirmed `(default)` **does not exist** in this project (404). So if the
selector shows `(default)`, or you never touched it, you are about to publish rules to
a database that isn't there. It will report success and change nothing.

### 3. Replace the entire ruleset
Delete everything in the editor and paste the full contents of `firestore.rules`
from this repo.

### 4. Click **Publish**
Wait for the confirmation. Propagation takes a few seconds.

### 5. Reload your app
The badge next to "Medical Tracker BD" should turn green: `☁ ক্লাউড সিঙ্ক চালু`

Console should read:

    [MTDB] ✅ Firestore connected → ai-studio-medicaltrackerbd-...  (config from firebase-applet-config.json)

---

## About the expiry date in these rules

The rules contain `request.time < timestamp.date(2026, 10, 5)`.

Your app has no Firebase Auth — students log in with an email and 4-digit PIN stored in
their own document, so `request.auth` is always null. Any rule demanding authentication
locks out every user. So these rules must allow unauthenticated access, which means
**anyone who opens your app can read or delete every student's data.**

That is a real risk, and fine for testing with 3 students. It is not fine for real use.

The date guard makes the app **fail closed** in ~6 weeks rather than sitting wide open
indefinitely. When it expires the app drops to offline mode and the badge turns amber —
that is the reminder to add real auth, not a malfunction. Change the date if you need
longer; just change it deliberately.

---

## Then verify properly

A green badge only proves the app can **read**. Prove it **shares**:

1. Sign up a new student in your normal browser.
2. Open a **different browser** or an incognito window — a fresh localStorage is the point.
3. Log in as admin. The new student should appear.

If they appear in browser 1 but not browser 2, data is still local — tell me.

---

## Separate bug spotted in your screenshot

Your stat cards read:

    বায়োলজি গড়  —          রসায়ন গড়  —
    পদার্থ গড়   325/400     সর্বমোট     325/400

Physics equals the overall total, and bio/chem are empty. That is consistent — your
recent activity shows only physics chapters (গতিবিদ্যা, ভৌতজগৎ, কাজ শক্তি ও ক্ষমতা, ভেক্টর),
so this is probably correct behaviour, not a bug.

But two things are worth checking once sync is live:

- The label says **গড়** ("average") while the value shows a raw total `325/400`.
  Either the label or the value is wrong.
- `রank: #1/৪০০` with only physics data — `calculateStudentMetrics` computes rank from a
  written score that ignores subjects you haven't attempted, so a single strong subject
  can produce a misleadingly perfect rank.

Not urgent. Flagging it so it isn't mistaken for a sync problem later.

---

## Roadmap after this

| # | Task | Status |
|---|---|---|
| 1 | Cloud sync | ✅ code done — **publish rules to finish** |
| 2 | Routine broadcast: `admin.html` writes `routines/{date}`, students read `student.routines[]` | next |
| 3 | Real security (Firebase Auth, replacing PIN-in-document) | before the rules expire |
| 4 | Scoring/label bug above | minor |
| 5 | Delete dead `src/` React scaffold | anytime |
