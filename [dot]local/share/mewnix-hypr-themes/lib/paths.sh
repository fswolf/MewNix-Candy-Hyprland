# shellcheck shell=bash
# ------------------------------------------------------------
#  paths.sh — shared path helpers for hypr-themes (sourced, not executed).
#
#  Single source of truth for "which files the tool generates and where".
#  bin/theme, install.sh and uninstall.sh all source this so adding a target
#  tool is just dropping a template (and optionally a skeleton) — no path list
#  to keep in sync across scripts.
#
#  Callers must set REPO_DIR and HYPR_CONFIG_DIR / WOFI_CONFIG_DIR /
#  DUNST_CONFIG_DIR before calling these.
# ------------------------------------------------------------
# shellcheck disable=SC2154  # *_CONFIG_DIR are provided by the sourcing script

# Map a template/skeleton's tool dir (first path component) to its dest dir.
target_for() {
    local rel="$1" tool="${1%%/*}" sub="${1#*/}"
    case "$tool" in
        hypr)  echo "$HYPR_CONFIG_DIR/$sub" ;;
        wofi)  echo "$WOFI_CONFIG_DIR/$sub" ;;
        dunst) echo "$DUNST_CONFIG_DIR/$sub" ;;
        *)     echo "$HOME/.config/$rel" ;;
    esac
}

# Destination path of every generated partial, one per line (from templates/).
each_partial_target() {
    local tmpl rel
    while IFS= read -r tmpl; do
        rel="${tmpl#"$REPO_DIR/templates/"}"; rel="${rel%.tmpl}"
        target_for "$rel"
    done < <(find "$REPO_DIR/templates" -type f -name '*.tmpl' | sort)
}

# Destination path of every base config the skeletons cover (from skeleton/).
each_base_target() {
    local skel rel
    while IFS= read -r skel; do
        rel="${skel#"$REPO_DIR/skeleton/"}"
        target_for "$rel"
    done < <(find "$REPO_DIR/skeleton" -type f | sort)
}
