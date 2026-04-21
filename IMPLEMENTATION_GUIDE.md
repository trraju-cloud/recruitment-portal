# Recruitment Portal — Implementation Guide

**What you'll have when you're done:** A web portal at `https://<your-github-username>.github.io/recruitment-portal/` that your team uses to track open positions, candidates, interviews, and onboarding. Every edit auto-saves to a shared GitHub Gist that acts as the database. Every user sees every update within 30 seconds. All data is encrypted with a team passphrase. GitHub keeps a full revision history so nothing is ever permanently lost.

**Total time to deploy:** 25–30 minutes for the first person. 5 minutes per additional team member.

**No server to maintain. No recurring cost. No vendor lock-in.**

---

## Architecture at a glance

```
┌─────────────────────┐       ┌──────────────────────────┐       ┌─────────────────────┐
│                     │       │                          │       │                     │
│   User A's browser  │◄─────►│    GitHub Gist (JSON)    │◄─────►│   User B's browser  │
│  (portal HTML from  │       │   = the backend/database │       │  (portal HTML from  │
│   GitHub Pages)     │       │   - Encrypted AES-256    │       │   GitHub Pages)     │
│                     │       │   - Full revision history│       │                     │
└─────────────────────┘       └──────────────────────────┘       └─────────────────────┘
         ▲                                                                  ▲
         │                                                                  │
         └────────────── auto-sync every 30 seconds ───────────────────────┘
```

The portal code lives on **GitHub Pages** (free static hosting). The data lives in a **GitHub Gist** (free versioned JSON storage). Every user's browser reads/writes the same Gist using a shared token. AES-256 encryption protects the data so that even someone with the token can't read it without the passphrase.

---

## Prerequisites

Before you start, you need:

- [ ] A **GitHub account**. Create one at <https://github.com/signup> if you don't have one. Free tier is fine.
- [ ] The three files from this package on your local machine: `index.html`, `README.md`, `deploy.sh`.
- [ ] About 30 minutes of uninterrupted time for the initial setup.
- [ ] A password manager (1Password, Bitwarden, LastPass, etc.) to store the team passphrase and the GitHub token. You'll be sharing both with your team, and email/Slack is not the right place for them.

Optional but recommended:
- [ ] The `gh` command-line tool (<https://cli.github.com>) — lets you deploy with one script instead of clicking through the web UI. Install takes 2 minutes.

---

## Part 1 — Deploy the portal to GitHub Pages

### Option 1A: Automated (uses the deploy.sh script)

From a terminal, in the folder containing `index.html`:

```bash
# One-time: install the GitHub CLI
brew install gh              # macOS
# OR: winget install --id GitHub.cli    # Windows
# OR: see https://cli.github.com/ for Linux

# Authenticate (one time only, opens a browser)
gh auth login

# Deploy (creates the repo, pushes the files, enables Pages)
chmod +x deploy.sh
./deploy.sh
```

The script takes about 30 seconds and prints your live URL at the end. Skip to **Part 2**.

### Option 1B: Manual (via the GitHub web UI — no terminal required)

1. Go to <https://github.com/new>
2. Repository name: `recruitment-portal`
3. Description: `Team recruitment tracking portal`
4. Visibility: **Public** (free accounts) or **Private** (Pro accounts)
5. Initialize with README: **leave unchecked**
6. Click **Create repository**

You'll land on an empty-repo page. Click the link that says **"uploading an existing file"** (or drag-and-drop area):

7. Drag `index.html`, `README.md`, and `deploy.sh` from your computer into the upload area
8. Commit message: `Initial deploy`
9. Click **Commit changes**

Now enable Pages:

10. In the same repo, click **Settings** (top menu)
11. In the left sidebar, click **Pages**
12. Under **Source**, select **Deploy from a branch**
13. Under **Branch**, select **main** and **/ (root)**. Click **Save**.
14. Wait about 60 seconds for the green checkmark
15. Your portal URL will be shown near the top: `https://<your-username>.github.io/recruitment-portal/`

### Verify Part 1

Open the URL in your browser. You should see the Recruitment Portal dashboard with 14 open positions, 15 candidates, 6 closed positions, and 2 onboarding records pre-loaded. The data is seeded from the spreadsheet — this is demo data you'll keep or replace.

If you see a 404, wait another minute and refresh; Pages can take a bit to build on first deploy.

---

## Part 2 — Create the Gist backend

The Gist is your database. One Gist, one JSON file inside it, and every user on your team reads/writes the same file.

1. Go to <https://gist.github.com>
2. In the filename box, type exactly: **`recruitment-data.json`** (the exact filename matters — the portal looks for this name)
3. In the content box, paste this placeholder (the portal overwrites it on first save):
   ```json
   {
     "data": {
       "positions": [],
       "candidates": [],
       "onboarding": []
     }
   }
   ```
4. At the bottom, click the **dropdown arrow** next to the Create button
5. Choose **Create secret gist**
   - "Secret" does NOT mean private/hidden. It means unlisted — doesn't show up in your profile, but anyone with the URL can read it. That's fine because (a) the URL has a random ID nobody will guess, and (b) the data will be encrypted anyway.
6. Once created, look at the URL in your browser's address bar:
   ```
   https://gist.github.com/<your-username>/abc123def456…
                                          ^^^^^^^^^^^^^
                                          this is the Gist ID
   ```
7. **Copy the Gist ID** (the long hex string after your username). Save it in your password manager under `Recruitment Portal — Gist ID`.

### Verify Part 2

Refresh the Gist page. You should see the JSON content you pasted, with `recruitment-data.json` as the filename. That's it — the backend exists now.

---

## Part 3 — Create a GitHub Personal Access Token

The token is how the portal authenticates when it reads and writes the Gist. Every team member uses the **same token** for simplicity.

1. Go to <https://github.com/settings/tokens>
2. Click **Generate new token** → **Generate new token (classic)**
   - (The "fine-grained" option doesn't support Gist scope as cleanly yet; stick with classic.)
3. **Note** (i.e., the token's name): `Recruitment Portal Shared`
4. **Expiration**: choose what you're comfortable with:
   - `90 days` — safer, requires rotating four times a year
   - `1 year` — convenient
   - `No expiration` — simplest but not recommended
5. **Scopes** — check ONLY the **`gist`** checkbox. **Do not check anything else.** This limits damage if the token ever leaks.
6. Click **Generate token** at the bottom
7. You'll see a green box with your token, starting with `ghp_`. **This is the only time you'll see it.** Copy it immediately.
8. Save it in your password manager under `Recruitment Portal — Shared Token`.

### Verify Part 3

If you paste the token back into the GitHub tokens page search, you should see your `Recruitment Portal Shared` token listed with the `gist` scope. The actual token value is one-way hashed on GitHub's side; it won't show again.

---

## Part 4 — Configure the portal (first time)

Now connect the deployed portal to your Gist backend.

1. Open your portal URL: `https://<you>.github.io/recruitment-portal/`
2. Click **Settings** (top-right)
3. Fill in:
   - **Company Name:** `ACS Staffing` (or whatever your org is called)
   - **Portal Title:** `Nearshore Recruitment Portal` (or your preferred name)
4. Scroll to **Shared Storage**:
   - **GitHub Gist ID:** paste the Gist ID from Part 2
   - **GitHub Personal Access Token:** paste the token from Part 3
5. Click **Test Connection**. You should see `✓ Connection OK. Gist is accessible.`
6. Click **Push to Gist**. This uploads the current (demo) data to the Gist.
7. You should see `Pushed to Gist at <time>`.
8. Click **Save & Close**.

### Verify Part 4

Go back to your Gist in another browser tab and refresh. The `recruitment-data.json` file should now contain all 14 positions, 15 candidates, and 2 onboarding records in JSON form. That confirms the portal is writing to the backend successfully.

Top-right of the portal should now show `● Synced · Gist` instead of `● Local storage`.

---

## Part 5 — Enable passphrase protection

Without this step, the data in your Gist is readable by anyone who has the token — including team members you haven't vetted. Passphrase protection encrypts the data so that only users who know the passphrase can read it.

1. In the portal, click **Settings**
2. Scroll to **Access Protection (end-to-end encryption)**
3. Click **🔒 Enable Passphrase Protection**
4. A dialog asks you for a new passphrase. Choose one that:
   - Is **at least 8 characters**, preferably 12 or more
   - Mixes letters, numbers, and symbols (`Sunflower-Kitchen-4725` is much stronger than `admin123`)
   - Is stored in your password manager — you cannot recover it if you forget
5. Enter it twice and click **Enable Protection**
6. Confirm the alert
7. Save the passphrase in your password manager under `Recruitment Portal — Team Passphrase`

### Verify Part 5

1. Reload the portal. You should see the dark **Locked** screen asking for the passphrase.
2. Enter the passphrase. The portal unlocks and the dashboard appears.
3. Look at the Gist (refresh its page). The `recruitment-data.json` now contains something like:
   ```json
   {
     "encrypted": true,
     "version": 1,
     "salt": "f8jK3…",
     "iv": "9Xm…",
     "ciphertext": "H7Q2…"
   }
   ```
   — a proper encrypted blob. Nobody (not even GitHub) can read the underlying recruiting data without the passphrase.

---

## Part 6 — Onboarding team members

For each new team member, send them the following through a password manager's **secure share** feature (1Password: "Share" button; Bitwarden: "Send"; LastPass: "Share"):

1. **Portal URL** — e.g., `https://you.github.io/recruitment-portal/`
2. **Gist ID** — from Part 2
3. **GitHub Token** — from Part 3
4. **Passphrase** — from Part 5

Do **not** send these four items together in email, Slack DM, Teams message, or SMS. Use password-manager sharing, an encrypted vault like 1Password Shared, or print them and hand them over in person. If someone really insists on Slack, send each item in a separate channel/DM and ask them to delete after reading.

**What they do on their end:**

1. Open the portal URL → see the Locked screen → enter the passphrase → dashboard appears
2. Click **Settings** → paste the Gist ID and Token → **Test Connection** → **Save & Close**
3. They're in. Their edits auto-sync to the Gist every 2 seconds; they see other users' edits every 30 seconds.

### Quick reference card — paste this into your team's shared onboarding doc

```
RECRUITMENT PORTAL — QUICK START
=================================
URL:        https://<your-username>.github.io/recruitment-portal/
Gist ID:    <shared via 1Password link>
Token:      <shared via 1Password link>
Passphrase: <shared via 1Password link>

First-time setup:
  1. Open URL
  2. Enter passphrase on lock screen
  3. Settings → paste Gist ID & Token → Test Connection → Save

Daily use:
  - Add/edit positions, candidates, onboarding: auto-saves within 2 seconds
  - Other users' edits appear automatically every 30 seconds
  - "Lock" button (top right) clears your session until you re-enter the passphrase

If something doesn't save:
  - Check top-right — should show "Synced · Gist" with a green dot
  - If it shows "Error" or "Local storage", open Settings → Test Connection
  - If there's a Sync Conflict modal: choose Reload theirs (unless you know better)
```

---

## Day-to-day use

Most of your team's interaction is: open portal, unlock with passphrase, edit positions and candidates through forms, close tab. Behind the scenes the sync-save-poll loop handles all persistence without anyone needing to click a save button.

**Common operations:**

- **Add a position:** sidebar → New Position → fill form → Save
- **Update a candidate's status:** Candidates tab → click the Status dropdown in their row → pick a new status. It saves on change.
- **Schedule an interview:** Candidates tab → Edit row → set Interview Date → Save
- **Mark a position filled:** Open Positions → Edit → set Status to `Closed`, add Outcome → Save. It moves to the Closed Positions tab.
- **Download a status report:** Reports → Download Full Status PDF (text-searchable PDF with everything)
- **Weekly team update:** Reports → Generate Weekly Status → preview renders → Download as PDF. Email to stakeholders.
- **Lock your session:** click Lock (top right) before stepping away. Passphrase clears from memory.

---

## Backup and recovery

The Gist has built-in revision history — GitHub keeps every version of every edit forever. If something goes wrong, recovery is straightforward.

### Recovering from an accidental delete or bad edit

1. Go to `https://gist.github.com/<your-username>/<your-gist-id>`
2. Click **Revisions** (top right)
3. You'll see a list of every save, with a diff view
4. Find the version from before the mistake. Click the small **"View file"** button next to it
5. Copy the entire file content
6. In the portal, go to Reports → Import JSON
   - (or: paste it back into the Gist directly via **Edit** → paste → **Update public gist**)

### Manual periodic backups

Paranoid? Schedule a weekly reminder to:
1. Open the portal → Reports → **Export JSON**
2. Save the downloaded `recruitment-backup-YYYY-MM-DD.json` to a shared drive (Google Drive, SharePoint, etc.)

The exported JSON is **unencrypted plain text** — intentional, so you can restore without needing the passphrase. Store these backups securely.

### Disaster scenario: what if someone deletes the Gist?

Go to <https://gist.github.com>. Deleted Gists don't appear in your dashboard, but the revision history was preserved before deletion — contact GitHub Support and they can usually restore. If that fails, your most recent JSON backup is the fallback.

To reduce this risk, create a **second Gist** that you push to manually once a week as a mirror. Same process as Part 2; keep the second Gist ID in your password manager and use **Reports → Export JSON → manual paste into second Gist** for weekly snapshots.

---

## Troubleshooting

### "I made changes but they didn't save"

- Check the top-right sync indicator. `● Synced · Gist` (green) means all good. `● Local storage` (gray) means Gist isn't configured. `● Sync error` (red) means something failed.
- If red: open Settings → Test Connection. If that fails, your token may have expired or been revoked. Generate a new one (Part 3) and update in Settings.

### "Someone's changes disappeared"

If two people edited at the same time, the portal should have shown a Sync Conflict modal. If someone clicked **Overwrite theirs** (the danger button), the other person's changes were lost — go to Gist Revisions and restore.

### "Incorrect passphrase" — but I'm certain it's right

- Check for autocorrect/capitalization. Pass**P**hrases are case-sensitive.
- If you changed the passphrase recently, the old value won't work.
- If another admin changed the passphrase without telling you, ask them for the new one.

### "I forgot the passphrase"

Recovery path, in priority order:
1. Ask a teammate who has it
2. Find a plain-text JSON backup you exported before encryption was enabled, import via Reports → Import JSON, then disable encryption in Settings
3. Go to Gist → Revisions → find a revision from before encryption was turned on. Copy its content. Wipe local (lock screen → "Lost your passphrase?" → Wipe local data), then restore from that revision via Import JSON.
4. If none of the above: the data is gone. Re-seed from your original spreadsheet.

### "The lock screen appears but nothing happens when I click Unlock"

The PBKDF2 key derivation takes ~200ms. Give it a second. If nothing happens after 5 seconds, check browser console (F12) for errors and report back.

### "Read-only clients can't see anything"

Read-only mode (`?view=readonly` URL) still requires the passphrase. Either give the client the passphrase, or export a JSON snapshot periodically to a separate read-only portal deployment.

---

## Security best practices

- [ ] **Use different values for every credential**: don't reuse your GitHub password, the token, or the passphrase anywhere else
- [ ] **Store all four values (URL, Gist ID, Token, Passphrase) in a password manager**, not in email, Slack, or a sticky note
- [ ] **Rotate the token annually** (generate a new one, update Settings in everyone's portal, revoke the old one at <https://github.com/settings/tokens>)
- [ ] **Rotate the passphrase when someone leaves the team**: click Settings → Change Passphrase. Re-share with remaining members through password manager.
- [ ] **Click Lock** before stepping away from your desk (top-right button when protection is enabled)
- [ ] **Never commit the token or passphrase to a Git repo** — the `.gitignore` in the deploy folder helps but check your commits anyway
- [ ] **Periodically review token activity** at <https://github.com/settings/tokens> — GitHub shows last-used date

---

## Appendix: costs and limits

| Item | Cost | Limit |
|---|---|---|
| GitHub Pages hosting | Free | 100 GB bandwidth/month (you will use <1 GB) |
| GitHub Gist storage | Free | 10 MB per file; the portal's data grows ~1 KB per position+candidate (room for thousands) |
| GitHub API calls | Free | 5,000 requests/hour per token; the portal uses ~150/hour per active user |
| Portal user count | No limit | Smooth to ~20 concurrent editors; degrades past that |

You will not hit any of these limits with a normal recruiting team.

---

## When to outgrow this setup

Switch to Supabase (or equivalent) if you need any of these:

- More than ~20 simultaneous active editors
- Separate read-only client accounts (with their own logins, not a shared passphrase)
- Per-user permissions (e.g., recruiters can edit candidates, hiring managers can only comment)
- Audit log showing who changed what and when
- API for integrating with your ATS, HRIS, Slack, etc.

Until any of those are hard requirements, the Gist-backed portal is the right choice: no server to maintain, no recurring cost, no vendor lock-in, and your data lives on GitHub's rock-solid infrastructure with 15 years of reliability behind it.
