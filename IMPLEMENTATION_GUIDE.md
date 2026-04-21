# Recruitment Portal — Implementation Guide

**What you'll have when you're done:** A web portal at `https://<your-username>.github.io/recruitment-portal/` for tracking positions, candidates, interviews, and onboarding. Data auto-saves to a shared backend. All data is encrypted with a team passphrase. **End users open the URL, enter the passphrase, and they're in — nothing else to configure.**

**Total time:** 25 minutes for the admin (one time). **30 seconds for each team member or client.**

---

## Two roles, two workflows

| Role | Who | Needs | Time |
|---|---|---|---|
| **Admin** | One person who sets everything up | GitHub account, 25 minutes | Once |
| **End user** | Every team member and client | A URL and a passphrase | 30 seconds |

After admin setup, the admin generates a customized `index.html` with the Gist ID and an encrypted GitHub token baked in. Users of that file only need the passphrase — no Settings, no credential pasting.

---

## Architecture

```
┌───────────────────────┐     ┌──────────────────────────┐     ┌───────────────────────┐
│   User A's browser    │◄───►│    GitHub Gist (JSON)    │◄───►│   User B's browser    │
│   Opens portal URL    │     │   = the backend          │     │   Opens portal URL    │
│   Enters passphrase   │     │   - AES-256 encrypted    │     │   Enters passphrase   │
│   Uses portal         │     │   - Full revision history│     │   Uses portal         │
└───────────────────────┘     └──────────────────────────┘     └───────────────────────┘
         ▲                                                                ▲
         └────────── auto-sync every 30 seconds ─────────────────────────┘
```

Portal HTML lives on **GitHub Pages** (free static hosting). Data lives in a **GitHub Gist** (free versioned JSON). The GitHub token is baked into the HTML as **encrypted ciphertext** — meaningless without the passphrase.

---

# Part 1 — Admin Setup (25 minutes, once)

## 1.1 Prerequisites

- A **GitHub account** — create at <https://github.com/signup>
- The files from this package: `index.html`, `README.md`, `deploy.sh`
- A **password manager** (1Password, Bitwarden, LastPass) for storing the passphrase and token
- Optional: `gh` CLI (<https://cli.github.com>) for automated deploy

## 1.2 Deploy to GitHub Pages

### Option A — Automated (with `gh` CLI)

```bash
gh auth login              # one time
chmod +x deploy.sh
./deploy.sh                # creates repo, pushes, enables Pages, prints URL
```

### Option B — Manual (web UI)

1. Create repo at <https://github.com/new>: name `recruitment-portal`, Public, no README
2. Drag-drop `index.html`, `README.md`, `deploy.sh` into the upload area → commit
3. Settings → Pages → Source: "Deploy from a branch" → main / (root) → Save
4. Wait ~60 seconds, copy the URL near the top

## 1.3 Create the Gist backend

1. Go to <https://gist.github.com>
2. Filename: exactly **`recruitment-data.json`**
3. Content: `{"data":{"positions":[],"candidates":[],"onboarding":[]}}`
4. Click dropdown next to Create → **Create secret gist**
5. Copy the Gist ID from the URL (the long hex after your username). Save in password manager.

## 1.4 Create a GitHub Personal Access Token

1. <https://github.com/settings/tokens> → **Generate new token (classic)**
2. Name: `Recruitment Portal Shared`
3. Expiration: 1 year (or whatever you'll remember to rotate)
4. **Scopes: check ONLY `gist`** — nothing else
5. Generate → **copy the token now** (shown only once) → save in password manager

## 1.5 Configure the portal and enable encryption

1. Open your portal URL in a browser
2. Click **Settings** (top right)
3. Fill in Company Name and Portal Title
4. Paste the **Gist ID** and **GitHub Token**
5. Click **Test Connection** — wait for green success
6. Click **Push to Gist** — uploads seed data
7. Scroll to **Access Protection** → **🔒 Enable Passphrase Protection**
8. Choose a passphrase (12+ chars, letters/numbers/symbols). **Save in password manager.**
9. Click **Enable Protection**

**Checkpoint:** refresh the URL. You should see the dark lock screen. Enter the passphrase — data loads.

## 1.6 Generate the Team Deployment file

This turns admin setup into a zero-config link for everyone.

1. In Settings, scroll to **Team Deployment**
2. Click **📦 Generate Team Deployment File**
3. A customized `index.html` downloads containing:
   - Your Gist ID (plaintext — it's just an unlisted URL)
   - Your GitHub token encrypted with the team passphrase
   - Company/portal names
4. Read the alert's next steps — do 1.7 immediately.

## 1.7 Replace the deployed index.html

### With `gh` / command line

```bash
# From your deploy folder
cp ~/Downloads/index.html ./index.html
git add index.html
git commit -m "Bake team config"
git push
```

### Via web UI

1. On github.com, open `index.html` in your repo → pencil icon to edit
2. Select all → delete
3. Open the downloaded file in a text editor → select all → copy → paste into GitHub editor
4. Scroll → **Commit changes**

Alternative: delete `index.html` in repo → drag-drop the downloaded one. GitHub Pages rebuilds in ~60 seconds.

## 1.8 Verify end-user experience

1. Open a **private/incognito window** (fresh state)
2. Go to your portal URL → lock screen appears
3. Enter passphrase → dashboard loads

What every user will see from now on.

**Admin setup complete.**

---

# Part 2 — Onboarding Team Members & Clients (30 seconds each)

## What to share

Two things, through secure channels (password manager sharing, encrypted vault, in-person):

1. **Portal URL** — `https://your-username.github.io/recruitment-portal/`
2. **Passphrase** — from step 1.5

**That's it.** No Gist ID, no token, no technical steps.

## What they do

1. Click URL
2. Enter passphrase
3. Use the portal

Lock screen decrypts the embedded token, fetches the encrypted Gist, decrypts the data — ~2 seconds.

## Read-only access for clients

Give clients: URL + `?view=readonly` appended, plus the passphrase:

```
https://your-username.github.io/recruitment-portal/?view=readonly
```

They can view dashboards, tables, reports, and download PDFs. All edit buttons are hidden.

## Quick-reference card

```
RECRUITMENT PORTAL — ACCESS
════════════════════════════
URL:        https://<your-username>.github.io/recruitment-portal/
Passphrase: <shared via 1Password link>

1. Open URL
2. Enter passphrase  
3. Use the portal

Clients (read-only): append ?view=readonly to the URL
Lock button (top-right) clears your session
```

---

# Part 3 — Day-to-day

## Common tasks

- **Add a position:** sidebar → New Position → Save
- **Update candidate status:** Candidates tab → Status dropdown → auto-saves
- **Schedule interview:** Candidates → Edit → Interview Date → Save
- **Mark position filled:** Positions → Edit → Status=Closed + Outcome → Save (moves to Closed tab)
- **Full status PDF:** Reports → Download Full Status PDF (text-searchable)
- **Weekly status:** Reports → Generate Weekly Status → Download as PDF
- **Lock session:** click Lock (top right) before stepping away

## How sync works

1. Edit → saves to localStorage immediately
2. After 2 sec of no edits → portal checks if Gist has newer data than baseline
3. No conflict → pushes encrypted data to Gist
4. Every 30 sec → every user polls the Gist
5. No pending local edits → auto-refresh with remote changes
6. Pending local edits + remote also changed → blue "Someone else updated" bar

## Conflict handling

Simultaneous edits → Sync Conflict modal:
- **Export JSON first** (safest — download your version before overwriting)
- **Reload theirs** (discard local, get remote)
- **Overwrite theirs** (push local, remote edits lost — avoid unless certain)

Gist revisions preserve everything anyway.

---

# Part 4 — Backup and recovery

## Built-in: Gist revisions

GitHub keeps every Gist revision forever.

1. `https://gist.github.com/<your-username>/<gist-id>`
2. Click **Revisions**
3. Find the version to restore
4. Copy content → Portal → Reports → Import JSON

## Manual weekly backup

Reports → **Export JSON** → save to shared drive. **Exported JSON is plain text** (intentional — restore doesn't need the passphrase).

---

# Part 5 — Admin maintenance

## Changing the passphrase

1. Open portal, enter current passphrase
2. Settings → Access Protection → **Change Passphrase**
3. Data re-encrypts automatically
4. **Regenerate Team Deployment** (Settings → Generate Team Deployment File) → upload the new file replacing `index.html` in your repo
5. Share new passphrase via password manager

## Rotating the GitHub token

Keep a **separate admin copy** of the portal that isn't baked — it retains the Settings fields for editing Gist/Token. Two good options:

- **Local copy:** keep an un-baked `index.html` in a folder on your computer. Open via file:// for admin operations.
- **Admin branch:** in your GitHub repo, keep the un-baked version on a `main-admin` branch. Switch between branches as needed.

To rotate:
1. Generate new token at <https://github.com/settings/tokens> (same `gist` scope)
2. Open your un-baked admin version, enter passphrase
3. Settings → paste new token → **Generate Team Deployment File**
4. Upload new baked HTML to repo (replacing `index.html`)
5. Revoke old token at GitHub

## Removing a team member

1. Settings → Change Passphrase (new value)
2. Regenerate Team Deployment
3. Share new passphrase only with remaining members
4. Former member's cached copy is useless without the new passphrase

## When to outgrow this

Switch to a real backend (Supabase, Firebase) if you need:
- More than ~20 simultaneous editors
- Per-user logins
- Role-based permissions (recruiter/manager/client)
- Audit log of changes
- API integration with other tools

---

# Part 6 — Troubleshooting

| Problem | Fix |
|---|---|
| "Incorrect passphrase" but you're sure | Caps lock, autocorrect, case-sensitivity. Admin may have rotated recently — ask them. |
| "My edit didn't save" | Check top-right: `● Synced · Gist` is good. If error, refresh page. Persists? Admin needs to check/rotate token. |
| "Can see but can't edit" | URL contains `?view=readonly`. Remove it for edit access. |
| "Someone's change is gone" | Gist → Revisions → find the version with their change → copy → Portal → Reports → Import JSON. |
| "I forgot the passphrase" (admin) | Password manager. If truly lost: Gist → Revisions → find pre-encryption version → restore; else: re-seed from original. |
| "Unlock button does nothing" | PBKDF2 derivation takes ~200ms. Wait 2-3 sec. Hit Enter in input. F12 for console errors. |
| "Slow to load" | Network may be blocking jsdelivr CDN. Test: open <https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4> directly. |

---

# Part 7 — Security checklist

- [ ] Unique credentials — token, passphrase, GitHub password all different
- [ ] Everything in a password manager — never email/Slack/SMS
- [ ] Use password manager's secure-share for onboarding
- [ ] Rotate token annually
- [ ] Rotate passphrase when someone leaves
- [ ] Click Lock before stepping away
- [ ] Never commit token or passphrase to any repo
- [ ] Review token activity periodically at <https://github.com/settings/tokens>
- [ ] Keep admin file separate from deployed file

---

# Part 8 — Costs and limits

| Item | Cost | Limit | You'll use |
|---|---|---|---|
| GitHub Pages hosting | Free | 100 GB/mo bandwidth | <1 GB |
| Gist storage | Free | 10 MB per file | ~1 KB per position+candidate |
| GitHub API | Free | 5,000 req/hr per token | ~150/hr per user |
| Concurrent users | No limit | Smooth to ~20 | ? |

You will not hit any of these with a normal recruiting team.

---

# Appendix: what the baked file contains

Open the customized `index.html` in a text editor and search for `PORTAL_CONFIG`:

```html
<!-- PORTAL_BAKED_V1_START -->
<script id="portal-baked-config">
window.PORTAL_CONFIG = {
  "gistId": "abc123def456...",
  "encryptedToken": {
    "encrypted": true,
    "version": 1,
    "salt": "base64...",
    "iv": "base64...",
    "ciphertext": "base64..."
  },
  "companyName": "ACS Staffing",
  "portalTitle": "Nearshore Recruitment Portal"
};
</script>
<!-- PORTAL_BAKED_V1_END -->
```

**Why publishing this is safe:**

- `gistId` is just an unlisted URL. Knowing it without the token gets you nothing.
- `encryptedToken` is AES-256-GCM ciphertext. Without the passphrase, it's unusable bytes.
- `salt` and `iv` are random and are *meant* to be public per the crypto spec.

To actually read any recruiting data, someone would need the baked HTML **and** the passphrase. One without the other is useless.
