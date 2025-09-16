# Human Rhythms – MVP Backlog (Issues)

Copy items into GitHub Issues or use `tool/create_github_issues.sh` with GitHub CLI.

## MVP – Must Have
1. **Auth: Google + Email**  
   - Implement Firebase Auth UI flows.  
   - AC: user can sign in/out, userId provider wired to auth.

2. **Persist Entries**  
   - Wire `EditEntrySheet` save to Firestore (`entries` collection).  
   - Use uuid for doc ids; include date, timeBucket, status, intensity, duration, note.

3. **Outcome Chip (🙂😐🙁)**  
   - Add to Diary header; persists to `outcomes` (today).  
   - Show latest value when revisiting day.

4. **Routine Editor**  
   - Create, edit, delete routines (title, category, frequency, targetTime).  
   - Show user routines in Diary by time buckets.

5. **Weekly Summary Calculations**  
   - Compute averages and basic correlations (sleep vs energy).  
   - Display 1–3 insights as neutral statements.

6. **Firestore Security Rule Audit**  
   - Verify read/write only for owner.  
   - Add rules tests (optional).

7. **Accessibility Pass**  
   - Large text, color contrast, semantics labels for bubbles.  

8. **Settings: Privacy Copy**  
   - Explain “private by default”; add local lock toggle (placeholder).

## Nice to Have (MVP+)
9. **Self-Award Badges Sheet**  
   - Bottom sheet to pick ⭐ 🥇 💡 and save to `badges` (with optional label).

10. **Month Map View**  
   - Calendar grid with micro-bubbles per day, “+N” overflow.

11. **Reminder Scaffolding**  
   - Local notifications placeholder; schedule by `targetTime`.

12. **Dark Mode**  
   - Respect system theme; test bubble contrast.

13. **Export (CSV/JSON)**  
   - Export entries + outcomes for a date range.

14. **Offline Support**  
   - Ensure Firestore persistence enabled; UX for pending writes.

## Future (Phase 2)
15. **Apple Health / Google Fit Hooks**  
   - Steps & sleep ingestion with user consent.

16. **AI-lite Insights**  
   - Natural-language weekly insight summary (on-device first).

17. **Community Library (Private Templates)**  
   - Share routine template (anon or named); adopt into own diary.

18. **Moderation Hooks**  
   - Toxicity filter placeholder; report flow.
