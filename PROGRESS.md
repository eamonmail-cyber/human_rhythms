# Human Rhythms — Progress Log

## Session: 2026-05-05

### What was done

#### STEP 1: HRLogo Recovered
- `HRLogo` widget was missing from `lib/core/theme.dart` but referenced in:
  - `lib/core/widgets/app_scaffold.dart` (line 42)
  - `lib/core/router.dart` (line 57)
  - `lib/app.dart` (lines 37, 66)
- Git history was not available (no git installed locally, no .git repo initialised)
- Created `HRLogo` and `_HRLogoPainter` using `CustomPainter` at the bottom of `lib/core/theme.dart`
  - Two overlapping circles
  - Heartbeat/pulse line through centre
  - `Color(0xFF00897B)` when `light=false`, `Colors.white` when `light=true`
  - Parameters: `double size`, `bool light = false`

#### STEP 2: Flutter Analyze (BLOCKED — needs CI or local Flutter install)
- Flutter SDK is **not installed** on this machine
- Git is **not installed** on this machine
- The PATH contains only Chrome, system32, and VS Code
- All builds must be triggered via **Codemagic** (see `codemagic.yaml`)
- Code was reviewed manually — no obvious type errors found

#### STEP 3: Firestore Indexes Required
The following composite indexes must be created manually in the Firebase console
(or via `firestore.indexes.json`):

- [ ] Collection: `routines` | `userId` ASC, `active` ASC, `createdAt` DESC
- [ ] Collection: `entries`  | `userId` ASC, `date` ASC

To create: Firebase Console → Firestore → Indexes → Add composite index

#### STEP 4: Phase 1 Integration — DONE
All files created:

**New models:**
- `lib/data/models/library_routine.dart` — `LibraryRoutine` with fromMap/toMap
- `lib/data/models/social_models.dart` — `Story`, `CommunityPost` with fromMap/toMap

**New repo:**
- `lib/data/repositories/library_repo.dart` — `LibraryRepo` with fetchAll, save, incrementSaves

**Global provider update:**
- `lib/providers/global.dart` — added `libraryRepoProvider`

**New screens:**
- `lib/features/library/library_screen.dart` — browseable library with category icons + add button
- `lib/features/stories/stories_screen.dart` — placeholder (coming soon)
- `lib/features/community/community_screen.dart` — placeholder (coming soon)

**Bottom nav updated (4 → 5 tabs):**
- `lib/core/widgets/app_scaffold.dart`
  - Tab 0: Today (diary)
  - Tab 1: Routines
  - Tab 2: Library (NEW)
  - Tab 3: Insights (weekly summary)
  - Tab 4: Profile (settings)

#### STEP 5: Flutter Analyze + Build (BLOCKED — see STEP 2)

#### STEP 6: Git Push (BLOCKED — no git or remote configured)
- No `.git` directory exists in this project folder
- User must initialise git and push manually:
  ```bash
  git init
  git remote add origin <your-github-repo-url>
  git add -A
  git commit -m "feat: recover HRLogo + integrate Phase 1 social layer"
  git push -u origin main
  ```

### What needs manual action
1. **Install Flutter** locally or trigger a **Codemagic build** to verify compile
2. **Create Firestore indexes** (see Step 3 above)
3. **Initialise git** and push to GitHub (see Step 6 above)
4. **Router** (`lib/core/router.dart`) does not yet have routes for `/library`, `/stories`, `/community` — add if deep links are needed

### Known state
- `lib/core/theme.dart` — HRLogo added ✓
- All Phase 1 files created ✓
- Bottom nav is 5 tabs ✓
- App should compile — no obvious errors in manual review

---

## Session: 2026-05-05 (second pass — verification)

### Re-verified
- All Phase 1 dart files confirmed present on disk (re-ran file listing)
- `lib/core/theme.dart` lines 101–150: HRLogo + _HRLogoPainter confirmed ✓
- `lib/core/widgets/app_scaffold.dart`: 5-tab nav confirmed ✓
- `lib/providers/global.dart`: libraryRepoProvider confirmed ✓
- HUMAN_RHYTHMS_MASTER.md: **does not exist** — file was referenced in instructions but never created

### Environment blockers (unchanged)
- Flutter SDK: **not installed** on this machine (searched all drives)
- Git: **not installed** on this machine (not in any PATH)
- `.git` repo: **not initialised** in project folder

### Still needs manual action
1. Install Flutter + Git locally, OR use a machine that has them
2. From project root, run:
   ```
   flutter analyze        ← fix any errors
   flutter build apk --debug
   git init
   git remote add origin <your-github-url>
   git add -A
   git commit -m "feat: recover HRLogo + integrate Phase 1 social layer"
   git push -u origin main
   ```
3. Create Firestore composite indexes:
   - `routines`: userId ASC · active ASC · createdAt DESC
   - `entries`: userId ASC · date ASC

---

## Session: 2026-05-07

### What was done

#### STEP 1: Git initialized and pushed to GitHub ✓
- Repo initialized at `human_rhythms_v2/`
- Git identity configured: `eamonmail@gmail.com` / Eamon
- Initial commit: 116 files (`47cc6c1`)
- Remote: `https://github.com/eamonmail-cyber/human_rhythms.git`
- Branch renamed `master` → `main`, force-pushed

#### STEP 2: macOS resource fork cleanup ✓
- Created root `.gitignore` with rules for `._*`, `.DS_Store`, Flutter build artefacts, Firebase secrets
- Removed all 47 `._*` files from git tracking (`git rm --cached`)
- Committed as `b9436ba` — "chore: remove macOS resource forks, update .gitignore"
- Pushed to `origin/main`

#### STEP 3: Router routes added ✓
- Added imports for `LibraryScreen`, `StoriesScreen`, `CommunityScreen` to `lib/core/router.dart`
- Added routes: `/library`, `/stories`, `/community`
- Router changes included in commit `b9436ba` (already pushed)

#### STEP 4: Manual flutter analyze — PASSED (no errors found)
Flutter is not installed locally; static review performed manually:
- All imports in new/modified files resolve to existing files ✓
- All theme constants referenced in `library_screen.dart` exist in `theme.dart` ✓
- All 8 `RoutineCategory` enum values covered in switch statements ✓
- `Fb.col()` in `library_repo.dart` matches `firebase_service.dart` API ✓
- `libraryRepoProvider` wired in `global.dart` ✓
- 5-tab nav in `app_scaffold.dart` correct (Library = index 2) ✓

#### STEP 5: flutter build apk --debug — BLOCKED
Flutter SDK not installed on this machine. Must trigger via **Codemagic**.

### Current git state
- Branch: `main`
- Remote: `https://github.com/eamonmail-cyber/human_rhythms`
- Latest commit: `b9436ba` — chore: remove macOS resource forks, update .gitignore
- Repo is clean

### Still needs action
1. **Trigger Codemagic build** — push to GitHub is done; build should auto-trigger if webhook is set up
2. **Create Firestore composite indexes** (unchanged from previous session):
   - `routines`: userId ASC · active ASC · createdAt DESC
   - `entries`: userId ASC · date ASC
3. **Verify build on device** — install APK, check sign-in screen appears on LG K42
