# ~/.config/hypr/scripts/dpms-off.sh
#!/bin/bash
hyprctl dispatch 'hl.dsp.dpms({action="disable"})'