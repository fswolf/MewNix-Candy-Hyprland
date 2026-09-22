#!/bin/bash

# Toggle off if fuzzel is already open
pkill -x fuzzel && exit 0

# Resolve icons relative to this script so the theme remains portable.
icon_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../icons" && pwd)" || exit 1

# Fuzzel's dmenu icon metadata is hidden from the returned choice text.
chosen=$(printf '%s\0icon\x1f%s\n' \
    "Lock" "$icon_dir/menu-lock.svg" \
    "Logout" "$icon_dir/menu-logout.svg" \
    "Reboot" "$icon_dir/menu-reboot.svg" \
    "Shutdown" "$icon_dir/menu-shutdown.svg" | fuzzel --dmenu \
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
