#!/usr/bin/env bash
# Sync this theme folder to its configured GitHub repository.
set -euo pipefail
trap 'printf "\nSync stopped. Your local changes have been kept.\n" >&2' ERR

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
git rev-parse --is-inside-work-tree >/dev/null
if ! git symbolic-ref -q HEAD >/dev/null; then
    printf 'Switch to a branch before syncing.\n' >&2
    exit 1
fi
if ! git rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
    printf 'This branch needs a remote tracking branch before syncing.\n' >&2
    exit 1
fi
if [[ -n "$(git ls-files --unmerged)" ]]; then
    printf 'Resolve the merge conflicts before syncing.\n' >&2
    exit 1
fi

printf '\nChecking GitHub for updates...\n'
git fetch
behind=$(git rev-list --count 'HEAD..@{upstream}')
if (( behind > 0 )); then
    ahead=$(git rev-list --count '@{upstream}..HEAD')
    if [[ -n "$(git status --porcelain)" ]] || (( ahead > 0 )); then
        printf '\nGitHub has new commits. Reconcile them with your local changes first, then rerun this script.\n' >&2
        printf 'No files were staged or committed by this run.\n' >&2
        exit 1
    fi
    git merge --ff-only '@{upstream}'
fi

if [[ -n "$(git status --porcelain)" ]]; then
    printf '\nChanges to upload from this folder:\n'
    git status --short
    printf '\n'
    if (( $# > 0 )); then
        message="$*"
    elif [[ -t 0 ]]; then
        read -r -p 'Commit message [Update MewNix Candy theme] (Ctrl+C cancels): ' message
    else
        printf 'Supply a commit message when running without a terminal.\n' >&2
        exit 1
    fi
    message=${message:-Update MewNix Candy theme}
    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "$message"
    fi
fi

# Also retry a previous commit whose push failed.
if (( $(git rev-list --count '@{upstream}..HEAD') > 0 )); then
    git push
else
    printf 'Already up to date.\n'
fi
printf '\nTheme folder synced successfully.\n'
