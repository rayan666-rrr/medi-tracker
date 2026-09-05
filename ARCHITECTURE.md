# Medical Tracker BD — App Structure

> Auto-generated map of the repository as it exists on `arena/01a023d8-medi-tracker`
> (base commit `0698322 — feat: initialize project structure and base UI`).

---

## 1. File tree (tracked files only)

```
medi-tracker/
├── index.html                    ← THE ENTIRE STUDENT + ADMIN APP (3,842 lines, vanilla JS)
├── admin.html                    ← Separate "Teacher Portal" page (375 lines, Firebase modular SDK)
├── src/                          ← React/Vite scaffold — currently EMPTY / UNUSED
│   ├── main.tsx                  (10 lines, mounts <App/> into #root)
│   ├── App.tsx                   (8 lines, returns <div></div>)
│   └── index.css                 (1 line, `@import "tailwindcss"`)
├── assets/
│   └── .aistudio/.gitignore      (ignores everything — AI Studio scratch dir)
├── vite.config.ts                React + Tailwind plugins, `@` → repo root alias, HMR toggle
├── tsconfig.json                 ES2022, bundler resolution, react-jsx, noEmit
├── package.json                  name "react-example"; dev = `vite --port=3000 --host=0.0.0.0`
├── bun.lock                      Bun lockfile (93 KB)
├── metadata.json                 AI Studio applet manifest (name/description/capabilities)
├── firebase-applet-config.json   Real Firebase project creds (linen-math-v6shk)
├── firebase-blueprint.json       Entity schema for `student` + `/students/{uid}` mapping
├── firestore.rules               `/students/{uid}` → allow read, write: if true  ⚠️
├── .env.example                  GEMINI_API_KEY, APP_URL
└── .gitignore                    node_modules, dist, build, coverage, .env*, *.log
```

**Key structural fact:** the app does **not** run through React. `index.html` is a
standalone, self-contained single-file application (inline `<style>` + inline `<script>`).
`src/*` is dead scaffolding — nothing imports `src/main.tsx`, and `index.html` has no
`<script type="module" src="/src/main.tsx">` tag.

---

## 2. index.html — the main application

### Load order
| Lines | Content |
|---|---|
| 1–16 | `<head>`, Google Fonts (Hind Siliguri + Inter), Firebase **compat** SDK v10.7.1 (app + firestore) |
| 17–644 | Inline CSS (~630 lines), dark theme driven by CSS custom properties on `:root` |
| 646–1370 | `<body>` markup — nav, 9 view `<section>`s, 2 modals |
| 1371 | Chart.js 4.4.1 UMD from jsDelivr |
| 1376–3840 | Inline application script, organized into **16 numbered sections** |

### CSS blocks (lines 17–644)
`Container` · `Top Nav` · `Avatar & Dropdown` · `UI Cards` · `Buttons` · `Toast` ·
`Forms` · `Modals` · `Login Screen` · `Rank Orb & Score` · `Stat 4-card grid` ·
`Subject / Paper Grid` · `Chapter List` · `Routine Blocks` · `Admin Mini 6-Cards` ·
`Heatmap` · `Empty state` · `Toggle Switch` · `Thinking stats responsive` · `Utility`

Theme tokens: `--bg #090a0f`, `--card #11131d`, `--accent #818cf8`, `--text #f8fafc`, `--radius 12px`.

### Views (SPA — one `<section>` per screen, toggled by `.hidden`)
`VIEWS` array at line 1951 drives `navigate(viewName)`:

| # | Section id | Role | Purpose |
|---|---|---|---|
| 1 | `view-login` | public | Email + 4-digit PIN login, inline signup prompt |
| 2 | `view-home` | student | Category badge, 200-mark breakdown table, rank orb, 4 stat cards, weak chapters, recent activity, 3 "thinking stats" charts |
| 3 | `view-subjects` | student | Subject/paper grid (6 papers) |
| 4 | `view-paper` | student | Chapter list for the selected paper |
| 5 | `view-routine` | student | Today's routine blocks + completion checkboxes |
| 6 | `view-settings` | student | Profile, GPA, PIN change, 200-scale toggle, milestones, JSON export/import |
| 7 | `view-admin-home` | admin | 6 KPI cards, class average chart, student list, 15-day activity heatmap |
| 8 | `view-student-analytics` | admin | Drill-down: 4 charts (rank trend, paper avg, chapter mastery, routine completion) + recent marks |
| 9 | `view-admin-routine` | admin | Routine builder: recipients checklist, time range, subject/chapter multi-select, pending blocks, publish |

Modals: `#chapter-entry-modal` (score entry), `#modal-signup`, plus an admin-login modal and a result card overlay.

### JavaScript sections (lines 1376–3840)

| § | Lines | Contents |
|---|---|---|
| 1 | 1377–1475 | `hashPin()` (djb2), `SEED_STUDENTS` (3 demo users), `seedStudents()`, **`SYLLABUS`** (55 chapters as `[paperId, banglaName]`), `PAPERS` (6 papers), `DIST_SAMPLES` (deterministic Box-Muller N(110,25) 100-sample rank distribution) |
| 2 | 1476–1710 | `FIREBASE_CONFIG` (⚠️ **dummy placeholder**), `initFirebase()`, async DB layer: `db_getStudentByEmail` · `db_getStudent` · `db_saveStudent` · `db_listStudents` · `db_deleteStudent` — each falls back to `localStorage` when Firestore is inactive. Also `showToast()`, `state`, `loadState()`, `saveState()` |
| 3 | 1711–1947 | `SUBJECTS`, `WEIGHTS` (bio 30 / chem 25 / phy 20), `getSubjectIdForChapter`, `categoryFromScore100/200`, `CATEGORY_DETAILS` (6 tiers: Diamond → Gold → Metal → Silver → Pass → Red Zone), `computeOverallAvg100`, `computeProfileCategory100`, `refreshStudentCategories`, `calcGPA` (SSC×8 + HSC×12, −3 for 2nd timers), `calculateStudentMetrics` (rank prediction) |
| 4 | 1948–1992 | `VIEWS`, `navigate()`, `handleBrandClick()` |
| 5 | 1993–2170 | `showLogin`, `renderLoginScreen`, `handleLoginEmailInput`, `attemptLogin`, `enterStudentApp`, `handleAdminLogin`, `setupNavForUser`, `logout` |
| 6 | 2171–2237 | `openSignUpModal`, `updateLiveGpaPreview`, `handleCreateStudent` |
| 7 | 2238–2597 | `getCurrentStudent`, `renderStudentHome`, `renderThinkingStats` (pie / line / bar via Chart.js) |
| 8 | 2598–2700 | `renderSubjectsGrid`, `renderPaperChapters` |
| 9 | 2701–2915 | `calculateSkipped`, `openChapterEntryModal`, `closeChapterModal`, `handleSaveChapterMark`, `showResultCard` (tier-up animation), `closeResultCard` |
| 10 | 2916–2990 | `renderStudentRoutine`, `toggleRoutineComplete` |
| 11 | 2991–3095 | `renderSettings`, `renderMilestonesList`, `handleUpdateProfile`, `exportDataJSON`, `importDataJSON` |
| 12 | 3096–3277 | `renderAdminDashboard` (KPIs + heatmap), `renderAdminClassChart` |
| 13 | 3278–3619 | `renderStudentAnalytics`, `renderDrillRankTrend`, `renderDrillPaperAvg`, `renderDrillChapterMastery`, `renderDrillRoutineComp`, `sendRoutineToCurrentStudent`, `resetStudentData`, `deleteCurrentStudentProfile` |
| 14 | 3620–3771 | `renderAdminRoutineBuilder`, `selectAllRecipients`, `renderRoutineChapterChecklist`, `addPendingBlock`, `renderPendingBlocksList`, `removePendingBlock`, `publishRoutineBlocks` |
| 15 | 3772–3806 | `openModal`, `closeModal`, `openAdminLoginModal`, `toggleDropdown`, `closeDropdown` |
| 16 | 3807–3840 | `wireLoginEvents`, `initApp` (`loadState → showLogin → wireLoginEvents`), DOMContentLoaded + readyState double-boot |

### Domain model
```
student {
  id, name, email, pinHash, role: 'student',
  ssc, hsc, isSecondTimer,          // GPA inputs
  marks: [ { date, chapterId, total, correct, wrong, skipped, mistakeCategory, note } ],
  routines: [ { date, blocks: [ { start, end, subject, chapters[], title, note } ] } ],
  completions: [ { date, done: [blockIdx...] } ],
  streak, lastActive, createdAt
}
```
Scoring: written = weighted % of MCQ correct (−0.25 per wrong) → out of 100;
grand total (200 scale) = written + SSC×8 + HSC×12 − (3 if second timer);
rank = position of grand total inside `DIST_SAMPLES`.

---

## 3. admin.html — separate teacher portal

- Standalone page, **not linked from `index.html`** and not routed by Vite.
- Uses the **modular** Firebase SDK v10.12.0 (app / auth / firestore) + Tailwind CDN + Lucide icons.
- Reads real creds inline (matching `firebase-applet-config.json`, project `linen-math-v6shk`,
  named Firestore DB `ai-studio-medicaltrackerbd-…`).
- Flow: PIN gate (`handlePinSubmit`, hardcoded `123456` / `1234`) → routine broadcast UI with
  three JSON templates (`Weak-Chapter Filler`, `Foundation Week`, `Mock-Heavy Final`),
  a JSON editor, validation, and publish.
- Writes to `doc(db, 'routines', <YYYY-MM-DD>)` **and** `doc(db, 'routines', 'current')`.

---

## 4. Data & persistence layers

| Layer | Used by | Keys / paths |
|---|---|---|
| `localStorage` | index.html (default path) | `medtrack_students`, `medtrack_seeded_v2`, `medical_tracker_v2` (`STORAGE_KEY`) |
| Firestore (compat) | index.html, **inactive** | `students/{uid}` |
| Firestore (modular) | admin.html, **active** | `routines/{date}`, `routines/current` |

---

## 5. Notable inconsistencies / risks

1. **Two disconnected front-ends.** `index.html` (compat SDK, `students` collection) and
   `admin.html` (modular SDK, `routines` collection) don't share a config, a data shape, or a link.
2. **`index.html` Firebase config is a placeholder** (`AIzaSyDUMMY_REPLACE_ME`), so `initFirebase()`
   always falls through to `localStorage` — cloud sync is effectively off for students.
   The real values sit in `firebase-applet-config.json` / `admin.html`.
3. **`src/` React scaffold is dead code** — `package.json`, `vite.config.ts`, `tsconfig.json`,
   Tailwind, lucide-react, motion and `@google/genai` are all installed but unused by the shipped HTML.
4. **Secrets committed**: real Firebase API key + OAuth client id in `firebase-applet-config.json`
   and inlined in `admin.html`.
5. **Auth is cosmetic**: admin password `17514` and admin PINs `123456`/`1234` are hardcoded in
   client JS; student PINs use a non-cryptographic djb2 hash.
6. **`firestore.rules` is fully open** (`allow read, write: if true`) on `/students/{uid}`,
   and has no rule at all for `/routines/*` that `admin.html` writes to.
7. `initApp()` can run twice (DOMContentLoaded listener + immediate readyState check).
8. `metadata.json` declares a server-side Gemini capability, but no Gemini call exists in the code,
   and there is no server (`express`/`tsx` are dependencies with no server file).
