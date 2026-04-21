# Nearshore Recruitment Portal

A single-file web portal for tracking open positions, candidates, interviews, and new-hire onboarding. Built to replace the `Nearshore_Recruitment_Tracking.xlsx` spreadsheet with a collaborative, dashboard-driven tool that deploys to GitHub Pages with no build step.

## What's inside

One file: **`index.html`** (~102 KB). Everything is inlined — HTML, CSS, the seeded data from the source spreadsheet, and all JavaScript. The file loads four libraries from public CDNs:

| Library | Purpose |
|---|---|
| Alpine.js 3 | reactivity and UI state |
| Tailwind CSS v4 (browser build) | layout and utilities |
| Chart.js 4 | dashboard charts |
| html2pdf.js | PDF export |

No build step. No npm install. Open the file directly in a browser and it works.

## Features

**Dashboard** — KPI cards (open positions, active candidates, interviews this week, filled positions), four charts (priority breakdown, candidate status, candidates per position, positions by leader), upcoming interview list, high-priority queue.

**Open / Closed Positions** — filterable/searchable table with columns for number, title, target role, certification, leader, manager, director, VP, priority, status, candidate count, and notes. Click a row to edit inline or close a position (moves it to the Closed tab with an outcome).

**Candidates** — master list of everyone submitted, linked to their position. Status editable inline from the table. Manager / Director / VP captured per candidate. Interview dates, resume-on-file flag, and notes included. Filters for status, position, resume status, and free-text search.

**Onboarding** — card-per-employee checklist for provisioning tickets (AD account, application access, hardware, Epic access, etc.). Progress % updates as you check off items.

**Reports** — one-click full-status PDF (dashboard + positions + candidates + onboarding, ~3 pages letter size, text-searchable). Weekly Status generator that summarizes the last 7 days of activity and next 7 days of interviews. JSON export/import for backups. Shareable read-only URL for clients.

**Access Protection** — optional end-to-end encryption. Set a passphrase and all portal data (local storage + Gist) is encrypted with AES-256-GCM before being written. Reload the portal and you get a lock screen; without the passphrase, data is unreadable even to someone who has your GitHub token.

**Settings** — company name, portal title, optional Gist-based shared storage, and passphrase protection controls.

---

## Access Protection — how the passphrase works

When you enable passphrase protection in Settings, the portal uses the browser's built-in WebCrypto API to derive a 256-bit AES key from your passphrase using PBKDF2 (120,000 iterations, SHA-256) and a random 128-bit salt. All data is then encrypted with AES-GCM before being stored, both in browser localStorage and in the shared Gist.

**What this actually protects:**

- Someone opening the portal URL without the passphrase sees only the lock screen. They can't read positions, candidates, interview notes, or any other data — all they see in localStorage or the Gist is ciphertext.
- A collaborator with the GitHub token (needed for Gist sync) still can't read the data without the passphrase. The token gives them access to the ciphertext; only the passphrase unlocks it.
- The passphrase is never transmitted, never saved to localStorage, never appears in the HTML. It lives in a JavaScript variable that's cleared when you click Lock, close the tab, or the browser evicts the page.

**What it doesn't protect:**

- Anyone you share the passphrase with can read and edit everything. Same trust model as any shared password.
- A browser with a keylogger or malicious extension can capture the passphrase when you type it.
- If you lose the passphrase, there is no recovery. The data is gone. Use a password manager.

**How to enable:**

1. Open the portal → Settings (top right)
2. Scroll to "Access Protection" → click **Enable Passphrase Protection**
3. Enter a passphrase (minimum 6 characters; 12+ alphanumeric recommended) and confirm it
4. Click **Enable Protection**. The portal re-encrypts all data in place and pushes the encrypted payload to the Gist (if configured)
5. Reload the page — you'll see the lock screen
6. Enter the passphrase to unlock

**How to share with collaborators:**

Send them three things through separate secure channels (password manager sharing is ideal):

1. The portal URL (`https://<you>.github.io/recruitment-portal/`)
2. The Gist ID + GitHub PAT (for shared storage)
3. The passphrase

They paste Gist ID and PAT into Settings, reload, and are prompted for the passphrase. Don't email all three together.

**Read-only clients with encryption:** Clients using `?view=readonly` also need the passphrase. Either share it with them directly, or create a separate un-encrypted "client view" Gist that you manually export data to periodically.

**Recovery options if a passphrase is lost:**

- Ask a teammate who has it
- Restore from a plain-text JSON backup exported before encryption was enabled
- Use the Gist's revision history (gist.github.com → your gist → "Revisions") to restore an older pre-encryption version
- As a last resort, click "Wipe local data" on the lock screen and re-seed

**Performance:** PBKDF2 at 120k iterations adds ~200ms to each unlock and each save operation. You'll notice a tiny pause; it's intentional — higher iteration counts make offline brute-force attacks proportionally more expensive.

---

## Deploying to GitHub Pages

### Option A — Automated (recommended if you have `gh` CLI)

From this folder, run:

```bash
./deploy.sh
```

The script will:
1. Initialize a git repo
2. Commit the files
3. Create a new public GitHub repo named `recruitment-portal` (you'll be prompted if not authenticated)
4. Push the code
5. Enable GitHub Pages on the `main` branch
6. Print the public URL (usually `https://<your-username>.github.io/recruitment-portal/`)

Takes about 30 seconds once `gh` is authenticated.

### Option B — Manual

1. Create a new GitHub repo (public or private — Pages works on both with a paid plan; free accounts need public). Call it whatever you like, e.g. `recruitment-portal`.
2. Upload `index.html` to the root of the repo (drag-and-drop in the web UI works).
3. In the repo → **Settings** → **Pages** → under **Source**, choose **Deploy from a branch** → **main** / **`/` (root)** → **Save**.
4. Wait ~1 minute for the green checkmark. Your URL is `https://<username>.github.io/<repo-name>/`.

That's it. The portal is live.

---

## Data storage — three modes

The portal starts with **14 open positions, 6 closed positions, 15 candidates, and 2 onboarding records** seeded from the spreadsheet. There are three ways to store your edits:

### 1. Local-only (default) — zero setup

All data is saved to `localStorage` in whatever browser you're using. Changes persist across page reloads but **don't sync to other people or other devices**. Good for a single admin working solo, or for trying things out.

### 2. JSON export / import — manual backup

On the Reports tab, click **Export JSON** to download a full backup. Anyone else can click **Import JSON** to load it into their browser. Good for occasional hand-off or archiving. Not live-sync — each import replaces what was there.

### 3. GitHub Gist sync — live shared storage

This is the closest thing to a real backend on GitHub Pages. All users who configure the same Gist ID + token read and write the same data. Set it up once per collaborator:

**Step 1 — Create a Gist to hold the data**
1. Go to <https://gist.github.com>
2. Filename: `recruitment-data.json`
3. Content: `{"data":{"positions":[],"candidates":[],"onboarding":[]}}` (just a placeholder — the portal will overwrite on first push)
4. Click **Create secret gist** (secret ≠ private; it's unlisted but anyone with the URL can read)
5. Copy the Gist ID from the URL: `gist.github.com/<username>/`**`<GIST_ID>`**

**Step 2 — Create a Personal Access Token**
1. Go to <https://github.com/settings/tokens> → **Generate new token (classic)**
2. Name: `recruitment-portal`
3. Expiration: whatever you're comfortable with
4. Scopes: check **`gist`** only — nothing else
5. Click **Generate token** and copy it (starts with `ghp_...`) — you won't see it again

**Step 3 — Configure the portal**
1. Open the portal, click **Settings** (top-right)
2. Paste the Gist ID and token
3. Click **Test Connection** — you should see "Connection OK"
4. Click **Push to Gist** to upload your current data
5. Click **Save & Close**

From now on, saves automatically push to the Gist after a 2-second debounce. When the portal loads, it pulls from the Gist first.

**For each additional collaborator:** send them the portal URL, the Gist ID, and the PAT. They paste the same values into their Settings and they're connected.

---

## Sharing with clients (read-only)

On the Reports tab, click **Copy share link**. This generates a URL like:

```
https://<your-username>.github.io/recruitment-portal/?view=readonly&gist=<GIST_ID>
```

Clients who open this URL see the dashboard, positions, candidates, and reports but **cannot** add, edit, or delete anything. The `?view=readonly` flag disables all edit controls. They'll still need the PAT to load the Gist data — so for true client-facing use, send them the token separately, or set up a proxy (see security caveat below).

---

## ⚠ Security model — what protects what

The Gist sync mechanism stores a GitHub Personal Access Token in the browser's localStorage. That token gives read/write access to all of your gists (GitHub's `gist` scope isn't gist-specific), and is visible to anyone who opens DevTools on a logged-in machine.

**If you enable passphrase protection** (recommended for anything beyond demo use), the threat model improves substantially: even if someone obtains the PAT, the Gist contents are AES-256 ciphertext. They can delete the Gist (a denial-of-service attack on your team) but they cannot read recruiting data or learn about candidates.

**If you don't enable passphrase protection,** treat the PAT like a shared spreadsheet link — fine for the internal ACS team, not appropriate to hand to external clients.

**For the cleanest client-facing story** — where external viewers should see some data but not all, or where you want separate read-only and read-write accounts — you want a real backend. Two straightforward paths:

- **Supabase free tier** (~15 minutes of setup) — swap the Gist-sync functions for Supabase calls. Row-level security gives you real read-only client accounts without exposing any write tokens or passphrases.
- **Firebase Firestore** — same idea, different vendor.

I can stub either in if you want to go that route. For the internal team + encrypted Gist model, what ships here is sufficient.

---

## Data model reference

If you're importing data from another source or writing your own sync layer, here's the JSON schema the portal expects:

```json
{
  "data": {
    "positions": [
      {
        "id": "p-open-1",
        "number": "1",
        "title": "Sr Systems Analyst (Grace Faulds)",
        "status": "OPEN",
        "targetRole": "Sr Systems Administrator",
        "certification": "ServiceNow Certs",
        "leader": "Carole",
        "manager": "",
        "director": "",
        "vp": "",
        "priority": "TBD",
        "notes": "More information Needed...",
        "isClosed": false,
        "outcome": "",
        "createdAt": "2026-04-01",
        "closedAt": ""
      }
    ],
    "candidates": [
      {
        "id": "c-1",
        "name": "Gerardo Moreno",
        "role": "Senior BI Developer",
        "positionId": "p-open-7",
        "manager": "Anna Straus",
        "director": "John O'Toole",
        "vp": "Jawad Khan",
        "status": "Interview Scheduled",
        "resumeReceived": false,
        "interviewDate": "2026-04-23",
        "notes": ""
      }
    ],
    "onboarding": [
      {
        "id": "o-jesus-andrade",
        "employeeName": "Jesus Andrade",
        "startDate": "",
        "items": [
          { "type": "New Hire AD Account", "ticket": "RITM0140540", "status": "Submitted" }
        ]
      }
    ]
  },
  "settings": {
    "companyName": "ACS Staffing",
    "portalTitle": "Nearshore Recruitment Portal"
  }
}
```

Candidate status values: `Submitted`, `Pending Interview`, `Interview Scheduled`, `Interview Complete`, `Offered`, `Hired`, `Rejected`, `Closed`, `On Hold`.

Position status values: `OPEN`, `NEW/Growth`, `Repurpose`, `Open / Contract`, `Closed`.

Priority values: `High`, `Medium`, `Low`, `TBD`.

---

## Customizing

**Company name / portal title** — Settings modal, top of the panel.

**Seeded data** — the initial dataset is inlined in the JS as `const SEED = {...}`. To start blank, open Settings and click **Clear All Data**. To start fresh with your own seed data, use **Import JSON**.

**Brand colors** — search the `<style>` block for hex values. Primary is `#0E1A2B` (deep navy ink), accent is `#B45309` (burnt amber), paper is `#FAFAF7`. Fonts are IBM Plex Sans + IBM Plex Mono + Fraunces (loaded from Google Fonts).

**Adding columns** — the position and candidate data models are open objects, so you can add fields. You'll need to edit the modal forms and the table headers in `index.html` to expose them in the UI.

---

## Multi-user editing — how conflicts are handled

The portal supports shared editing via GitHub Gist sync with two safety mechanisms:

**Polling (30s):** When Gist sync is active, the portal polls the remote every 30 seconds. If someone else has pushed changes and you have no unsaved local edits, your view auto-refreshes with their changes. If you *do* have local edits pending, a blue notification bar appears at the top: "Someone else updated the portal" with buttons to either push your version (overwriting theirs) or reload theirs (discarding yours).

**Conflict detection on push:** Before every push to the Gist, the portal checks the server's current `updated_at` timestamp against the baseline it loaded from. If they don't match, the push is blocked and a conflict modal appears with three options: Export JSON first (safest), Overwrite theirs, or Reload theirs.

This isn't a real-time CRDT — two people editing the same field at the same moment will still produce a conflict. But it eliminates silent data loss: you'll always see the conflict and get to decide.

**Rate limits:** GitHub API allows 5,000 authenticated requests/hour. The poll loop uses ~120/hour. The push debounce (2 seconds) keeps edit-burst pushes well under the limit.

## Data safety

The portal automatically tracks when you last exported JSON or pushed to the Gist. If you're running local-only (no Gist configured) AND your last backup was more than 7 days ago (or never), an amber warning banner appears at the top of the page with one-click buttons to export JSON or configure Gist sync. You can dismiss it — it'll reappear in 7 days.

For peace of mind: if you configure Gist sync, every edit auto-syncs within 2 seconds. The banner stays out of the way when you're protected.

## PDF output

The full-status and weekly-status PDFs are generated with jsPDF + jspdf-autotable, producing real text (not a rasterized image). That means: text is selectable and searchable in any PDF viewer, file sizes are small (typically 100-200 KB for the full report), and the report scales cleanly on any screen or print size.

## Candidate-to-position linking

The seed data links all 15 candidates from the source spreadsheet to their target positions. Three candidates (Nestor, Andres, and Janner) are linked to the BI Developers role based on their Analytics role and the shared Manager/Director/VP chain (Anna Straus / John O'Toole / Jawad Khan). If any are mislinked for your workflow, open the candidate edit modal and change the Linked Position dropdown.

---

## Things this portal still can't do

A few honest boundaries — things you'd notice if you really stressed the tool:

- **Sub-30-second collaboration latency.** Two people editing simultaneously will see each other's changes within about 30 seconds; true real-time requires WebSockets and a proper backend.
- **Audit history.** There's no change log. If you delete a position by accident, the only recovery path is a JSON backup you exported earlier (or the Gist's revision history — Gists keep all revisions, so you can also restore from there via gist.github.com).
- **Attachments.** The portal tracks a "Resume on file" boolean but doesn't store actual resume files. Use your existing doc store (SharePoint, Google Drive) for those and reference them in the Notes field.
- **Access control beyond read/write.** Gist-sync users are all equal — anyone with the token can edit. Fine-grained roles (recruiter-only, hiring-manager-only, client-read-only) would require a real auth system.
- **Mobile.** The UI is tested on desktop browsers at 1280px+. It'll load on a phone but the tables will overflow. Most recruiting work happens on laptops anyway.

---

## Support and feedback

This was built in a single session from the Nearshore spreadsheet. If something's broken or missing a feature you need, file it in the repo issues or edit the HTML directly — it's one file and it's readable.
