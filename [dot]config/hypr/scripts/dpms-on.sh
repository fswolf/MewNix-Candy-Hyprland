# ~/.config/hypr/scripts/dpms-on.sh
#!/bin/bash
hyprctl dispatch 'hl.dsp.dpms({action="enable"})'