#!/usr/bin/env bash
# new-brief.sh <owner> "<title>" [budget]
# Creates a brief from the template and opens it in your editor.
# owner: claude-code | codex | soup
set -euo pipefail

SWARM_REPO="${SWARM_REPO:-$HOME/venulo-swarm}"

owner="${1:?usage: new-brief.sh <owner: claude-code|codex|soup> \"<title>\" [budget]}"
title="${2:?missing title}"
budget="${3:-standard}"

case "$owner" in claude-code|codex|soup) ;; *)
  echo "owner must be claude-code, codex, or soup"; exit 1 ;;
esac

slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-\|-$//g' | cut -c1-50)
id="$(date +%Y-%m-%d)-$slug"
f="$SWARM_REPO/briefs/$id.md"
[ -e "$f" ] && { echo "already exists: $f"; exit 1; }

sed -e "s/^id: .*/id: $id/" \
    -e "s/^title: .*/title: \"$title\"/" \
    -e "s/^owner: .*/owner: $owner/" \
    -e "s/^budget: .*/budget: $budget/" \
    -e "s/^branch: .*/branch: swarm\/$id/" \
    -e "s/^created: .*/created: $(date +%Y-%m-%d)/" \
    "$SWARM_REPO/briefs/_TEMPLATE.md" > "$f"

"${EDITOR:-nano}" "$f"
echo "created: $f"
echo "commit + push it, and the runner will pick it up on its next poll."
