# Where we are, and what to do next

## Done — step 1: cloud sync wiring (commit `eec40c4`)

`index.html` no longer uses the placeholder config or the compat SDK.

| Before | After |
|---|---|
| `apiKey: "AIzaSyDUMMY_REPLACE_ME"` | real project config |
| compat SDK → can only reach `(default)` | modular SDK → reaches the **named** DB |
| `initFirebase()` fails silently | real read probe, failure cause printed |
| offline was a dead end | badge + console name the exact cause |
| `initApp()` could run twice | `__appBooted` guard |

**Verified locally:** both inline scripts parse; all 27 inline `onclick`/`onsubmit`
handlers still resolve to global functions (the module trap was avoided by keeping the
main app script classic and passing the DB through `window.MTDB`).

**Not verified:** the actual Firestore connection. This sandbox has no outbound network
to `firestore.googleapis.com`, so only your browser can confirm it.

---

## Do this now — 3 minutes

### 1. Deploy the updated rules ⚠️ likely your blocker
`firestore.rules` was missing a rule for `/routines/*` entirely — the collection
`admin.html` writes to. Firestore denies anything without a matching rule, so **the
teacher routine broadcast has been failing silently this whole time.** I added it.

Rules in a repo file do nothing until deployed. In the Firebase console:
Firestore → **Rules** tab → paste the contents of `firestore.rules` → **Publish**.

Also confirm at the top of that page that you are editing the database named
`ai-studio-medicaltrackerbd-74a36dc8-bb14-40cd-a17d-522eb9ae35f1`, **not** `(default)`.
The database picker is easy to miss, and rules published to the wrong database look
correct while changing nothing.

### 2. Reload the app and read the badge
It sits next to the "Medical Tracker BD" title in the top nav.

- `☁ ক্লাউড সিঙ্ক চালু` (green) → **working.** Go to step 3.
- `📴 অফলাইন মোড` (amber) → click it, then open the console (F12).

### 3. If still offline, the console now names the cause
Look for the line `[MTDB] Likely cause:` and match it below.

| Message | Meaning | Fix |
|---|---|---|
| `PERMISSION DENIED` | Rules block reads of `/students` | Rules not deployed, or deployed to `(default)` instead of the named DB. Redo step 1. |
| `DATABASE NOT FOUND` | The named DB id doesn't exist in this project | Open Firestore → database dropdown → copy the exact id → tell me and I'll update it. |
| `UNAVAILABLE` | Network, or Firestore not enabled | Check connection; confirm Firestore is provisioned. |
| `BAD CONFIG` | Key/project rejected | The project may have been deleted or the key restricted by HTTP referrer. |

Paste that line to me and I'll fix the specific cause. **Don't guess — the message is exact.**

### 4. Prove it end-to-end
The badge only proves the app can *read*. Prove it *shares*:

1. Sign up a new student in a normal window.
2. Open a **different browser** (or incognito — a fresh localStorage is the point).
3. Log in as admin → the new student appears in the list.

If step 4 works, cloud sync is genuinely done. If the student appears in the first
browser but not the second, it saved to localStorage only — tell me.

---

## Then — the remaining roadmap

| # | Problem | Status |
|---|---|---|
| 1 | No cloud sync | ✅ code done, awaiting your browser check |
| 2 | Routine broadcast disconnected: `admin.html` writes `routines/{date}`, students read `student.routines[]` | ⏭ next — the rules gap is fixed, but the data shapes still don't match |
| 3 | Rules are `if true` — anyone can read/wipe every student | after #2 |
| 4 | Hardcoded admin password `17514`, PINs `123456`/`1234`, djb2 "hashing" | needs Firebase Auth, own session |
| 5 | Delete dead `src/` React scaffold | anytime, zero risk |

### A note on step 2
Two front-ends currently disagree about where routines live:

- `admin.html` → `routines/{date}` and `routines/current` (shared documents)
- `index.html` → `student.routines[]` inside each student document

Neither is wrong, but they must agree. My recommendation is to keep the broadcast
documents as the source of truth and have students read `routines/current`, because it
means one write reaches every student instead of N writes. We'll decide together once
the badge is green — no point building on an unverified foundation.

### On security (steps 3–4)
To be clear about what's actually exposed: the Firebase web API key is **public by
design** and is not the problem. The real exposure is `allow read, write: if true` —
any visitor can read every student's data or delete the whole collection. That is why
step 3 exists, and why the current rules file is explicitly labelled development-only.
