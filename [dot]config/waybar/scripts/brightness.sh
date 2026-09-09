#!/bin/bash
# Brightness control for waybar via ddcutil (DDC/CI, works with external monitors)
# Display 1 = HDMI-A-1 (Samsung), Display 2 = DP-1 (ASUS)

STEP=5
PRESETS=(25 50 75 100)

get_brightness() {
    # Read Display 2 (DP-1) as the reference value shown in the bar
    ddcutil --display 2 getvcp 10 2>/dev/null | grep -oP '(?<=current value = )[0-9]+'
}

set_brightness() {
    local value=$1
    ddcutil --display 1 setvcp 10 "$value" >/dev/null 2>&1
    ddcutil --display 2 setvcp 10 "$value" >/dev/null 2>&1
}

refresh_waybar() {
    pkill -RTMIN+8 waybar
}

case "$1" in
    --up)
        current=$(get_brightness)
        new=$(( current + STEP > 100 ? 100 : current + STEP ))
        set_brightness "$new"
        refresh_waybar
        ;;
    --down)
        current=$(get_brightness)
        new=$(( current - STEP < 0 ? 0 : current - STEP ))
        set_brightness "$new"
        refresh_waybar
        ;;
    --cycle)
        current=$(get_brightness)
        next="${PRESETS[0]}"
        for i in "${!PRESETS[@]}"; do
            if [ "$current" -lt "${PRESETS[$i]}" ]; then
                next="${PRESETS[$i]}"
                break
            fi
        done
        set_brightness "$next"
        refresh_waybar
        ;;
    *)
        value=$(get_brightness)
        [ -z "$value" ] && value=0

        if [ "$value" -ge 66 ]; then
            icon="󰃠"
        elif [ "$value" -ge 33 ]; then
            icon="󰃟"
        else
            icon="󰃞"
        fi

        printf '{"text":"%s %s%%","tooltip":"Brightness: %s%%\\nScroll to adjust, click to cycle presets"}\n' "$icon" "$value" "$value"
        ;;
esac
