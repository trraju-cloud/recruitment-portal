#!/usr/bin/env bash
# Deploy the recruitment portal to GitHub Pages
# Usage: ./deploy.sh [repo-name]
# Default repo name: recruitment-portal
# Requirements: git, gh (GitHub CLI) authenticated via `gh auth login`

set -euo pipefail

REPO_NAME="${1:-recruitment-portal}"
VISIBILITY="${VISIBILITY:-public}"  # set VISIBILITY=private to override

# ---------- preflight ----------
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required but not installed." >&2; exit 1; }
command -v gh  >/dev/null 2>&1 || { echo "ERROR: GitHub CLI (gh) is required. Install from https://cli.github.com" >&2; exit 1; }

if ! gh auth status >/dev/null 2>&1; then
  echo "You are not logged in to GitHub CLI. Running 'gh auth login' now..."
  gh auth login
fi

if [ ! -f "index.html" ]; then
  echo "ERROR: index.html not found in $(pwd)." >&2
  echo "Run this script from the folder that contains index.html." >&2
  exit 1
fi

GH_USER="$(gh api user -q .login)"
echo "Deploying as: $GH_USER"
echo "Repo name:    $REPO_NAME"
echo "Visibility:   $VISIBILITY"
echo ""

# ---------- ensure .gitignore ----------
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
# OS / editor
.DS_Store
Thumbs.db
.vscode/
.idea/

# Local data / keys — NEVER commit
*.secret
*.env
*.token
data-backup-*.json
EOF
  echo "  wrote .gitignore"
fi

# ---------- git init + commit ----------
if [ ! -d .git ]; then
  git init -q -b main
  echo "  git initialized"
fi

git add index.html README.md deploy.sh .gitignore 2>/dev/null || true
if git diff --cached --quiet 2>/dev/null; then
  echo "  nothing new to commit"
else
  git commit -q -m "Deploy recruitment portal" \
    -m "Single-file portal with dashboard, positions, candidates, onboarding, and reports."
  echo "  commit created"
fi

# ---------- create remote repo (idempotent) ----------
if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  echo "  repo $GH_USER/$REPO_NAME already exists — reusing"
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
  fi
else
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin \
    --description="Nearshore recruitment tracking portal" \
    --push
  echo "  repo $GH_USER/$REPO_NAME created and pushed"
fi

# if push hasn't happened yet (repo pre-existed), push now
if ! git ls-remote --exit-code origin main >/dev/null 2>&1; then
  git push -u origin main
  echo "  pushed main"
fi

# ---------- enable GitHub Pages ----------
echo ""
echo "Enabling GitHub Pages on main branch (root)..."

# Try to create Pages site. If it already exists, update it.
if ! gh api "repos/$GH_USER/$REPO_NAME/pages" --silent >/dev/null 2>&1; then
  gh api "repos/$GH_USER/$REPO_NAME/pages" \
    -X POST \
    -F "source[branch]=main" \
    -F "source[path]=/" \
    >/dev/null
  echo "  Pages enabled"
else
  gh api "repos/$GH_USER/$REPO_NAME/pages" \
    -X PUT \
    -F "source[branch]=main" \
    -F "source[path]=/" \
    >/dev/null 2>&1 || true
  echo "  Pages already enabled"
fi

# ---------- done ----------
URL="https://${GH_USER}.github.io/${REPO_NAME}/"
echo ""
echo "========================================================="
echo "Deployment initiated. Your portal will be live at:"
echo ""
echo "    $URL"
echo ""
echo "It typically takes 30-90 seconds for the first build."
echo "Check status at:"
echo "    https://github.com/$GH_USER/$REPO_NAME/actions"
echo "========================================================="
