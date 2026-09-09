#!/bin/bash

# Toggle off if fuzzel is already open
pkill -x fuzzel && exit 0

options="Lock
Logout
Reboot
Shutdown"

chosen=$(printf '%b\n' "$options" | fuzzel --dmenu \
    --hide-prompt \
    --lines 4 \
    --width 18 \
    --anchor top-right \
    --x-margin 6 \
    --y-margin 6) || exit 0

case "$chosen" in
    Lock)
        hyprlock
        ;;

    Logout)
        command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'
        ;;

    Reboot)
        exec systemctl reboot
        ;;

    Shutdown)
        exec systemctl poweroff
        ;;
esac