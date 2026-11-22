#!/usr/bin/env bash
#
# One-command update for Arch / CachyOS:
#   1. pulls your repository (origin),
#   2. merges new work from the original OpenGHub project (upstream),
#   3. pushes the result back to origin,
#   4. builds the app from source and installs it with pacman.
#
#   scripts/update.sh            # everything above
#   scripts/update.sh --no-upstream   # skip step 2 (only your own repo)
#   scripts/update.sh --no-push       # skip step 3
#
# It stops, changing nothing, when you have uncommitted changes or when the
# upstream merge conflicts with your changes.
set -euo pipefail

UPSTREAM_URL="https://github.com/Slyvan25/OpenGHub.git"
BRANCH="master"
use_upstream=1
push=1
for arg in "$@"; do
    case "$arg" in
        --no-upstream) use_upstream=0 ;;
        --no-push) push=0 ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mxx  %s\033[0m\n' "$*" >&2; exit 1; }

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"

for tool in git makepkg cargo npm; do
    command -v "$tool" >/dev/null || fail "'$tool' is missing. Install it: sudo pacman -S --needed git base-devel rust nodejs npm"
done

[[ "$(git rev-parse --abbrev-ref HEAD)" == "$BRANCH" ]] || fail "Switch to the '$BRANCH' branch first: git switch $BRANCH"
[[ -z "$(git status --porcelain)" ]] || fail "You have uncommitted changes. Commit or stash them first (git status shows them)."

before="$(git rev-parse HEAD)"

say "Pulling your repository"
git pull --ff-only origin "$BRANCH" || fail "Could not fast-forward from origin. Your local branch and GitHub have diverged."

if (( use_upstream )); then
    say "Checking the original OpenGHub project for updates"
    # `anon@` keeps a global "insteadOf https://github.com/" rule from turning
    # this public, read-only fetch into an SSH one.
    if ! git remote get-url upstream >/dev/null 2>&1; then
        git remote add upstream "${UPSTREAM_URL/https:\/\//https://anon@}"
    fi
    git fetch --tags upstream "$BRANCH"
    if git merge-base --is-ancestor "upstream/$BRANCH" HEAD; then
        echo "Already up to date with upstream."
    elif ! git merge --no-edit "upstream/$BRANCH"; then
        git merge --abort
        fail "Upstream changes conflict with yours. Nothing was changed. Merge by hand: git merge upstream/$BRANCH"
    fi
fi

if (( push )) && [[ "$(git rev-parse HEAD)" != "$(git rev-parse "origin/$BRANCH")" ]]; then
    say "Pushing to your GitHub repository"
    git push origin "$BRANCH"
fi

after="$(git rev-parse HEAD)"
installed="$(pacman -Q openghub-local 2>/dev/null | awk '{print $2}' || true)"
if [[ "$before" == "$after" && "$installed" == *".g$(git rev-parse --short HEAD)-"* ]]; then
    say "Already on the newest version ($installed). Nothing to build."
    exit 0
fi

say "Building and installing (this takes a few minutes; asks for your password)"
cd packaging/arch-source
# makepkg writes the computed version back into the PKGBUILD; undo that so
# the repository stays clean for the next update.
trap 'git -C "$repo" checkout --quiet -- packaging/arch-source/PKGBUILD' EXIT
makepkg -si --needed --cleanbuild
say "Done. Restart OpenGHub to use the new version."
