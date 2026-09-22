# MewNix Candy Hyprland

A purple-and-rose Hyprland rice with compact Waybar panels, matching SVG status icons, and rounded, flared edges.

## Screenshots

### Desktop and Fastfetch

![MewNix Candy desktop with Waybar and Fastfetch](Docs/screenshot.png)

### Power menu

![MewNix Candy power menu with SVG icons](Docs/screenshot1.png)

### Application launcher

![MewNix Candy application launcher](Docs/screenshot2.png)

### Floating utility windows

Bluetui, Wiremix, and Calcurse run in floating Kitty windows, with their positioning and animations defined in `hyprland.lua`. Calcurse is shown below.

![Calcurse showing the floating utility window layout](Docs/screenshot3.png)

## Included

- 28px Waybar layouts for the main and secondary monitors.
- SVG icons for system stats, audio, network, Bluetooth, clock, and power.
- Matching workspace indicators, subtle underline hovers, and a rose power button.
- Hyprland, Hypridle, Hyprlock, launcher, notification, terminal-shell, and visualizer configuration.
- Wallpapers and the `toggle-float` helper.

## Layout

`[dot]config/` represents `~/.config/`, and `[dot]local/` represents `~/.local/`. The brackets are literal directory names in this repository. Hyprland configuration is under `[dot]config/hypr/`.

These are personal configuration files, rather than an automatic installer. Review the files before copying them into your home directory. Adjust `/home/ryan` paths, monitor names (`DP-1` and `HDMI-A-1`), temperature sensor paths, and application commands for your machine. The included Hyprland configuration uses Lua.

Copy the complete Waybar directory, including `icons/` and `scripts/`; its CSS references the SVG assets. Waybar uses JetBrainsMono Nerd Font. Fuzzel provides the application launcher and power menu.

## Utility window toggles

The Waybar audio, Bluetooth, and clock buttons toggle Wiremix, Bluetui, and Calcurse in Kitty. Click once to open the utility, then click again to close its window.

The included `toggle-float` script belongs in `~/.local/bin/` and takes a window class and a launch command. It checks for an existing window with that class: if one exists, it closes it; otherwise, it runs the launch command. This lets repeated clicks toggle the utility instead of opening extra copies. The script uses `hyprctl` and `jq`.

Window rules in `[dot]config/hypr/hyprland.lua` match those Kitty window classes and control floating, size, position, and animation. For example, the `calcurse-float` rule creates a 900×600 floating window, centers it horizontally, places it 38 pixels from the top, and applies the `slide top` animation. The `toggle-float` script handles opening and closing; it does not switch windows between tiled and floating modes.
