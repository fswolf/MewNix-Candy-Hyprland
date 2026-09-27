#!/usr/bin/env bash
# Close fuzzel when a left-click lands outside its window.
# Bound non-consuming to mouse:272 so clicks inside the menu still select.
set -u

pgrep -x fuzzel >/dev/null || exit 0

read -r lx ly lw lh < <(hyprctl layers -j | jq -r '
  [ .[].levels[][] | select(.namespace == "launcher") ] | .[0]
  | "\(.x) \(.y) \(.w) \(.h)"' 2>/dev/null)
[[ -z ${lx:-} || $lx == null ]] && exit 0

read -r cx cy < <(hyprctl cursorpos | tr -d ',')

(( cx < lx || cx >= lx + lw || cy < ly || cy >= ly + lh )) && pkill -x fuzzel
exit 0
