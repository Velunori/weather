#!/usr/bin/env bash
set -euo pipefail
config_path="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
backup=$(mktemp "${config_path}.before-weather-restore.XXXXXXXX")
cp -p "$config_path" "$backup"
# Disabling a clone puts the built-in weather widget back in its place.
omarchy plugin disable velunori.weather || echo 'Disable IPC interrupted; restarting to apply the saved configuration.' >&2
omarchy restart shell
echo "Built-in Omarchy weather restored. Configuration backup: $backup"
