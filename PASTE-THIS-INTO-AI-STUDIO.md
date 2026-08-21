# AI Studio Command #2 — Diagnose why cloud sync is offline

Since AI Studio provisioned Firebase itself, it can inspect the project directly.
Do NOT ask it to rewrite the sync code — that is already done. Ask it to REPORT.

Paste the prompt below into AI Studio as one message.

---

## THE PROMPT

Do not change any application code yet. I need a diagnosis first.

You provisioned Firebase for this applet, so you have access to the project. My app
`index.html` connects to Firestore and falls back to localStorage when that fails.
It is currently falling back — the sync badge shows offline mode. I need to know why.

Answer these seven questions precisely. If you cannot determine one, say
"cannot determine" rather than guessing.

1. What is the exact `projectId` of the Firebase project attached to this applet
   right now? Does it still match `linen-math-v6shk` in `firebase-applet-config.json`?

2. List every Firestore database that exists in that project, by exact id. For each,
   say whether it is `(default)` or a named database.

3. Does a database with the id
   `ai-studio-medicaltrackerbd-74a36dc8-bb14-40cd-a17d-522eb9ae35f1`
   still exist? If it was re-provisioned or renamed, give the current id.

4. Show the Firestore security rules **currently deployed** (not the local
   `firestore.rules` file — the live published ruleset), and state which database
   they are published to. If more than one database exists, show the rules for each.

5. Do the deployed rules allow an **unauthenticated** client to run a `list` query on
   the `students` collection? My connectivity probe is
   `getDocs(query(collection(db,'students'), limit(1)))`, which needs `list`, not just
   `get`. Answer yes or no.

6. Does the `students` collection currently contain any documents? How many? Same for
   the `routines` collection.

7. Is the Firebase API key restricted by HTTP referrer or by API? If so, list the
   allowed referrers and confirm whether the AI Studio preview domain is included.

After answering all seven, tell me in one sentence which single item is the root cause
of the offline fallback. Do not fix anything yet — I will decide the fix based on your
answers.

---

## Why ask instead of tell

The sync code is already correct and pushed. The failure is in the **environment**, not
the code — a database id, a deployed ruleset, or a key restriction. AI Studio can see
all three; I cannot (this sandbox has no network route to `firestore.googleapis.com`).

Telling AI Studio to "fix the connection" now would make it start editing working code
on a guess. That is how a one-line environment problem turns into a broken app.

## What each answer would mean

| Answer | Root cause | Fix |
|---|---|---|
| Q3 says the database id changed | AI Studio re-provisioned Firebase | Update `firebase-applet-config.json` — the app now reads it at runtime, so no code change |
| Q5 is **no** | Rules allow `get` but not `list` | Publish the repo's `firestore.rules` |
| Q4 shows rules on the wrong database | Published to `(default)` | Re-publish to the named database |
| Q7 shows referrer restrictions | Preview domain blocked | Add the preview domain to allowed referrers |
| Q1 shows a different project | Config is stale | Replace `firebase-applet-config.json` wholesale |

## Reminder about the browser console

Your own app already narrows this down. Open the preview, press F12, and look for:

    [MTDB] Likely cause: ...

That line plus AI Studio's seven answers will pin the cause exactly. Send me either one.
