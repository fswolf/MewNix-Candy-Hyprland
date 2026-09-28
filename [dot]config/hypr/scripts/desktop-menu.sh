#!/usr/bin/env bash
set -u

# toggle off if a fuzzel menu is already open
pkill -x fuzzel && exit 0

ICONS="$HOME/.config/waybar/icons"

read -r cx cy < <(hyprctl cursorpos | tr -d ',')

# every workspace currently visible on any monitor, not just the focused one
vis=$(hyprctl monitors -j | jq -c '[ .[].activeWorkspace.id ]')

over=$(hyprctl clients -j | jq --argjson x "$cx" --argjson y "$cy" --argjson v "$vis" '
  [ .[]
    | select(.mapped and (.hidden | not))
    | select(.workspace.id as $w | $v | index($w))
    | select($x >= .at[0] and $x < (.at[0] + .size[0]) and
             $y >= .at[1] and $y < (.at[1] + .size[1]))
  ] | length')

(( over > 0 )) && exit 0

# ignore clicks landing on any top/overlay layer surface: waybar, tray menus,
# notifications. Levels 0/1 are skipped so the wallpaper doesn't block us.
onlayer=$(hyprctl layers -j | jq --argjson x "$cx" --argjson y "$cy" '
  [ .[].levels | to_entries[]
    | select((.key | tonumber) >= 2) | .value[]
    | select(.w > 0 and .h > 0)
    | select($x >= .x and $x < (.x + .w) and $y >= .y and $y < (.y + .h))
  ] | length')
(( onlayer > 0 )) && exit 0

read -r mx my mw mh < <(hyprctl monitors -j | jq -r --argjson x "$cx" --argjson y "$cy" '
  .[] | select($x >= .x and $x < (.x + (.width / .scale)) and
               $y >= .y and $y < (.y + (.height / .scale)))
      | "\(.x) \(.y) \(.width / .scale | floor) \(.height / .scale | floor)"')
: "${mx:=0}" "${my:=0}" "${mw:=1920}" "${mh:=1080}"

MW=240 MH=150
OFF_X=0 OFF_Y=-40                         # nudge menu relative to the cursor
px=$(( cx - mx + OFF_X )); py=$(( cy - my + OFF_Y ))
(( px + MW > mw )) && px=$(( mw - MW ))
(( py + MH > mh )) && py=$(( mh - MH ))
(( px < 0 )) && px=0
(( py < 0 )) && py=0

# no --config: inherit ~/.config/fuzzel/fuzzel.ini so this matches the power menu
opts=( --dmenu --width 18 --lines 5 --anchor=top-left --x-margin="$px" --y-margin="$py" )
if fuzzel --help 2>&1 | grep -q -- --hide-prompt; then
  opts+=( --hide-prompt )
else
  opts+=( -p '' )
fi

menu_items() {
  printf '%s\0icon\x1f%s\n' \
    "Terminal"  "$ICONS/menu-terminal.svg" \
    "Files"     "$ICONS/menu-files.svg" \
    "Wallpaper" "$ICONS/menu-wallpaper.svg" \
    "Displays"  "$ICONS/menu-displays.svg" \
    "Reload"    "$ICONS/menu-reload.svg"
}

case $(menu_items | fuzzel "${opts[@]}") in
  Terminal)  kitty & ;;
  Files)     dolphine & ;;
  Wallpaper) waypaper & ;;
  Displays)  kitty hyprmoncfg & ;;
  Reload)    hyprctl reload ;;
esac