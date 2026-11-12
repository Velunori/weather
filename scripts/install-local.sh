#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/.." && pwd -P)
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
plugin_dir="$config_dir/plugins/velunori.weather"
core_dir="$config_dir/plugins/velunori.core"
for executable in omarchy omarchy-shell python3; do
  command -v "$executable" >/dev/null || { echo "Missing: $executable" >&2; exit 1; }
done
# Only the core design kit is required; either bar may be active.
python3 - "$core_dir/manifest.json" <<'PY'
import json,sys
core=json.load(open(sys.argv[1]))
assert core['id']=='velunori.core' and tuple(map(int,core['version'].split('.'))) >= (0,4,1), 'Core 0.4.1 or later required'
PY
bash "$core_dir/scripts/prepare-dev-layout.sh"
if [[ -e "$plugin_dir" || -L "$plugin_dir" ]]; then
  [[ -L "$plugin_dir" && $(readlink -f "$plugin_dir") == "$repo_dir" ]] || { echo "Refusing to replace $plugin_dir" >&2; exit 1; }
fi
[[ $(omarchy-shell shell ping) == ok ]]
backup=$(mktemp "$config_dir/shell.json.before-velunori-weather.XXXXXXXX")
cp -p "$config_dir/shell.json" "$backup"
echo "Configuration backup: $backup"
[[ -L "$plugin_dir" ]] || ln -s "$repo_dir" "$plugin_dir"
omarchy-shell shell rescanPlugins
ready=false
for attempt in {1..30}; do
  if omarchy-shell shell listPlugins | python3 -c 'import json,sys; sys.exit(0 if any(p.get("id")=="velunori.weather" for p in json.load(sys.stdin)) else 1)'; then ready=true; break; fi
  sleep 0.2
done
[[ $ready == true ]] || { echo 'Weather plugin discovery failed; configuration was not changed.' >&2; exit 1; }
# Enabling a clone takes the built-in weather widget's place in the bar. The
# write triggers a hot reload during which IPC can stop answering even though
# the configuration was saved, so restart and then read the saved layout.
if ! omarchy plugin enable velunori.weather; then
  echo 'Enable IPC interrupted; restarting to verify the saved configuration.' >&2
fi
omarchy restart shell
ready=false
for attempt in {1..60}; do
  if [[ $(omarchy-shell shell ping 2>/dev/null) == ok ]] && python3 - "$config_dir/shell.json" <<'PY'
import json, sys
layout = json.load(open(sys.argv[1])).get('bar', {}).get('layout', {})
ids = [entry if isinstance(entry, str) else entry.get('id') for section in layout.values() for entry in section]
sys.exit(0 if 'velunori.weather' in ids and 'omarchy.weather' not in ids else 1)
PY
  then ready=true; break; fi
  sleep 0.25
done
if [[ $ready != true ]]; then
  cp -p "$backup" "$config_dir/shell.json"
  omarchy restart shell || true
  echo "The weather widget did not take its place in the bar; restored $backup" >&2
  exit 1
fi
echo 'Velunori Weather installed. It appears in the bar once the first forecast arrives.'
echo "Restore: bash $repo_dir/scripts/restore-local.sh"
