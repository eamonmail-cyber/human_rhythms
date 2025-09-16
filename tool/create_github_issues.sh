#!/usr/bin/env bash
# Requires: GitHub CLI `gh` authenticated (`gh auth login`).
# Usage: ./tool/create_github_issues.sh <owner/repo>

set -euo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "Usage: $0 <owner/repo>"
  exit 1
fi

echo "Creating MVP issues in $REPO ..."

gh issue create --repo "$REPO" --title "Auth: Google + Email" --label "MVP" --body "Implement Firebase Auth UI flows. AC: user can sign in/out, userId provider wired to auth."
gh issue create --repo "$REPO" --title "Persist Entries" --label "MVP" --body "Wire EditEntrySheet save to Firestore (\`entries\`). Include date, timeBucket, status, intensity, duration, note."
gh issue create --repo "$REPO" --title "Outcome Chip (🙂😐🙁)" --label "MVP" --body "Add to Diary header; persist to \`outcomes\`. Show latest value when revisiting day."
gh issue create --repo "$REPO" --title "Routine Editor" --label "MVP" --body "Create/edit/delete routines (title, category, frequency, targetTime). Show user routines in Diary."
gh issue create --repo "$REPO" --title "Weekly Summary Calculations" --label "MVP" --body "Compute averages and basic correlations; display 1–3 neutral insights."
gh issue create --repo "$REPO" --title "Firestore Security Rule Audit" --label "MVP" --body "Verify read/write only for owner; consider rules tests."
gh issue create --repo "$REPO" --title "Accessibility Pass" --label "MVP" --body "Large text, contrast, semantics on bubbles."
gh issue create --repo "$REPO" --title "Settings: Privacy Copy" --label "MVP" --body "Explain private-by-default; local lock toggle placeholder."

gh issue create --repo "$REPO" --title "Self-Award Badges" --label "enhancement" --body "Bottom sheet to pick ⭐ 🥇 💡; save to \`badges\` with optional label."
gh issue create --repo "$REPO" --title "Month Map View" --label "enhancement" --body "Calendar grid with micro-bubbles per day; '+N' overflow."
gh issue create --repo "$REPO" --title "Reminder Scaffolding" --label "enhancement" --body "Local notification placeholder using targetTime."
gh issue create --repo "$REPO" --title "Dark Mode" --label "enhancement" --body "Respect system theme; ensure bubble contrast."
gh issue create --repo "$REPO" --title "Export CSV/JSON" --label "enhancement" --body "Export entries + outcomes by date range."
gh issue create --repo "$REPO" --title "Offline Support" --label "enhancement" --body "Enable Firestore offline; UX for pending writes."

gh issue create --repo "$REPO" --title "Apple Health / Google Fit Hooks" --label "phase-2" --body "Ingest steps & sleep with consent; platform channels."
gh issue create --repo "$REPO" --title "AI-lite Weekly Insights" --label "phase-2" --body "Natural-language summaries with transparent phrasing."
gh issue create --repo "$REPO" --title "Community Library (Templates)" --label "phase-2" --body "Share routine templates (anon or named); adopt into diary."
gh issue create --repo "$REPO" --title "Moderation Hooks" --label "phase-2" --body "Toxicity filter placeholder; report flow."
echo "Done."
