# AI Studio Command #1 — Connect index.html to the real Firestore

Copy everything inside the box below and paste it into AI Studio as one message.

---

## THE PROMPT

Fix cloud sync in `index.html`. Right now `FIREBASE_CONFIG` contains placeholder values
(`AIzaSyDUMMY_REPLACE_ME`), so `initFirebase()` always fails and every `db_*` function
silently falls back to localStorage. Students and the admin therefore never see each
other's data.

Do exactly the following. Change nothing else.

### Constraint you must respect
`index.html` uses a single classic (non-module) `<script>`, and the HTML uses inline
`onclick="navigate('home')"` style handlers that require functions to be global.
DO NOT convert that main script to `type="module"` — it will break every button.
Instead, add a small separate module script that exposes the database to the global scope.

### Step 1 — remove the compat SDK
Delete these two lines from `<head>`:

    <script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore-compat.js"></script>

### Step 2 — add a modular bootstrap module
Insert this immediately BEFORE the main `<script>` tag that starts the application code
(the one containing `function hashPin(pin)`):

    <script type="module">
      import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
      import {
        getFirestore, collection, doc, getDoc, getDocs, setDoc, deleteDoc,
        query, where, limit
      } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

      const firebaseConfig = {
        apiKey: "AIzaSyDVhjhOc5uFAz-0uuHNsaSoPBP8UfA0Z7A",
        authDomain: "linen-math-v6shk.firebaseapp.com",
        projectId: "linen-math-v6shk",
        storageBucket: "linen-math-v6shk.firebasestorage.app",
        messagingSenderId: "495265888515",
        appId: "1:495265888515:web:eb3051b5dccdde9962d136"
      };
      const FIRESTORE_DB_ID = "ai-studio-medicaltrackerbd-74a36dc8-bb14-40cd-a17d-522eb9ae35f1";

      window.MTDB = null;
      window.MTDBReady = (async () => {
        try {
          const app = initializeApp(firebaseConfig);
          const db  = getFirestore(app, FIRESTORE_DB_ID);
          // connectivity probe - if this throws we stay on localStorage
          await getDocs(query(collection(db, 'students'), limit(1)));
          window.MTDB = {
            getByEmail: async (email) => {
              const s = await getDocs(query(collection(db,'students'), where('email','==',email), limit(1)));
              return s.empty ? null : s.docs[0].data();
            },
            get:    async (uid) => { const d = await getDoc(doc(db,'students',uid)); return d.exists() ? d.data() : null; },
            save:   async (student) => { await setDoc(doc(db,'students',student.id), student, { merge: true }); },
            list:   async () => (await getDocs(collection(db,'students'))).docs.map(d => d.data()),
            remove: async (uid) => { await deleteDoc(doc(db,'students',uid)); }
          };
          console.log('[MTDB] Firestore connected:', FIRESTORE_DB_ID);
          return true;
        } catch (err) {
          console.warn('[MTDB] Firestore unavailable, using localStorage:', err);
          window.MTDB = null;
          return false;
        }
      })();
    </script>

### Step 3 — rewire the existing db layer
In the main script, DELETE the `FIREBASE_CONFIG` object and the whole `initFirebase()`
function. Replace the two globals with:

    let isFirestoreActive = false;

Then in each of the five functions `db_getStudentByEmail`, `db_getStudent`,
`db_saveStudent`, `db_listStudents`, `db_deleteStudent`:
- replace the condition `if (isFirestoreActive && firestoreDb)` with `if (window.MTDB)`
- replace the compat call inside the `try` with the matching `window.MTDB.*` call
  (`getByEmail`, `get`, `save`, `list`, `remove`)
- KEEP the existing localStorage fallback in the `catch` and in the `else` branch
  exactly as it is. Offline must still work.

### Step 4 — boot only after the DB is ready, and only once
Replace the bottom initialisation block with:

    let __appBooted = false;
    async function initApp() {
      if (__appBooted) return;
      __appBooted = true;
      isFirestoreActive = await window.MTDBReady;
      loadState();
      showLogin();
      wireLoginEvents();
      const badge = document.getElementById('sync-badge');
      if (badge) {
        badge.textContent = isFirestoreActive ? '☁ ক্লাউড সিঙ্ক চালু' : '📴 অফলাইন মোড';
        badge.style.color = isFirestoreActive ? '#34d399' : '#94a3b8';
      }
    }
    if (document.readyState === 'loading') {
      window.addEventListener('DOMContentLoaded', initApp);
    } else {
      initApp();
    }

### Step 5 — visible sync indicator
Inside the top nav, next to the brand element, add:

    <span id="sync-badge" style="font-size:11px;font-weight:600;color:#94a3b8;">…</span>

### Acceptance criteria
1. Opening the app logs `[MTDB] Firestore connected:` in the console and the badge shows
   "ক্লাউড সিঙ্ক চালু".
2. Signing up a new student creates a document under `students/{id}` in the named database
   `ai-studio-medicaltrackerbd-74a36dc8-bb14-40cd-a17d-522eb9ae35f1`.
3. Saving a chapter mark in one browser, then logging in as admin in a DIFFERENT browser,
   shows that student and their mark.
4. Blocking network requests to firestore.googleapis.com makes the badge show "অফলাইন মোড"
   and the app still works from localStorage — no crash, no blank screen.
5. Every existing button still works (no `onclick` handler became undefined).

---

## Why this shape

- **Named database.** `getFirestore(app, dbId)` is the only way to reach
  `ai-studio-medicaltrackerbd-…`. Compat's `firebase.firestore()` can only ever hit
  `(default)`, which is empty. This is why simply pasting the real API key into the
  current code would NOT have fixed it.
- **No module conversion.** Your ~120 inline `onclick=` handlers need global functions.
  Module scope would silently break all of them. The bootstrap module hands the DB over
  through `window.MTDB` so the classic script is untouched structurally.
- **Connectivity probe.** Firebase's `initializeApp` never throws on a bad network, so a
  real read is the only honest test of whether cloud is live.
- **Fallback preserved.** Bangladeshi mobile data drops. Offline mode staying functional
  is a feature, not a leftover.

## Known gap this intentionally does NOT fix
After this lands, `admin.html` still writes routines to `routines/{date}` while
`index.html` reads routines from inside each student document. The routine broadcast
still won't reach students. That is command #2 — do not mix it into this change.
