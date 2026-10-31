#!/usr/bin/env python3
"""MewNix runtime integration for the upstream hypr-themes renderer."""
import configparser
import json
import shlex
import os
from pathlib import Path
import subprocess
import sys
import time

CONFIG = Path.home() / '.config'
STATE = Path.home() / '.local/state/mewnix-themes'
STYLES = {'candy': 'style.css', 'midnight-blue': 'style_midnight_blue.css', 'silver': 'style_silver.css'}

def current():
    active = CONFIG / 'hypr-themes/.active'
    return active.resolve().stem if active.is_symlink() else 'midnight-blue'

def run(args):
    result = subprocess.run(args, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f'{args[0]}: {result.stderr.strip() or result.stdout.strip()}')
    return result.stdout

def atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.tmp')
    temp.write_text(text)
    temp.replace(path)

def wallpaper_preset(name):
    # Read literal assignments; do not execute the theme as Python or shell.
    theme = Path(__file__).resolve().parents[1] / 'themes' / (name + '.theme')
    values = {}
    for line in theme.read_text().splitlines():
        parts = shlex.split(line, comments=True)
        if len(parts) == 1 and '=' in parts[0]:
            key, value = parts[0].split('=', 1)
            values[key] = value
    preset = {}
    for kind, prefix in [('desktop', 'WALLPAPER_'), ('lock', 'LOCK_WALLPAPER_')]:
        main = values.get(prefix + 'MAIN')
        portrait = values.get(prefix + 'PORTRAIT')
        if main and portrait:
            preset[kind] = {'DP-1': main, 'HDMI-A-1': portrait}
    if 'desktop' in preset:
        preset.setdefault('lock', preset['desktop'])
    return preset

def wallpapers(name):
    """Remember Waypaper's two-monitor selection without replacing its preferences."""
    path = CONFIG / 'waypaper/config.ini'
    if not path.exists():
        return
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.read(path)
    settings = cfg['Settings']
    saved = STATE / 'wallpapers.json'
    profiles = json.loads(saved.read_text()) if saved.exists() else {}
    keys = ('monitors', 'wallpaper', 'fill', 'color')
    profiles[current()] = {k: settings[k] for k in keys if k in settings}
    # New themes inherit the current image until customized using Waypaper.
    profiles.setdefault(name, dict(profiles[current()]))
    atomic(saved, json.dumps(profiles, indent=2) + '\n')
    target = dict(profiles[name])
    preset = wallpaper_preset(name)
    desktop = preset.get('desktop')
    if desktop:
        target['monitors'] = '\n'.join(desktop)
        target['wallpaper'] = '\n'.join(desktop.values())
    # Don't replace a valid image with a deleted/unavailable wallpaper.
    images = target.get('wallpaper', '').splitlines()
    if not images or not all(Path(p.strip()).expanduser().is_file() for p in images if p.strip()):
        print('Saved wallpaper unavailable; keeping the current selection.', file=sys.stderr)
        return
    import io
    old = path.read_text()
    for key, value in target.items():
        settings[key] = value
    output = io.StringIO(); cfg.write(output)
    atomic(path, output.getvalue())
    try:
        # Wallpaper backends may inherit stdout: don't capture a pipe that stays open.
        subprocess.run(['waypaper', '--restore'], check=True,
                       stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, start_new_session=True,
                       env=dict(os.environ, GDK_BACKEND='wayland'), timeout=30)
    except Exception:
        atomic(path, old)
        raise

def lock_wallpapers(name):
    preset = wallpaper_preset(name).get('lock')
    if not preset:
        return
    for path in preset.values():
        if not Path(path).expanduser().is_file():
            raise RuntimeError(f'Missing lock-screen wallpaper: {path}')
    lines = ['# Generated from ~/.local/share/mewnix-hypr-themes/themes/*.theme']
    for monitor, variable in [('DP-1', 'mewnix_wallpaper_main'), ('HDMI-A-1', 'mewnix_wallpaper_portrait')]:
        lines.append(f'${variable} = {Path(preset[monitor]).expanduser()}')
    atomic(CONFIG / 'hypr/hyprlock-wallpapers.conf', '\n'.join(lines) + '\n')

def bars(name):
    style = CONFIG / 'waybar' / STYLES[name]
    if not style.is_file():
        raise RuntimeError(f'Missing Waybar stylesheet: {style}')
    # Only stop this user's Waybar processes, then wait for them to exit.
    subprocess.run(['pkill', '-u', str(os.getuid()), '-x', 'waybar'], capture_output=True)
    for _ in range(30):
        if subprocess.run(['pgrep', '-u', str(os.getuid()), '-x', 'waybar'], capture_output=True).returncode:
            break
        time.sleep(.1)
    else:
        raise RuntimeError('Waybar did not exit; refusing to launch duplicate bars.')
    STATE.mkdir(parents=True, exist_ok=True)
    processes = []
    display_env = dict(os.environ, GDK_BACKEND="wayland")
    for config in ('config-main', 'config-side'):
        with (STATE / f'waybar-{config}.log').open('w') as log:
            process = subprocess.Popen(['waybar', '-c', str(CONFIG / 'waybar' / config), '-s', str(style)],
                             stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True, env=display_env)
            processes.append(process)
    time.sleep(0.5)
    if any(process.poll() is not None for process in processes):
        raise RuntimeError(f"Waybar failed to start; see logs in {STATE}")

def main():
    startup = sys.argv[1:] == ['--startup']
    name = current() if startup else sys.argv[1]
    if name not in STYLES:
        raise RuntimeError('Unknown MewNix theme')
    if os.environ.get('MEWNIX_RENDER_ONLY') == '1':
        return
    if not startup:
        lock_wallpapers(name)
        wallpapers(name)
        run(['hyprctl', 'reload'])
        errors = run(['hyprctl', 'configerrors']).strip()
        if errors and errors != 'ok':
            raise RuntimeError('Hyprland configuration errors: ' + errors)
        run(['makoctl', 'reload'])
    bars(name)

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(error, file=sys.stderr)
        sys.exit(1)
